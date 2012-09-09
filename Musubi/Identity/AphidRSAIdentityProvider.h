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
#import "IdentityProvider.h"
#import "IdentityManager.h"


#define kMusubiExceptionAphidNeedRetry @"AphidNeedRetry"
#define kMusubiExceptionAphidBadToken @"AphidBadToken"

@interface AphidRSAIdentityProvider : NSObject<RSAIdentityProvider>

@property (nonatomic, strong) RSAIdentityManager* identityManager;
@property (nonatomic, strong) NSMutableDictionary* knownTokens;

@end

@interface AphidRSARequest : NSOperation<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableURLRequest* request;

@property (nonatomic, strong) id response;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, assign) BOOL finished;

- (id) initWithRequestDictionary: (NSDictionary*) dict;

@end
