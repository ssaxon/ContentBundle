//
//  SSContentBundle.m
//  SSContentBundle
//
//  Created by Steve Saxon on 5/19/11.
//  Copyright 2011 Steve Saxon. All rights reserved.
//

#import "SSContentBundle.h"
#import "LiteUnzip.h"

static SSContentBundle* _provider;

@interface ContentLoader : NSObject 
{
	NSInteger _currentVersion;
	NSInteger _serverVersion;
	BOOL _fetchingVersion;
	NSURL* _versionURL;
	NSMutableData* _data;
	void (^_block)(NSInteger serverVersion, NSData* data, NSError* error);
}

- (void)loadWithVersionURL:(NSURL*)url 
				   version:(NSInteger)version 
					 block:(void (^)(NSInteger serverVersion, NSData* data, NSError* error))block;

@end

@interface SSContentBundle (Private)
- (void)extractFiles:(NSData*)data version:(NSInteger)version fileManager:(NSFileManager*)fileManager;
@end

@implementation SSContentBundle

- (id) initWithSource:(NSString*)sourceFile 
			  version:(NSInteger)version 
			serverURL:(NSString*)serverURL
		 targetFolder:(NSString*)targetFolder
{
	if((self = [super init]))
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
		NSString* documentsDirectoryPath = [paths objectAtIndex:0];
		NSString* versionFileName = [targetFolder stringByAppendingString:@"-version.txt"];
		
		_dataFolder = [[documentsDirectoryPath stringByAppendingPathComponent:targetFolder] retain];
		_versionPath = [[documentsDirectoryPath stringByAppendingPathComponent:versionFileName] retain];
		_currentVersion = 0;
		_contentURL = [serverURL retain];
		
		NSFileManager* fileManager = [NSFileManager new];
		NSError* error = nil;
		
		NSString* fileVersion = nil;
		if([fileManager fileExistsAtPath:_versionPath])
		{
			fileVersion = [NSString stringWithContentsOfFile:_versionPath encoding:NSASCIIStringEncoding error:&error];
			if(error)
			{
				NSLog(@"Error fetching file version: %@", [error localizedDescription]);
				error = nil;
			}
			else if(fileVersion)
			{
				_currentVersion = [fileVersion intValue];
			}
		}
		
		if(_currentVersion < version)
		{
			BOOL dir;
			if([fileManager fileExistsAtPath:_dataFolder isDirectory:&dir] && dir)
			{
				[fileManager removeItemAtPath:_dataFolder error:&error];
				if(error)
				{
					NSLog(@"Error removing old content: %@", [error localizedDescription]);
					error = nil;
				}
			}
		}
		
		BOOL dir;
		if([fileManager fileExistsAtPath:_dataFolder isDirectory:&dir] && dir)
		{
			
		}
		else if([fileManager createDirectoryAtPath:_dataFolder withIntermediateDirectories:NO attributes:nil error:&error])
		{
			NSBundle* bundle = [NSBundle mainBundle];
			NSString* path = [bundle pathForResource:[sourceFile stringByDeletingPathExtension] ofType:[sourceFile pathExtension]];
			
			NSLog(@"Copying from: %@", path);
			
			NSData* data = [NSData dataWithContentsOfFile:path];
			
			[self extractFiles:data version:version fileManager:fileManager];
		}
		else if(error)
		{
			NSLog(@"Error creating direction: %@", [error localizedDescription]);
			error = nil;
		}

		[fileManager release];
	}
	
	return self;
}

- (void)dealloc
{
	[_dataFolder release];
	[_versionPath release];
	[_contentURL release];
	
	[super dealloc];
}

- (NSString*)pathForFile:(NSString*)relativePath
{
	NSString* path = [_dataFolder stringByAppendingPathComponent:relativePath];
	NSFileManager* manager = [NSFileManager defaultManager];
	
	if([manager fileExistsAtPath:path])
	{
		return path;
	}
	
	return nil;
}

- (BOOL)checkForUpdatesWithCompletionHandler:(void (^)(BOOL updateFound, NSError* error))block
{
	if(!_contentURL)
	{
		NSLog(@"CPContentVersionURL not defined");
		return NO;
	}

	NSURL* url = [NSURL URLWithString:_contentURL];
	if(!url)
	{
		NSLog(@"CPContentVersionURL is not a valid URL");
		return NO;
	}
	
	ContentLoader* loader = [ContentLoader new];
	
	[loader loadWithVersionURL:url
					   version:_currentVersion 
						 block:^(NSInteger serverVersion, NSData *data, NSError *error) 
							{
								[loader autorelease];
								if(error)
								{
									block(NO, error);
									return;
								}
								
								if(data)
								{
									NSFileManager* fileManager = [NSFileManager new];
									
									BOOL dir;
									if([fileManager fileExistsAtPath:_dataFolder isDirectory:&dir] && dir)
									{
										[fileManager removeItemAtPath:_dataFolder error:&error];
										if(error)
										{
											NSLog(@"Error removing old content: %@", [error localizedDescription]);
											error = nil;
										}
									}
									
									if([fileManager createDirectoryAtPath:_dataFolder withIntermediateDirectories:NO attributes:nil error:&error])
									{
										[self extractFiles:data version:serverVersion fileManager:fileManager];
									}
									else if(error)
									{
										NSLog(@"Error creating direction: %@", [error localizedDescription]);
										error = nil;
									}
									
									[fileManager release];
									
									block(YES, nil);
								}
								else
								{
									block(NO, nil);
								}
							}];
	
	return YES;
}

