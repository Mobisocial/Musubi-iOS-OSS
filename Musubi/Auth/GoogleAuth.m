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


#import "GoogleAuth.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "SBJSON.h"
#import "MAccount.h"
#import "MIdentity.h"
#import "Musubi.h"
#import "AccountAuthManager.h"
#import "Authorities.h"
#import "UIImage+Resize.h"
#import "IdentityManager.h"

static GTMOAuth2Authentication* active;

@implementation GoogleAuthManager

- (GTMOAuth2Authentication*) activeAuth {
    if (active != nil)
        return active;
    else {
        GTMOAuth2Authentication *auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kGoogleKeyChainItemName clientID:kGoogleClientId clientSecret:kGoogleClientSecret];
        
        if ([auth canAuthorize]) {
            NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]];
            [auth authorizeRequest:req
                 completionHandler:^(NSError *error) {
                     CFRunLoopStop(CFRunLoopGetCurrent());
                 }];

            CFRunLoopRun();
            active = auth;
        }
        
        return active;
    }
    
    return nil;
}

- (NSString *)activeAccessToken {
    GTMOAuth2Authentication* auth = self.activeAuth;
    return [auth.accessToken copy];
}

- (void) didLoginWith: (GTMOAuth2Authentication*) auth {
    active = auth;
}


@end

@implementation GoogleOAuthOperation

@synthesize manager, googleMgr;

- (id)initWithManager:(AccountAuthManager *)m {
    self = [super init];
    if (self) {
        [self setManager:m];
        [self setGoogleMgr: [[GoogleAuthManager alloc] init]];

        // need this reference so we won't be released when we do the CFRunLoopRun()
        me = self;
    }
    return self;
}

- (void) fetchUserInfo {
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]];
    
    GTMOAuth2Authentication* auth = [googleMgr activeAuth];
    [auth authorizeRequest:req
                  delegate:self
         didFinishSelector:@selector(authentication:request:finishedWithError:)];
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error {
}


@end


@implementation GoogleOAuthCheckValidOperation

- (void)main {
    BOOL active = NO;
    if(googleMgr.activeAuth) {
        NSString* email = googleMgr.activeAuth.userEmail;
        active = [googleMgr activeAccessToken] != nil && [manager checkAccount:kAccountTypeGoogle name:email principal:email];
    }
    
    [manager onAccount:kAccountTypeGoogle isValid:active];
}

@end


@implementation GoogleOAuthLoginOperation

- (void)start {
    [super start];
    [self openDialog];
    
    CFRunLoopRun(); // Avoid thread exiting
}

- (void)finish
{
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissModalViewControllerAnimated:YES];
    CFRunLoopStop(CFRunLoopGetCurrent());
    
    me = nil;
}

- (void) openDialog {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(openDialog) withObject:nil waitUntilDone:YES];
        return;
    }
    
    GTMOAuth2ViewControllerTouch* vc = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGoogleOAuthScope clientID:kGoogleClientId clientSecret:kGoogleClientSecret keychainItemName:kGoogleKeyChainItemName delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    [vc setBackButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
    
    UIViewController* root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UINavigationController* navController = (UINavigationController*)root;
//    UINavigationController* settingsNavController = (UINavigationController*)[root.childViewControllers objectAtIndex:1];
    
    [navController pushViewController:vc animated:YES];
}

- (void) viewController: (GTMOAuth2ViewControllerTouch*) vc finishedWithAuth: (GTMOAuth2Authentication*) auth error: (NSError*) error {
    if (error == nil) {
        [googleMgr didLoginWith:auth];
        [self fetchUserInfo];
    } else {
        NSLog(@"Error: %@", error);
        [self finish];        
    }
}

- (void) fetchUserInfo {
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]];
    
    GTMOAuth2Authentication* auth = [googleMgr activeAuth];
    [auth authorizeRequest:req
                  delegate:self
         didFinishSelector:@selector(authentication:request:finishedWithError:)];
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error {
    if (error != nil) {
        // Authorization failed
        NSLog(@"Error: %@", error);
        [self finish];
    } else {
        // Authorization succeeded
        NSURLConnection* conn = [NSURLConnection connectionWithRequest:request delegate:self];
        [conn start];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* dict = [parser objectWithString:json];
    
    if (dict != nil && [dict objectForKey:@"email"] != nil) {
        //NSLog(@"dict keys %@", [dict allKeys]);
        //NSLog(@"dict values %@", [dict allValues]);
        NSString* email = [dict objectForKey:@"email"];
        NSString* name = [dict objectForKey:@"given_name"];
        NSString* imageUrl = [dict objectForKey:@"picture"];
        NSLog(@"imageUrl = %@", imageUrl);
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        UIImage* resized = [image centerFitAndResizeTo:CGSizeMake(300, 300)];
                
        MAccount* account = [manager storeAccount:kAccountTypeGoogle name:name principal:email];
        
        IdentityManager* idMgr = [[IdentityManager alloc] initWithStore:[[Musubi sharedInstance] newStore]];
        
        for (MIdentity* ident in idMgr.ownedIdentities) {
            ident.musubiThumbnail = UIImageJPEGRepresentation(resized, 0.9);
            [idMgr updateIdentity:ident];
        }
        
        [manager onAccount:kAccountTypeGoogle isValid:account != nil];
        
        if (account) {
            [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationGoogleFriendRefresh object:nil];
        }
    } else {
        [manager onAccount:kAccountTypeGoogle isValid:NO];
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    [self finish];
}

@end
