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


#import "TransportManager.h"

#import "IBEncryptionScheme.h"

#import "PersistentModelStore.h"
#import "IdentityManager.h"
#import "SignatureUserKeyManager.h"
#import "EncryptionUserKeyManager.h"
#import "OutgoingSecretManager.h"

#import "MMissingMessage.h"
#import "MSequenceNumber.h"
#import "MIdentity.h"
#import "MIncomingSecret.h"
#import "MOutgoingSecret.h"
#import "MDevice.h"
#import "MEncodedMessage.h"

@implementation TransportManager

@synthesize store, encryptionScheme, signatureScheme, deviceName, identityManager, encryptionUserKeyManager, signatureUserKeyManager;

- (id)initWithStore:(PersistentModelStore *)s encryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss deviceName:(uint64_t)devName {
    self = [super init];
    
    if (self != nil) {
        [self setStore: s];
        [self setEncryptionScheme: es];
        [self setSignatureScheme: ss];
        [self setDeviceName: devName];
        
        [self setIdentityManager: [[IdentityManager alloc] initWithStore: store]];
        [self setEncryptionUserKeyManager: [[EncryptionUserKeyManager alloc] initWithStore: store encryptionScheme:es]];
        [self setSignatureUserKeyManager: [[SignatureUserKeyManager alloc] initWithStore: store signatureScheme:ss]];
    }
    
    return self;
}

- (void)setStore:(PersistentModelStore *)s {
    store = s;
    
    [identityManager setStore:s];
}

- (uint64_t)signatureTimeFrom:(MIdentity *)from {
    //TODO: consider revocation/online offline status, etc
    return [identityManager computeTemporalFrameFromHash: from.principalHash];
}

- (uint64_t)encryptionTimeTo:(MIdentity *)to {
    //TODO: consider revocation/online offline status, etc
    return [identityManager computeTemporalFrameFromHash: to.principalHash];
}

-  (IBSignatureUserKey *)signatureKeyFrom:(MIdentity *)from myIdentity:(IBEncryptionIdentity *)me {
    return [signatureUserKeyManager signatureKeyFrom:from me:me];
}

- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me {
    return [encryptionUserKeyManager encryptionKeyTo:to me:me];
}

- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    return (MOutgoingSecret*)[store queryFirst:[NSPredicate predicateWithFormat:@"myIdentity = %@ AND otherIdentity = %@ AND encryptionPeriod = %llu AND signaturePeriod = %llu", from, to, other.temporalFrame, me.temporalFrame] onEntity:@"OutgoingSecret"];
}

- (void)insertOutgoingSecret:(MOutgoingSecret *)os myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    //if (os.objectID.isTemporaryID)
    //    [store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:os] error:nil];
    [store.context insertObject:os];
    [store save];
}

- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice:(MDevice *)device to:(MIdentity *)to withSignature:(NSData *)signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"myIdentity = %@ AND otherIdentity = %@ AND encryptionPeriod = %llu AND signaturePeriod = %llu AND device = %@", to, from, me.temporalFrame, other.temporalFrame, device];
    
    NSArray* results = [store query:predicate onEntity:@"IncomingSecret"];
    for (int i=0; i<results.count; i++) {
        MIncomingSecret* secret = (MIncomingSecret*) [results objectAtIndex:i];
        
        // It's possible to have different signatures on the same set of parameters; skip
        if (![secret.signature isEqualToData:signature])
            continue;
        
        return secret;
    }
    
    return nil;
}

- (void)insertIncomingSecret:(MIncomingSecret *)is otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    //if (is.objectID.isTemporaryID)
    //    [store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:is] error:nil];

    [store.context insertObject:is];
    [store save];
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    [identityManager incrementSequenceNumberTo: to];
}

- (void)receivedSequenceNumber:(uint64_t)sequenceNumber from:(MDevice *)device {
    MMissingMessage* mm = (MMissingMessage*) [store queryFirst:[NSPredicate predicateWithFormat:@"device = %@ AND sequenceNumber = %llu", device, sequenceNumber] onEntity:@"MissingMessage"];
    if (mm) {
        [[store context] deleteObject:mm];
    }
}

