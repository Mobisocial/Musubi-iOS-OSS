/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "HTMLAppViewController.h"

@implementation HTMLAppViewController

@synthesize app;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        updates = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL* html = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:[NSString stringWithFormat: @"apps/%@", app.id]];
    [webView loadRequest:[NSURLRequest requestWithURL:html]];
    [webView setDelegate:self];
    ((UIScrollView*)[webView.subviews objectAtIndex:0]).bounces = NO;

    
    [[Musubi sharedInstance] listenToGroup:[app feed] withListener:self];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    // Launch app
    NSError* err = nil;
    SBJsonWriter* writer = [[[SBJsonWriter alloc] init] autorelease];
    NSString* appJson = [writer stringWithObject: [app json] error:&err];
    if (err != nil) {
        NSLog(@"Error: %@", err);
    }
    User* user = [[Identity sharedInstance] user];
    NSString* userJson = [writer stringWithObject: [user json] error:&err];
    if (err != nil) {
        NSLog(@"Error: %@", err);
    }
    
    NSString* jsString = [NSString stringWithFormat:@"if (typeof Musubi !== 'undefined') {Musubi._launchApp(%@, %@);} else {alert('Musubi library not loaded. Please include musubiLib.js');}", appJson, userJson];
    /*
    NSString* jsString = [NSString stringWithFormat:@"function checkMusubi() {if (typeof Musubi !== 'undefined') {Musubi._launchApp(%@);} else {setTimeout(checkMusubi, 500);}}; checkMusubi() ", feedJson];*/
    [wv performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:NO];    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [updates release];
    updates = nil;
    
    [webView release];
    webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// This allows us to execute functions from Javascript. We can open URL's in the format musubi://class.method?key=value
- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL* url = [request URL];
    
    if ([[url scheme] isEqualToString:@"musubi"]) {
        URLFeedCommand* cmd = [URLFeedCommand createFromURL:url withApp: app];
        id result = [cmd execute];
        
        NSString* json = @"";
        if (result != nil) {
            SBJsonWriter* writer = [[[SBJsonWriter alloc] init] autorelease];
            NSError* err = nil;
            json = [writer stringWithObject: result error:&err];
            
            if (err != nil) {
                NSLog(@"JSON Encoding error: %@", err);
            }
        }
        
        NSString* jsString = [NSString stringWithFormat:@"Musubi.platform._commandResult(%@);", json];
        [wv performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:FALSE];
        return NO;
    } else if ([[url scheme] isEqualToString:@"console"]) {
        NSLog(@"Javascript: %@", [[url queryComponents] objectForKey:@"log"]);
        return NO;
    } else if ([[url scheme] isEqualToString:@"config"]) {
        NSLog(@"Getting config: %@", [url queryComponents]);
        [self setTitle: [[url queryComponents] objectForKey:@"title"]];
        return NO; 
    } else {
        return YES;
    }
}

- (void)newMessage:(SignedMessage *)message {
    SBJsonWriter* writer = [[[SBJsonWriter alloc] init] autorelease];
    NSError* err = nil;
    NSString* jsString = [NSString stringWithFormat:@"Musubi._newMessage(%@);", [writer stringWithObject:[message json] error:&err]];
    if (err != nil) {
        NSLog(@"JSON Encoding error: %@", err);
    }
    NSLog(@"JSON: %@", jsString);
    [webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:FALSE];
}

@end
