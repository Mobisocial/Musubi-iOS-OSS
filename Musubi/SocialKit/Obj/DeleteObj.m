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

#import "DeleteObj.h"
#import "ObjHelper.h"
#import "ObjManager.h"
#import "Musubi.h"
#import "NSData+HexString.h"
#import "MObj.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "PersistentModelStore.h"

@implementation DeleteObj

- (id) initWithData: (NSDictionary*) data {
    self = [super initWithType:kObjTypeDelete data:data andRaw:nil];
    return self;
}

- (id) initWithTargetObj:(MObj *)obj {
    self = [super init];
    if (self) {
        [self setType: kObjTypeDelete];
        NSString* objHash = [obj.universalHash hexString];
        NSArray* deletion = [[NSArray alloc] initWithObjects:objHash, nil];
        [self setData: [NSDictionary dictionaryWithObjectsAndKeys:deletion, kObjFieldHashes, nil]];        
    }
    
    return self;
}

- (BOOL)processObjWithRecord:(MObj *)deleteObj {
    NSArray *deletions = [self.data objectForKey: kObjFieldHashes];

    PersistentModelStore *store = [[Musubi sharedInstance] newStore];
    ObjManager* objMgr = [[ObjManager alloc] initWithStore: store];

    NSMutableSet* affectedFeeds = [NSMutableSet setWithCapacity:deletions.count];

    for (int i = 0; i < deletions.count; i++) {
        NSData* hashData = [[deletions objectAtIndex:i] dataFromHex];
        MObj* item = [objMgr objWithUniversalHash:hashData];
        //TODO: somehow defer processing?
        if(!item)
            continue;
        [affectedFeeds addObject:item.feed];
        if (deleteObj.identity.owned || !item.identity.owned) {
            [store.context deleteObject:item];
        } else {
            item.deleted = true;
        }
    }
    [store save];

    // Notify all affected feeds to update view
    for (MFeed* feed in affectedFeeds) {
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationUpdatedFeed object:feed.objectID];
    }

    return NO;
}

@end
