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

@class PersistentModelStore, PersistentModelStoreFactory;



@interface ObjectPipelineServiceConfiguration : NSObject

typedef int(^QueueSelector)(NSManagedObject* obj);

@property (nonatomic, strong) NSString* model;
@property (nonatomic, strong) NSPredicate* selector;
@property (nonatomic, strong) NSString* notificationName;
@property (nonatomic, strong) Class operationClass;
@property (nonatomic, assign) int numberOfQueues;
@property (nonatomic, strong) QueueSelector queueSelector; 

@end

@interface ObjectPipelineService : NSObject

@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) ObjectPipelineServiceConfiguration* config;
@property (nonatomic, strong) NSMutableArray* pending;
@property (nonatomic, strong) NSMutableArray* queues;
@property (nonatomic, strong) NSLock* pendingLock;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andConfiguration: (ObjectPipelineServiceConfiguration*) config;
- (void) start;
- (void) stop;
- (BOOL) isFinished;

@end

@interface ObjectPipelineOperation : NSOperation

@property (nonatomic, retain) NSManagedObjectID* objId;
@property (nonatomic, retain) ObjectPipelineService* service;
@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, assign) int retryCount;

- (id) initWithObjectId: (NSManagedObjectID*) objId andService: (ObjectPipelineService*) service;
- (BOOL)performOperationOnObject: (NSManagedObject*) object;
- (void) log:(NSString*) format, ...;
- (void)removePending;
@end