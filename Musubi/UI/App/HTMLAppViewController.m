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
#import "MIdentity.h"
#import "MObj.h"
#import "MEncodedMessage.h"
#import "MFeed.h"
#import "MApp.h"
#import "FeedManager.h"
#import "IdentityManager.h"
#import "NSData+HexString.h"

@implementation HTMLAppViewController

@synthesize app = _app, feed = _feed, obj = _obj;

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
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    NSURL* html = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:[NSString stringWithFormat: @"html5/apps/%@", _app.appId]];
    NSLog(@"HTML: %@, %@", html, _app.appId);
    NSLog(@"Web: %@", webView);
    [webView loadRequest:[NSURLRequest requestWithURL:html]];
    [webView setDelegate:self];
    ((UIScrollView*)[webView.subviews objectAtIndex:0]).bounces = NO;
    
//    [[Musubi sharedInstance] listenToGroup:[app feed] withListener:self];
    
    // change the back button to cancel and add an event handler
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(handleBack:)];
    self.navigationItem.leftBarButtonItem = backButton;    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"*** WebView failed to load, %@", error);
}

- (NSDictionary*) objToDict: (MObj*) obj {
    NSString* objId = [obj.universalHash hexString];
    return [NSDictionary dictionaryWithObjectsAndKeys:obj.type, @"type", objId, @"objId", obj.json, @"data", [self identityToDict:obj.encoded.fromIdentity], @"sender", obj.app.appId, @"appId", [NSString stringWithFormat:@"%lld", obj.feed.shortCapability], @"feedSession", [NSNumber numberWithInt:[obj.timestamp timeIntervalSince1970]], @"date", nil];
}
- (NSDictionary*) feedToDict: (MFeed*) feed {
    
    FeedManager* feedMgr = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    NSMutableArray* members = [NSMutableArray array];
    for (MIdentity* member in [feedMgr identitiesInFeed:feed]) {
        [members addObject:[self identityToDict:member]];
    }
    NSURL* feedId = [[feed objectID] URIRepresentation];
    return [NSDictionary dictionaryWithObjectsAndKeys:[feedMgr identityStringForFeed:_feed], @"name", [feedId absoluteString], @"session", members, @"members", nil];
}
- (NSDictionary*) identityToDict: (MIdentity*) identity {
    return [NSDictionary dictionaryWithObjectsAndKeys:[IdentityManager displayNameForIdentity:identity], @"name", identity.principal, @"id", identity.principal, @"personId", nil];
}

- (void) handleBack:(id) sender {
    NSString* jsBack = @"javascript:globalAppContext.back()";
    [webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsBack waitUntilDone:FALSE];
    //[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    NSString *iosBinding = [NSString stringWithContentsOfFile:@"html5/lib/platforms/socialKit-ios.js"];
    //[wv performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:iosBinding waitUntilDone:YES];
    
    // Launch app
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    
    NSDictionary* appDict = [NSDictionary dictionaryWithObjectsAndKeys:_app.appId, @"id", [self feedToDict:_feed], @"feed", [self objToDict:_obj], @"message", nil];
    NSString* appJson = [writer stringWithObject: appDict];
    
    FeedManager* feedMgr = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MIdentity* owned = [feedMgr ownedIdentityForFeed:_feed];
    NSString* userJson = [writer stringWithObject: [self identityToDict:owned]];
    
    NSDictionary* feedDict = [self feedToDict:_feed];
    NSString* feedJson = [writer stringWithObject:feedDict];
    
    NSString* objJson;
    if (_obj != nil) {
        NSDictionary* objDict = [self objToDict:_obj];
        objJson = [writer stringWithObject:objDict];
    } else {
        objJson = @"false";
    }
    NSLog(@"launching app from objC:\n  user: %@,\n  feed: %@,\n  app: %@,\n  obj: %@", userJson, feedJson, appJson, objJson);
    
    NSString* jsString = [NSString stringWithFormat:@"if (typeof Musubi !== 'undefined') {Musubi._launch(%@, %@, %@, %@);} else {alert('Musubi library not loaded. Please include musubiLib.js');}", userJson, feedJson, appJson, objJson];
    [wv performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:NO];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// This allows us to execute functions from Javascript. We can open URL's in the format musubi://class.method?key=value
- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    NSURL* url = [request URL];
    // NSLog(@"Load request %@", url);
    if ([[url scheme] isEqualToString:@"musubi"]) {
        URLFeedCommand* cmd = [URLFeedCommand createFromURL:url withApp:_app withViewController:self];
        id result = [cmd execute];

        cmd.viewController = nil; // clears circular reference? right?
        NSString* json = @"";
        if (result != nil) {
            SBJsonWriter* writer = [[SBJsonWriter alloc] init];
            NSError* err = nil;
            json = [writer stringWithObject: result];
            
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

@end
