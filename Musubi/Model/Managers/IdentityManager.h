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
#import "EntityManager.h"

#define kIBEncryptionUserKeyRefreshSeconds 2592000 //30 * 24 * 60 * 60

@class IBEncryptionIdentity, MIdentity;

@interface IdentityManager : EntityManager

- (id) initWithStore: (PersistentModelStore*) s;

- (void) updateIdentity: (MIdentity*) ident;
- (void) createIdentity:(MIdentity *)ident;

- (NSArray*) ownedIdentities;
- (MIdentity*) defaultIdentity;
- (MIdentity*) defaultIdentityForParticipants: (NSArray*) participants;
- (MIdentity*) identityForIBEncryptionIdentity: (IBEncryptionIdentity*) ident;
- (MIdentity*) ensureIdentity: (IBEncryptionIdentity*) ibeId withName: (NSString*) name identityAdded: (BOOL*) identityAdded profileDataChanged: (BOOL*) profileDataChanged;
- (IBEncryptionIdentity *) ibEncryptionIdentityForHasedIdentity: (IBEncryptionIdentity*) ident;
- (IBEncryptionIdentity*) ibEncryptionIdentityForIdentity: (MIdentity*) ident forTemporalFrame: (uint64_t) tf;
- (uint64_t) computeTemporalFrameFromHash: (NSData*) hash;
- (uint64_t) computeTemporalFrameFromPrincipal: (NSString*) principal;
- (void) incrementSequenceNumberTo:(MIdentity *)to;
- (NSArray*) whitelistedIdentities;
- (NSArray*) claimedIdentities;
- (NSArray*) identitiesWithSentEqual0;

+ (NSString*) displayNameForIdentity: (MIdentity*)ident;
- (void) deleteIdentity:(MIdentity *) ident;

@end
