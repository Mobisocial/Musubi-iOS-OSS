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


#import "ObjManager.h"
#import "SBJSON.h"
#import "MObj.h"
#import "MFeed.h"
#import "Obj.h"
#import "MLikeCache.h"
#import "MLike.h"
#import "MIdentity.h"
#import "PersistentModelStore.h"
#import "StatusObj.h"

@implementation ObjManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Obj" andStore:s];
    if (self) {
        
    }
    return self;
}

- (MObj*) create {
    return (MObj*) [super create];
}

- (MObj*) createFromObj: (Obj*) obj onFeed: (MFeed*) feed {
    
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    NSString* json = [writer stringWithObject:obj.data];
    
    MObj* mObj = [self create];
    [mObj setType: obj.type];
    [mObj setJson: json];
    [mObj setRaw: obj.raw];
    [mObj setFeed: feed];
    
    return mObj;
}

- (MObj*) objWithUniversalHash: (NSData*) hashData {
    uint64_t shortHash = *(uint64_t*)hashData.bytes;
    return (MObj*)[self queryFirst:[NSPredicate predicateWithFormat:@"(shortUniversalHash == %lld)", shortHash]]; 
}

- (MObj*) latestChildForParent: (MObj *)parent {
    NSArray *res = [self query:[NSPredicate predicateWithFormat:@"(parent == %@)", parent] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"intKey" ascending:false] limit:1];
    if (res.count == 0) {
        return nil;
    }
    return (MObj*)[res objectAtIndex:0];
}

- (MObj*)latestStatusObjInFeed:(MFeed *)feed {
    return [self latestObjOfType:kObjTypeStatus inFeed:feed after:nil before:nil];
}

- (NSArray*)latestArrayObjOfType:(NSString*)type inFeed:(MFeed *)feed  after:(NSDate*)after before:(NSDate*)before {
    if(after && before) {
        return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (type == %@) AND (parent == nil) && (timestamp < %@) && (timestamp >= %@)", feed.objectID, type, after, before] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:1];
    } else if(after) {
        return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (type == %@) AND (parent == nil) && (timestamp < %@)", feed.objectID, type, after] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:1];
        
    } else if(before) {
        return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (type == %@) AND (parent == nil) && (timestamp >= %@)", feed.objectID, type, before] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:1];
    } else {
        return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (type == %@) AND (parent == nil)", feed.objectID, type] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:1];
    }
}

- (MObj*)latestObjOfType:(NSString*)type inFeed:(MFeed *)feed  after:(NSDate*)after before:(NSDate*)before {
    NSArray* arr = [self latestArrayObjOfType:type inFeed:feed after:after before:before];
    if(!arr.count)
        return nil;
    return [arr objectAtIndex:0];

}


- (NSArray *)pictureObjsInFeed:(MFeed *)feed {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (type == 'picture') AND ((processed == YES) OR (encoded == nil))", feed.objectID] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:TRUE] limit:-1];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed {
    return [self renderableObjsInFeed:feed limit:-1];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed limit:(NSInteger)limit {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil))", feed.objectID] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:limit];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed before:(NSDate*)beforeDate limit:(NSInteger)limit {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil)) AND (timestamp < %@)", feed.objectID, beforeDate] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:limit];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed after:(NSDate*)afterDate limit:(NSInteger)limit {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil)) AND (timestamp > %@)", feed.objectID, afterDate] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:limit];
}

- (NSArray *) likesForObj: (MObj*) obj {
    return [store query:[NSPredicate predicateWithFormat:@"(obj == %@)", obj] onEntity:@"Like"];
}
- (BOOL) feed:(MFeed*)feed withActivityAfter:(NSDate*)start until:(NSDate*)end
{
    if(start && end) {
        return [self queryFirst:[NSPredicate predicateWithFormat:@"(feed == %@) && (timestamp < %@) && (timestamp >= %@)", feed.objectID, start, end]] != nil;
    } else if(start) {
        return [self queryFirst:[NSPredicate predicateWithFormat:@"(feed == %@) && (timestamp < %@)", feed.objectID, start]] != nil;
    } else {
        return [self queryFirst:[NSPredicate predicateWithFormat:@"(feed == %@) && (timestamp >= %@)", feed.objectID, end]] != nil;
    }
    
}



- (void) saveLikeForObj: (MObj*) obj from: (MIdentity*) sender {
    
    // Need to get a sender in the current store context
    MIdentity* contextedSender = (MIdentity*)[store queryFirst:[NSPredicate predicateWithFormat:@"(self == %@)", sender.objectID] onEntity:@"Identity"];
    
    BOOL matched = NO;
    for (MLike* like in [store query:[NSPredicate predicateWithFormat:@"(obj == %@) AND (sender == %@)", obj, contextedSender] onEntity:@"Like"]) {
        if ([like.obj.objectID isEqual: obj.objectID]) {
            like.count += 1;
            matched = YES;
            break;
        }
    }
    
    if (!matched) {
        MLike* like = (MLike*)[store createEntity:@"Like"];

        like.obj = obj;
        like.sender = contextedSender;
        like.count = 1;
    }
    
    [store save];
}

- (MLikeCache*) likeCountForObj: (MObj*) obj {
    return (MLikeCache*)[store queryFirst:[NSPredicate predicateWithFormat:@"(parentObj == %@)", obj] onEntity:@"LikeCache"];
}

- (void) increaseLikeCountForObj: (MObj*) obj local: (BOOL) local {
    MLikeCache* likes = [self likeCountForObj:obj];
    
    if (!likes) {
        likes = (MLikeCache*)[store createEntity:@"LikeCache"];
        likes.parentObj = obj;
    }
    
    likes.count += 1;
    
    if (local)
        likes.localLike += 1;
    
    [store save];
}

@end
