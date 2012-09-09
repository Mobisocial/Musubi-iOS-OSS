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

#import <Foundation/Foundation.h>
#import "Facebook.h"

#define kFacebookAppId @"xxx"

@class MAccount, AccountAuthManager, SettingsViewController;

@interface FacebookAuthManager : NSObject<FBSessionDelegate> 

@property (nonatomic, strong) Facebook* facebook;

- (id) initWithDelegate: (id<FBSessionDelegate>) d;
- (void) fbDidLogin;

- (NSString*) activeAccessToken;

@end

// Abstract Facebook operation
@interface FacebookConnectOperation : NSOperation<FBSessionDelegate> {
    //these are here so the ivars are public so there are less self.'s
    AccountAuthManager* manager;
    FacebookAuthManager* facebookMgr;
    
    FacebookConnectOperation* me;
}

@property (nonatomic, strong) AccountAuthManager* manager;
@property (nonatomic, strong) FacebookAuthManager* facebookMgr;

- (id) initWithManager: (AccountAuthManager*) m;

@end


// Operation to check the facebook auth token validity
@interface FacebookCheckValidOperation : FacebookConnectOperation <FBRequestDelegate>
@property (nonatomic, strong) FBRequest* request;
@end

// Operation to create a new account by connecting to FB
@interface FacebookLoginOperation : FacebookConnectOperation <FBRequestDelegate> {
    BOOL finished;
}
@property (nonatomic, strong) FBRequest* request;

- (BOOL) handleOpenURL: (NSURL*) url;

@end