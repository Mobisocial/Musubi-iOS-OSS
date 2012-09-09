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


#import "AppDelegate.h"
#import "FacebookAuth.h"
#import "Musubi.h"
#import "APNPushManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "NSData+HexString.h"
#import "IBEncryptionScheme.h"
#import <DropboxSDK/DropboxSDK.h>

#import "PersistentModelStore.h"
#import "MObj.h"
#import "MIdentity.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"
#import "Util/MusubiShareKitConfigurator.h"
#import "SHKConfiguration.h"
#import "SHKFacebook.h"
#import "SHK.h"
#import "MusubiAnalytics.h"
#import "SettingsViewController.h"

#define kMusubiUriScheme @"musubi"
#import "IdentityManager.h"
#import "FeedListViewController.h"
#import "PictureObj.h"
#import "NSData+Base64.h"
#import "DejalActivityView.h"

static const NSInteger kGANDispatchPeriodSec = 60;

@implementation AppDelegate

@synthesize window = _window, facebookLoginOperation, navController, corralHTTPServer;

NSDictionary *objJson;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self prepareAnalytics];

    NSDate* showUIDate = [NSDate dateWithTimeIntervalSinceNow:1];
        
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:@"5ilykwqbdfy3wq6" appSecret:@"v5k6dskxe58ct68" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    [Musubi sharedInstance];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    [TTStyleSheet setGlobalStyleSheet:[[MusubiStyleSheet alloc] init]];
    
    // Pause on the loading screen for a bit, for awesomeness display reasons
    [NSThread sleepUntilDate:showUIDate];

    MusubiShareKitConfigurator *configurator = [[MusubiShareKitConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    [SHK flushOfflineQueue];

    return YES;
}

- (void) prepareAnalytics {
    [[GANTracker sharedTracker] startTrackerWithAccountID:@"xxx"
                                           dispatchPeriod:kGANDispatchPeriodSec
                                                 delegate:nil];
    
    NSError *error;
    if (![[GANTracker sharedTracker] setCustomVariableAtIndex:1
                                                         name:@"iPhone1"
                                                        value:@"iv1"
                                                    withError:&error]) {
        // Handle error here
    }

    if (![[GANTracker sharedTracker] trackPageview:kAnalyticsPageAppEntryPoint
                                         withError:&error]) {
        // Handle error here
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"received remote notification while running %@", userInfo);

    if( [userInfo objectForKey:@"local"] != NULL &&
       [userInfo objectForKey:@"amqp"] != NULL)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            //TODO: good and racy
            NSNumber* amqp = (NSNumber*)[userInfo objectForKey:@"amqp"]; 
            int local = [APNPushManager tallyLocalUnread]; 
            [application setApplicationIconBadgeNumber:(amqp.intValue + local) ];
        });
    }    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {     
    NSLog(@"Error in registration. Error: %@", err);
}    

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {          
    [Musubi sharedInstance].apnDeviceToken = [deviceToken hexString];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // launch the corral service
    self.corralHTTPServer = [[CorralHTTPServer alloc] init];
    NSError* corralError;
    if ([self.corralHTTPServer start:&corralError]) {
        NSLog(@"Corral server running on port %hu", [self.corralHTTPServer listeningPort]);
    } else {
        NSLog(@"Error starting corral server: %@", corralError);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [APNPushManager resetLocalUnreadInBackgroundTask:NO];

    // Shutdown corral http server
    [self.corralHTTPServer stop];
    self.corralHTTPServer = nil;

    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

-(void)restart
{
    NSLog(@"Restarting UI");
    UIStoryboard *storyboard;
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    }
    else {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    }
    UIViewController* vc = [storyboard instantiateInitialViewController];
    [self.window setRootViewController:vc];
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSString* facebookPrefix = [NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)];
    if ([url.scheme hasPrefix:facebookPrefix]) {
        BOOL shk, fb;
        shk = [SHKFacebook handleOpenURL:url];
        fb = [facebookLoginOperation handleOpenURL:url];
        
        return shk && fb;
    }
    
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        [((SettingsViewController*) self.window.rootViewController.childViewControllers.lastObject).tableView reloadData];
        [((SettingsViewController*) self.window.rootViewController.childViewControllers.lastObject).tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        [((SettingsViewController*) self.window.rootViewController.childViewControllers.lastObject).tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        return YES;
    }

    if ([url.scheme hasPrefix:kMusubiUriScheme]) {
        if ([url.path hasPrefix:@"/intro/"]) {
            // n, t, p
            NSArray *components = [[url query] componentsSeparatedByString:@"&"];
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            for (NSString *component in components) {
                [parameters setObject:[[component componentsSeparatedByString:@"="] objectAtIndex:0] forKey:[[component componentsSeparatedByString:@"="] objectAtIndex:1]];
            }
            NSString *idName = [parameters objectForKey:@"n"];
            NSString *idTypeString = [parameters objectForKey:@"t"];
            NSString *idValue = [parameters objectForKey:@"p"];

            if (idValue != nil && idTypeString != nil) {
                int idType = [idTypeString intValue];
                if (idName == nil) {
                    idName = idValue;
                }

                BOOL identityAdded = NO;
                BOOL profileDataChanged = NO;
                IdentityManager* im = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
                
                IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:idType principal:idValue temporalFrame:0];
                [im ensureIdentity:ident withName:idName identityAdded:&identityAdded profileDataChanged:&profileDataChanged];
            }

            return YES;
        } else if ([url.host isEqualToString:@"share"]) {
            [self shareObjFromUrl:url];
            return YES;
        }
    }
    return NO;
}

- (void) shareObjFromUrl: (NSURL *) url {
    NSString *encodedString = [url.path substringFromIndex:1];
    NSString *jsonString = [encodedString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    objJson = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    
    UIAlertView* alert;
    if (objJson != nil) {
        alert = [[UIAlertView alloc] initWithTitle:@"Sharing data" message:@"Click 'Okay' and choose a conversation for sharing, or click cancel to discard the data." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"Error sharing data" message:@"Error sharing data." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        NSLog(@"Error sharing data %@", jsonString);
    }
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        NSString *type = [objJson objectForKey:@"type"];
        NSDictionary* json = [objJson objectForKey:@"json"];
        if ([type isEqualToString:@"picture"]) {
            NSString *imgUrlString = [json objectForKey:@"src"];
            NSString *imgTitle = [json objectForKey:kTextField];
            NSString *imgCallback = [json objectForKey:kFieldCallback];
            NSURL *imgUrl = [NSURL URLWithString:imgUrlString];
            if (imgUrl != nil) {
                dispatch_async(dispatch_get_current_queue(), ^{
                    UINavigationController* nav = (UINavigationController*)self.window.rootViewController;
                    [DejalBezelActivityView activityViewForView:nav.view withLabel:@"Preparing data..." width:200];

                    UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imgUrl]];
                    Obj* obj = [[PictureObj alloc] initWithImage:image andText:imgTitle andCallback:imgCallback];
                    [DejalBezelActivityView removeViewAnimated:YES];
                    
                    [nav popToRootViewControllerAnimated:YES];
                    FeedListViewController *feedList = (FeedListViewController*) nav.topViewController;
                    [feedList setClipboardObj: obj];
                });
            } else {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error sharing data" message:@"Image data not found." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                [alert show];
            }
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error sharing data" message:@"Unsupported data type." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
        }
    }
    objJson = nil;
}

@end

@implementation NonAnimatedSegue

//@synthesize appDelegate = _appDelegate;

-(void) perform{
    [[[self sourceViewController] navigationController] pushViewController:[self destinationViewController] animated:NO];
}
@end
