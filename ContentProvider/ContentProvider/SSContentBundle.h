//
//  SSContentBundle.h
//  SSContentBundle
//
//  Created by Steve Saxon on 5/19/11.
//  Copyright 2011 Steve Saxon. All rights reserved.
//

#import <Foundation/Foundation.h>



/*!
 @class SSContentBundle

 @abstract This class provides a mechanism for extracting application content 
 from a zip file store in the app's bundle.
 
 @discussion The info.plist contains a section for the content bundle. This section
 identifies the name of the zip, its version number (to identify later updates),
 and the name of the Documents sub-folder where the content will be expanded.
 <p>Once the zip contents are expanded into the app's Documents direction, from where they can be loaded using the regular file APIs,
 or referenced using views such a WebView.</p>
 <p>The info.plist section may also contain a URL reference to a location on the 
 Internet that can be checked for updates.</p> 
 */

@interface SSContentBundle : NSObject {
    NSString* _dataFolder;
    NSString* _versionPath;
	NSInteger _currentVersion;
	NSString* _contentURL;
}

/*!
 @property version
 @abstract Returns the version number of the content.
 */
@property (readonly) NSInteger version;

/*!
 @method mainBundle
 @abstract Returns the content bundle identifed in the info.plist under the key "SSContentBundle".
 @result The content bundle, or nil if an error occurs.
 @discussion This method will extract the data from the zip file if not already present,
 or if the application reports a higher version number than the already extracted data
 (i.e. in the case of an application update).
 */
+ (SSContentBundle*)mainBundle;

/*!
 @method bundleFromKey:
 @abstract Returns the content bundle identifed in the info.plist under the given key.
 @param key The key in the info.plist that contains the settings for this content bundle.
 @result The content bundle, or nil if an error occurs.
 @discussion This method will extract the data from the zip file if not already present,
 or if the application reports a higher version number than the already extracted data
 (i.e. in the case of an application update)
 */
+ (SSContentBundle*)bundleFromKey:(NSString*)key;

/*!
 @method pathForFile:
 @abstract Returns the full path for a relative file name in this bundle.
 @param relativePath The relative path to a file inside the original zip file.
 @result The full path of the file as it exists in the Documents directory, or nil if the file does not exist.
 */
- (NSString*)pathForFile:(NSString*)relativePath;

/*!
 @method checkForUpdatesWithCompletionHandler:
 @abstract Checks the server for updates to this content bundle.
 @param block The code block to be called when the content has been downloaded and updated.
 @result TRUE if a valid URL exists, and the request is issued to the server. 
 Returns FALSE if the URL does not exist, and the call cannot be made.
 */
- (BOOL)checkForUpdatesWithCompletionHandler:(void (^)(BOOL updateFound, NSError* error))block;

@end
