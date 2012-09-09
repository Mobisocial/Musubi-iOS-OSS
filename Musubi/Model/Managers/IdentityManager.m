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


#import "NSData+Crypto.h"

#import "IBEncryptionScheme.h"

#import "PersistentModelStore.h"
#import "IdentityManager.h"
#import "FeedManager.h"
#import "AccountManager.h"
#import "MAccount.h"
#import "MIdentity.h"
#import "MEncryptionUserKey.h"
#import "Authorities.h"

@implementation IdentityManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Identity" andStore:s];
    if (self != nil) {
    }
    return self;
}

- (void)updateIdentity:(MIdentity *)ident {
    
    assert(ident != nil);
    assert(ident.principalHash != nil && *(uint64_t*)ident.principalHash.bytes == ident.principalShortHash);
    assert(!ident.owned || ident.principal);

    // TOOD: synchronize code
    ident.updatedAt = [[NSDate date] timeIntervalSince1970] * 1000;
    [store save];
}

- (void) createIdentity:(MIdentity *)ident {
    assert(ident != nil);
    assert(ident.principalHash != nil);
    assert((*(uint64_t*)ident.principalHash.bytes) == ident.principalShortHash);
    assert(ident.principalShortHash != 0);
    assert(!ident.owned || ident.principal);
    
	// TOOD: synchronize code
    int64_t now = [[NSDate date] timeIntervalSince1970] * 1000;
    ident.createdAt = now;
    ident.updatedAt = now;
    
    [store save];
}

- (NSArray *)ownedIdentities {
    return [self query:[NSPredicate predicateWithFormat:@"owned=1"]];
}

- (MIdentity*) defaultIdentity {
    NSArray* owned = [self ownedIdentities];
    if (owned.count > 0)
        return [owned objectAtIndex: owned.count > 1 ? 1 : 0];
    
    return nil;
}

- (MIdentity*) defaultIdentityForParticipants: (NSArray*) participants {
    if (participants.count == 0)
        return [self defaultIdentity];
    
    for (MIdentity* mId in participants) {
        if (mId.owned)
            return mId;
    }
    
    FeedManager* feedManager = [[FeedManager alloc] initWithStore: store];
    AccountManager* accountManager = [[AccountManager alloc] initWithStore: store];
    
    NSArray* accounts = [accountManager claimedAccounts];
    if (accounts.count == 0)
        return [self defaultIdentity];
    if (accounts.count == 1)
        return ((MAccount*)[accounts objectAtIndex:0]).identity;
    
    NSMutableDictionary* map = [NSMutableDictionary dictionary];
    for (MAccount* acc in accounts) {
        if (acc.feed == nil)
            continue;
        
        int count = 0;
        if ([[map allKeys] containsObject:acc.identity.objectID])
            count = ((NSNumber*)[map objectForKey: acc.identity.objectID]).intValue;
        else
            count = 0;
        
        count += [feedManager countIdentitiesFrom: participants inFeed: acc.feed];
        [map setObject:[NSNumber numberWithInt:count] forKey:acc.identity.objectID];
    }
    
    NSManagedObjectID* bestIdentity = nil;
    int bestCount = 0;
    
    for (NSManagedObjectID* mId in [map allKeys]) {
        int curCount = ((NSNumber*)[map objectForKey:mId]).intValue;
        if (curCount > bestCount) {
            bestCount = curCount;
            bestIdentity = mId;
        }
    }
    
    if (bestIdentity)
        return (MIdentity*)[self queryFirst:[NSPredicate predicateWithFormat:@"self = %@", bestIdentity]];
    else
        return [self defaultIdentity];
}

- (IBEncryptionIdentity *) ibEncryptionIdentityForHasedIdentity: (IBEncryptionIdentity*) ident {
    if (ident.principal) {
        return ident;
    } else {
        MIdentity* mId = [self identityForIBEncryptionIdentity:ident];
        return [self ibEncryptionIdentityForIdentity:mId forTemporalFrame:ident.temporalFrame];
    }
}

