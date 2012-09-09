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

#define kAddressBookIdentityUpdaterFrequency 14400.0

@class PersistentModelStoreFactory, PersistentModelStore;

@interface AddressBookIdentityManager : NSObject

@property (nonatomic, strong) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) NSOperationQueue* queue;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;

@end


@interface AddressBookIdentityFetchOperation : NSOperation {    
    BOOL _identityAdded;
    BOOL _profileDataChanged;
}

@property (nonatomic, strong) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) PersistentModelStore* store;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;

@end
