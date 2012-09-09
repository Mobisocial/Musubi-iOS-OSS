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

#define kFacebookIdentityUpdaterFrequency 14400.0

@class PersistentModelStoreFactory, PersistentModelStore, FacebookAuthManager, IBEncryptionIdentity, MIdentity;

@interface FacebookIdentityUpdater : NSObject
@property (nonatomic, strong) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) NSOperationQueue* queue;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;

@end


@interface FacebookIdentityFetchOperation : NSOperation<FBRequestDelegate> {
    BOOL _identityAdded;
    BOOL _profileDataChanged;
    
    // We need a reference to ourselves to not get released...ARC what?
    FacebookIdentityFetchOperation* me;
}

@property (nonatomic, strong) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) PersistentModelStore* store;
@property (nonatomic, strong) FacebookAuthManager* authManager;
@property (nonatomic, strong) FBRequest* request;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;

@end