- (MIdentity *)identityForIBEncryptionIdentity:(IBEncryptionIdentity *)ident {
    NSArray* results = [self query: [NSPredicate predicateWithFormat:@"(type == %d) AND (principalShortHash == %llu)", ident.authority, *(uint64_t*)[ident.hashed bytes]]];
    
    for (int i=0; i<results.count; i++) {
        MIdentity* match = [results objectAtIndex:i];
        if (![[match principalHash] isEqualToData:ident.hashed]) {
            continue;
        }
        return match;
    }
    return nil;
}

- (IBEncryptionIdentity *)ibEncryptionIdentityForIdentity:(MIdentity *)ident forTemporalFrame:(uint64_t) tf{
    if (ident.principal) {
        return [[IBEncryptionIdentity alloc] initWithAuthority:ident.type principal:ident.principal temporalFrame:tf];
    } else {
        return [[IBEncryptionIdentity alloc] initWithAuthority:ident.type hashedKey:ident.principalHash temporalFrame:tf];        
    }
}


- (MIdentity*) ensureIdentity: (IBEncryptionIdentity*) ibeId withName: (NSString*) name identityAdded: (BOOL*) identityAdded profileDataChanged: (BOOL*) profileDataChanged {
    FeedManager* feedManager = [[FeedManager alloc] initWithStore: store];
    MIdentity* mId = [self identityForIBEncryptionIdentity: ibeId];
    
    BOOL changed = NO;
    BOOL insert = NO;
    
    if (mId == nil) {
        insert = YES;
        
        mId = [self create];
        [mId setType: ibeId.authority];
        [mId setPrincipal: ibeId.principal];
        [mId setPrincipalHash: ibeId.hashed];
        [mId setPrincipalShortHash: *(uint64_t*)ibeId.hashed.bytes];
        [mId setName: name];
        assert(mId.principalShortHash != 0);
        
        *identityAdded = YES;
    }
    if(!mId.principal) {
        [mId setPrincipal: ibeId.principal];
    }
    
    if (!mId.whitelisted) {
        changed = YES;
        [mId setWhitelisted: YES];
        
        // Dont' change the blocked flag here, because it could only have
        // been set through explicit user interaction
        *identityAdded = YES;
    }
    
    if (name != nil) {
        changed = YES;
        [mId setName: name];
    }
    
    if (insert) {
        NSLog(@"Inserted user %@", name);
        [mId setWhitelisted: YES];
        [self createIdentity: mId];
        [feedManager acceptFeedsFromIdentity: mId];
    } else if (changed) {
        //NSLog(@"Updated user %@", name);
        [self updateIdentity: mId];
        *profileDataChanged = YES;
    }
    
    return mId;
}

- (uint64_t) computeTemporalFrameFromPrincipal: (NSString*) principal {
    return [self computeTemporalFrameFromHash: [[principal dataUsingEncoding:NSUTF8StringEncoding] sha256Digest]];
}

- (uint64_t)computeTemporalFrameFromHash:(NSData *)hash {
    return 0;
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    [to setNextSequenceNumber: to.nextSequenceNumber + 1];
}

+ (NSString *)displayNameForIdentity:(MIdentity *)ident {
    if (ident && ident.musubiName != nil) {
        return ident.musubiName;
    } else if (ident && ident.name != nil) {
        return ident.name;
    } else if (ident && ident.principal != nil) {
        return ident.principal;
    } else {
        return @"Unknown";
    }
}
- (NSArray*) whitelistedIdentities
{
    //TODO: why can't we be enemies
    return [self query:nil];   
}
- (NSArray *)identitiesWithSentEqual0 {
    return [self query:[NSPredicate predicateWithFormat:@"sentProfileVersion=0"]];
}
- (NSArray *)claimedIdentities {
    return [self query:[NSPredicate predicateWithFormat:@"claimed=1"]];
}

/* don't use this right now... need to discuss how to properly handle deletes
 since other code references identities */
- (void)deleteIdentity:(MIdentity *)identity {
    
    
    IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:identity.principal temporalFrame:0];
    
    for (MEncryptionUserKey* userKey in [store query:[NSPredicate predicateWithFormat:@"identity = %@", identity] onEntity:@"EncryptionUserKey"]) {
        NSLog(@"userkey: %@", userKey.identity.principal);
        [store.context deleteObject:userKey];
    }
    
    [store.context deleteObject:[self identityForIBEncryptionIdentity:ident]];
    [store save];
}
@end
