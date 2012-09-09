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
#import <CoreData/CoreData.h>

#import "IdentityProvider.h"
#import "ObjectPipelineService.h"

@class PersistentModelStoreFactory, PersistentModelStore;
@class FeedManager, MusubiDeviceManager, TransportManager, AccountManager, AppManager, IdentityManager;
@class MessageDecoder;

@interface MessageDecodeService : ObjectPipelineService

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;

@property (nonatomic, retain) id<IdentityProvider> identityProvider;

@end


@interface MessageDecodeOperation : ObjectPipelineOperation {
    // ManagedObject is not thread-safe, ObjectID is
    NSMutableArray* _dirtyFeeds;
}

@property (nonatomic) NSMutableArray* dirtyFeeds;
@property (nonatomic, assign) BOOL shouldRunProfilePush;

@property (nonatomic) MessageDecoder* decoder;
@property (nonatomic) MusubiDeviceManager* deviceManager;
@property (nonatomic) IdentityManager* identityManager;
@property (nonatomic) TransportManager* transportManager;
@property (nonatomic) FeedManager* feedManager;
@property (nonatomic) AccountManager* accountManager;
@property (nonatomic) AppManager* appManager;

+ (int) operationCount;

@end