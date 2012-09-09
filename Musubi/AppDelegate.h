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

#import <UIKit/UIKit.h>
#import "CorralHTTPServer.h"

@class FacebookLoginOperation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property ( nonatomic) UIWindow *window;
@property ( nonatomic) UINavigationController* navController;
@property (nonatomic, strong) CorralHTTPServer* corralHTTPServer;

// Facebook SingleSignOn always calls back the appDelegate, so we need a reference to the login
@property (nonatomic, weak) FacebookLoginOperation* facebookLoginOperation;

- (void) restart;

@end


@interface NonAnimatedSegue : UIStoryboardSegue
@end