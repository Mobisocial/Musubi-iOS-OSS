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

#import "ObjProcessorService.h"
#import "PersistentModelStore.h"
#import "Musubi.h"
#import "MObj.h"
#import "MIdentity.h"
#import "MFeed.h"
#import "FeedManager.h"
#import "ObjManager.h"
#import "IdentityManager.h"
#import "Obj.h"
#import "ObjFactory.h"
#import "ObjHelper.h"
#import "NSData+HexString.h"

@implementation ObjProcessorService

@synthesize feedsToNotify, pendingParentHashes;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf {
    ObjectPipelineServiceConfiguration* config = [[ObjectPipelineServiceConfiguration alloc] init];
    config.model = @"Obj";
    config.selector = [NSPredicate predicateWithFormat:@"((processed == NO) OR (processed == nil)) AND (encoded != nil)"];
    config.notificationName = kMusubiNotificationAppObjReady;
    config.numberOfQueues = 1;
    config.operationClass = [ObjProcessOperation class];
    
    self = [super initWithStoreFactory:sf andConfiguration:config];
    if (self) {
        self.pendingParentHashes = [NSMutableDictionary dictionary];
    }
    return self;
}

@end

@implementation ObjProcessOperation

static int operationCount = 0;

+ (int) operationCount {
    return operationCount;
}

- (BOOL)performOperationOnObject:(NSManagedObject *)object {
    operationCount++;
    
    MObj* obj = (MObj*) object;
    
    @try {
        [self processObj: obj];
    } @catch (NSException *e) {
        [self log:@"Error while processing obj: %@", e];
        [self.store.context deleteObject: obj];
    } @finally {
        operationCount--;
    }
    
    return YES;
}

- (void) processObj:(MObj*)mObj {
    
    MIdentity* sender = mObj.identity;
    MFeed* feed = mObj.feed;    
    assert (mObj != nil);
    assert (mObj.universalHash != nil);
    if(mObj.processed) {
        NSLog(@"evil trying to reprocess obj %@", mObj);
        return;
    }
    assert (mObj.shortUniversalHash == *(uint64_t *)mObj.universalHash.bytes);
    
    if (mObj.processed)
        return;
    
    ObjProcessorService* service = (ObjProcessorService*) self.service;

    NSError* error;
    NSDictionary*parsedJson = [NSJSONSerialization JSONObjectWithData:[mObj.json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    NSString* targetHash = [parsedJson objectForKey:kObjFieldTargetHash];
    if (targetHash != nil) {
        NSString* targetRelation = [parsedJson objectForKey:kObjFieldTargetRelation];
        if (targetRelation == nil || [targetRelation isEqualToString:kObjFieldRelationParent]) {
            NSData* hash = [targetHash dataFromHex];
            ObjManager* objMgr = [[ObjManager alloc] initWithStore: self.store];
            MObj* parentObj = [objMgr objWithUniversalHash: hash];
            if (parentObj == nil) {
                [self log:@"Waiting for parent %@", targetHash];
                @synchronized(service.pendingParentHashes) {
                    NSMutableArray* children = [service.pendingParentHashes objectForKey:targetHash];
                    if(children == nil) {
                        children = [NSMutableArray array];
                        [service.pendingParentHashes setObject:children forKey:targetHash];
                    }
                    [children addObject:mObj.objectID];
                    mObj.processed = YES;
                    [self.store save];
                }
                return;
            }
            mObj.parent = parentObj;
        }
    }

    Obj* obj = [ObjFactory objFromManagedObj:mObj];
    NSLog(@"obj = %@", obj);
    NSLog(@"mObj = %@", mObj);
    if ([ObjHelper isRenderable: obj]) {
        [mObj setRenderable: YES];
        
        // Sometimes these things come in out of order
        NSTimeInterval objTime = [mObj.timestamp timeIntervalSince1970];
        if (objTime >= feed.latestRenderableObjTime) {
            // it seems sometimes we don't have the correct mObj here yet, let's get it
            [self.store save];

            [feed setLatestRenderableObjTime: [mObj.timestamp timeIntervalSince1970]];
            [feed setLatestRenderableObj: mObj];
        }
        
        if (!sender.owned) {
            [feed setNumUnread: feed.numUnread + 1];
        }
        [service.feedsToNotify addObject:feed.objectID];
    }

    BOOL keepObject = [obj processObjWithRecord: mObj];
    if (keepObject) {
        mObj.processed = YES;
    } else {
        [self log:@"Discarding %@", mObj.type];
        [self.store.context deleteObject: mObj];
    }
    
    FeedManager* feedManager = [[FeedManager alloc] initWithStore: self.store];
    if (feed.type == kFeedTypeOneTimeUse) {
        [feedManager deleteFeedAndMembers: feed];
    }
    
    [self.store save];
    
    [self log:@"Processed: %@", obj];
    
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationUpdatedFeed object:feed.objectID];

    NSMutableArray* children = nil;
    @synchronized(service.pendingParentHashes) {
        children = [service.pendingParentHashes objectForKey:targetHash];
        if(children)
            [service.pendingParentHashes removeObjectForKey:targetHash];
    }
    
    if(children != nil && children.count) {
        for(NSManagedObjectID* oid in children) {
            NSError* error;
            MObj* child = (MObj*)[self.store.context existingObjectWithID:oid error:&error];
            if(!child)
                continue;
            child.processed = NO;
        }
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationAppObjReady object:nil];
        [self.store save];
    }
}

@end