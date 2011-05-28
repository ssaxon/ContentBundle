//
//  RootViewController.m
//  ContentTest
//
//  Created by Steve Saxon on 5/27/11.
//  Copyright 2011 Neudesic LLC. All rights reserved.
//

#import "RootViewController.h"
#import "SSContentBundle.h"


@implementation RootViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SSContentBundle* provider = [SSContentBundle mainBundle];
    NSString* docPath = [provider pathForFile:@"index.html"];
    
    NSLog(@"Path to index.html: %@", docPath);
    
    NSURL* url = [NSURL fileURLWithPath:docPath];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    UIWebView* webView = (UIWebView*)self.view;
    [webView loadRequest:request];
}

- (IBAction)performUpdate:(id)sender
{
    SSContentBundle* provider = [SSContentBundle mainBundle];

	[provider checkForUpdatesWithCompletionHandler:^(BOOL updateFound, NSError *error) 
	 {
		 if(error)
		 {
			 NSLog(@"Error removing old content: %@", [error localizedDescription]);
			 [error release];
			 error = nil;
		 }
         
         // refresh the browser...
         UIWebView* webView = (UIWebView*)self.view;
         [webView reload];
	 }];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