+ (SSContentBundle*)bundleFromKey:(NSString*)key
{
	NSBundle* bundle = [NSBundle mainBundle];
	NSDictionary* infoDict = [bundle infoDictionary];
	NSDictionary* dict = [infoDict objectForKey:key];
	
	if(!dict)
	{
		NSLog(@"Count not create SSContentBundle. Missing key '%@'", key);
		return nil;
	}
	
	NSString* sourceFile = [dict objectForKey:@"SourceFile"];
	NSNumber* version = [dict objectForKey:@"SourceVersion"];
	NSString* serverURL = [dict objectForKey:@"VersionURL"];
	NSString* targetFolder = [dict objectForKey:@"TargetFolder"];
	
	if(!sourceFile)
	{
		NSLog(@"SourceFile not defined");
		return nil;
	}
	
	if(!version)
	{
		NSLog(@"SourceVersion not defined");
		return nil;
	}
	
	if(!targetFolder)
	{
		NSLog(@"TargetFolder not defined");
		return nil;
	}
	
	return [[[SSContentBundle alloc] initWithSource:sourceFile 
											version:[version intValue] 
										  serverURL:serverURL 
									   targetFolder:targetFolder] autorelease];
}

+ (SSContentBundle*)mainBundle
{
	if(!_provider)
	{		
		_provider = [[self bundleFromKey:@"SSContentBundle"] retain];
	}
	
	return _provider;
}

- (void)extractFiles:(NSData*)data version:(NSInteger)version fileManager:(NSFileManager*)fileManager
{
	if(!fileManager)
	{
		fileManager = [NSFileManager defaultManager];
	}
	
	void* sourceData = malloc(data.length);
	[data getBytes:sourceData length:data.length];
	
	HUNZIP huz = 0;
	
	UnzipOpenBuffer(&huz, sourceData, data.length, 0);

	ZIPENTRY ze;
	DWORD    numitems;
	
	ze.Index = (DWORD)-1;
	UnzipGetItem(huz, &ze);

	numitems = ze.Index;
	
	for (ze.Index = 0; ze.Index < numitems; ze.Index++)
	{
		UnzipGetItem(huz, &ze);
		if(!ze.UncompressedSize)
		{
			continue;
		}
		NSString* str = [NSString stringWithCString:ze.Name encoding:NSUTF8StringEncoding];
		if([str rangeOfString:@"__MACOSX"].length > 0)
		{
			continue;
		}
		
		//	NSLog(@"File: %@", str);
		NSString* filePath = [_dataFolder stringByAppendingPathComponent:str];
		if([str rangeOfString:@"/"].length > 0)
		{
			NSString* folder = [filePath stringByDeletingLastPathComponent];
			NSError* error;
			BOOL dir;
			if([fileManager fileExistsAtPath:folder isDirectory:&dir] && dir)
			{
				// no-op
			}
			else if(![fileManager createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:&error])
			{
				if(error)
				{
					NSLog(@"Error creating direction: %@", [error localizedDescription]);
					error = nil;
				}
			}
		}
		
		const char* fn = [filePath cStringUsingEncoding:NSASCIIStringEncoding];
		UnzipItemToFile(huz, fn, &ze);
	}
	
	UnzipClose(huz);
	
	free(sourceData);
	
	NSNumber* num = [NSNumber numberWithInt:version];
	NSString* numStr = [num description];
	NSError* error = nil;
	
	[numStr writeToFile:_versionPath atomically:NO encoding:NSASCIIStringEncoding error:&error];
	if(error)
	{
		NSLog(@"Error write file from zip: %@", [error localizedDescription]);
		error = nil;
	}
	
	_currentVersion = version;
}

@end

@implementation ContentLoader

- (void)loadWithVersionURL:(NSURL*)url version:(NSInteger)version block:(void (^)(NSInteger serverVersion, NSData* data, NSError* error))block
{
	_currentVersion = version;
	_block = [block copy];
	_versionURL = [url retain];
	_fetchingVersion = YES;
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)dealloc
{
	[_block release];
	[_data release];
	[_versionURL release];
	
	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(!_data)
	{
		_data = [data mutableCopy];
	}
	else
	{
		[_data appendData:data];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if(!_fetchingVersion)
	{
		_block(_serverVersion, _data, nil);
		[_data release];
		_data = nil;
		return;
	}

	NSString* str = [[NSString alloc] initWithData:_data encoding:NSASCIIStringEncoding];
	[_data release];
	_data = nil;
	
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	NSArray* array = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	if(array.count < 2)
	{
		NSError* error = [NSError errorWithDomain:@"ContentProvider" 
											 code:-1 
										 userInfo:[NSDictionary dictionaryWithObject:@"Version file is incomplete (requires 2 lines)" forKey:NSLocalizedDescriptionKey]];
		_block(0, nil, error);
		return;
	}
	
	NSInteger num = [[array objectAtIndex:0] intValue];
	if(num <= _currentVersion)
	{
		_block(num, nil, nil);
		return;
	}
	
	_serverVersion = num;
	_fetchingVersion = NO;
	
	NSURL* url = [[NSURL URLWithString:[array objectAtIndex:1] relativeToURL:_versionURL] absoluteURL];
	NSURLRequest* request = [NSURLRequest requestWithURL:url];
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	_block(0, nil, error);
}

@end