- (void)storeSequenceNumbers:(NSDictionary *)seqNumbers forEncodedMessage:(MEncodedMessage *)encoded {
    NSEnumerator* keyEnum = [seqNumbers keyEnumerator];
    while (true) {
        NSData* rcptHash = (NSData*) [keyEnum nextObject];
        if (rcptHash == nil)
            break;
        
        MIdentity* ident = (MIdentity*)[store queryFirst:[NSPredicate predicateWithFormat:@"principalHash=%@", rcptHash] onEntity:@"Identity"];
        
        MSequenceNumber* seqNumber = (MSequenceNumber*) [store createEntity:@"SequenceNumber"];
        [seqNumber setRecipient:ident];
        [seqNumber setSequenceNumber: [(NSNumber*)[seqNumbers objectForKey:ident] longLongValue]];
        [seqNumber setEncodedMessage: encoded];
    }
}

- (BOOL)isBlackListed:(MIdentity *)ident {
    return FALSE;
}

- (BOOL)isMe:(IBEncryptionIdentity *)ident {
    NSArray* results = [store query:[NSPredicate predicateWithFormat:@"type = %d AND principalShortHash = %llu AND owned = 1", (int32_t)ident.authority, *(uint64_t*)ident.hashed.bytes] onEntity:@"Identity"];
    return (results.count > 0);
}

- (MIdentity*) addClaimedIdentity:(IBEncryptionIdentity *)ident {
    MIdentity* mIdent = [identityManager identityForIBEncryptionIdentity:ident];
    
    if (mIdent != nil) {
        if (!mIdent.claimed) {
            [mIdent setClaimed: YES];
            [identityManager updateIdentity:mIdent];
        }
    } else {
        mIdent = [identityManager create];
        [mIdent setClaimed: YES];
        [mIdent setPrincipalHash: ident.hashed];
        [mIdent setPrincipalShortHash: *(uint64_t*)ident.hashed.bytes];
        [mIdent setType: ident.authority];        
        [identityManager createIdentity:mIdent];    
    }
    
    return mIdent;
}

- (MIdentity *)addUnclaimedIdentity:(IBEncryptionIdentity *)ident {
    MIdentity* mIdent = [identityManager identityForIBEncryptionIdentity:ident];
  
    if (mIdent == nil) {
        mIdent = [identityManager create];
        [mIdent setClaimed: NO];
        [mIdent setPrincipalHash: ident.hashed];
        [mIdent setPrincipalShortHash: *(uint64_t*)ident.hashed.bytes];
        [mIdent setType: ident.authority];
        
        [identityManager createIdentity:mIdent];    
    }
    
    return mIdent;
}

- (MDevice *)addDeviceWithName:(uint64_t)devName forIdentity:(MIdentity *)ident {
    
    MDevice* dev = (MDevice*) [store queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND deviceName = %llu", ident, devName] onEntity:@"Device"];
    
    if (dev == nil) {
        dev = (MDevice*) [store createEntity:@"Device"];
        [dev setDeviceName: devName];
        [dev setIdentity: ident];
        [dev setMaxSequenceNumber: 0];
    }
    
    return dev;
}

- (void)insertEncodedMessage:(MEncodedMessage *)encoded forOutgoingMessage:(OutgoingMessage *)om {
    //if (encoded.objectID.isTemporaryID)
    //    [store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:encoded] error:nil];
    [store save];
}

- (void)updateEncodedMetadata:(MEncodedMessage *)encoded {
    //if (encoded.objectID.isTemporaryID)
    //    [store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:encoded] error:nil];
    [store save];
}

- (BOOL)haveHash:(NSData *)hash {
    MEncodedMessage* msg = (MEncodedMessage*)[store queryFirst:[NSPredicate predicateWithFormat:@"(shortMessageHash == %llu) AND (messageHash == %@)", *(uint64_t*)hash.bytes, hash] onEntity:@"EncodedMessage"];
    return msg != nil;
}


@end
