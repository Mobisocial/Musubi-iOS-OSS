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


#import "NearbyFeed.h"
#import <CoreData/CoreData.h>
#import "MFeed.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "Authorities.h"
#import "FeedManager.h"
#import "PersistentModelStore.h"
#import "FeedListItem.h"
#import "NSData+Base64.h"
#import "JoinRequestObj.h"
#import "ObjHelper.h"
#import "AppManager.h"
#import "Musubi.h"
#import "Authorities.h"
#import "IBEncryptionScheme.h"

@implementation NearbyFeed
@synthesize groupCapability, groupName, thumbnail, sharerHash, sharerName, sharerType, memberCount;

-(id)initWithJSON:(NSDictionary *)descriptor
{
    self = [super init];
    if(!self)
        return nil;
    
    groupName = [descriptor objectForKey:@"group_name"];
    groupCapability = [[descriptor objectForKey:@"group_capability"] decodeBase64];
    sharerName = [descriptor objectForKey:@"sharer_name"];
    sharerType = ((NSNumber*)[descriptor objectForKey:@"sharer_type"]).intValue;
    sharerHash = [[descriptor objectForKey:@"sharer_hash"] decodeBase64];
    memberCount = ((NSNumber*)[descriptor objectForKey:@"member_count"]).intValue;
    thumbnail = [[descriptor objectForKey:@"thumbnail"] decodeBase64];
    return self;
}

- (id)initWithFeedId:(NSManagedObjectID*)feedId andStore:(PersistentModelStore*)store
{
    self = [super init];
    if(!self)
        return nil;
    
    FeedManager* fm = [[FeedManager alloc] initWithStore:store];
    NSError* error;
    MFeed* feed = (MFeed*)[store.context existingObjectWithID:feedId error:&error];
    NSAssert(feed.type == kFeedTypeExpanding, @"feed must be expanding");
    if(!feed) {
        NSLog(@"failed to look up feed for broadcast,.. obj id = %@", feedId);
        @throw error;
    }
        
    groupCapability = feed.capability;
    groupName = [fm identityStringForFeed:feed];
    memberCount = [fm identitiesInFeed:feed].count;
    
    IdentityManager* im = [[IdentityManager alloc] initWithStore:store];
    NSArray* mine = [im ownedIdentities];
    MIdentity* sharer = nil;
    for(MIdentity* me in mine) {
        if(me.type != kIdentityTypeLocal) {
            sharer = me;
            break;
        }
    }
    NSAssert(sharer, @"A non-local identity must already be bound");
    sharerType = sharer.type;
    sharerHash = sharer.principalHash;
    sharerName = sharer.musubiName;
    if(!sharerName)
        sharerName = sharer.name;
    if(!sharerName)
        sharerName = sharer.principal;
    if(!sharerName)
        sharerName = @"Unknown";
    
    thumbnail = feed.thumbnail;
    if(!thumbnail)
        thumbnail = sharer.musubiThumbnail;
    if(!thumbnail)
        thumbnail = sharer.thumbnail;
    
    return self;
}

- (void)join 
{
    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
    IdentityManager* im = [[IdentityManager alloc] initWithStore:store];
    AppManager* am = [[AppManager alloc] initWithStore:store];
    FeedManager* fm = [[FeedManager alloc] initWithStore:store];
    
    MIdentity* me = nil;
    for(MIdentity* maybe in [im ownedIdentities]) {
        if(maybe.type != kIdentityTypeLocal) {
            me = maybe;
            break;
        }
    }
    NSAssert(me, @"Must have an identity bound");
    JoinRequestObj* jr = [[JoinRequestObj alloc] initWithIdentities:[NSArray arrayWithObject:me]];
    MFeed* feed = [fm feedWithType:kFeedTypeExpanding andCapability:groupCapability];
    if(!feed) {
        feed = [fm create];
        feed.type = kFeedTypeExpanding;
        feed.capability = groupCapability;
        feed.shortCapability = *(int64_t*)[groupCapability bytes];
        feed.name = groupName;
        feed.thumbnail = thumbnail;

        [fm attachMember:me toFeed:feed];
        BOOL added = NO, changed = NO;
        IBEncryptionIdentity* hid = [[IBEncryptionIdentity alloc] initWithAuthority:sharerType hashedKey:sharerHash temporalFrame:0];
        MIdentity* sharer = [im ensureIdentity:hid withName:sharerName identityAdded:&added profileDataChanged:&changed];
        [fm attachMember:sharer toFeed:feed];
        
        [store save];    
        MApp* app = [am ensureSuperApp];
        [ObjHelper sendObj:jr toFeed:feed fromApp:app usingStore:store];
    } else {
        feed.latestRenderableObjTime = [[NSDate date] timeIntervalSince1970];
        [store save];    
    }
    
}

@end
