//
//  TransientTransportDataProvider.m
//  Musubi
//
//  Created by Willem Bult on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TransientTransportDataProvider.h"
#import "PersistentModelStore.h"
#import "NSData+Crypto.h"

@implementation DefaultBlackListProvider
- (BOOL)isBlackListed:(IBEncryptionIdentity *)identity {
    return FALSE;
}
@end

@implementation DefaultSignatureController
- (uint64_t)signingTimeForIdentity:(IBEncryptionIdentity *)hid {
    return *(uint64_t*)hid.hashed.bytes;
}
- (BOOL)hasSignatureKey:(IBEncryptionIdentity *)hid {
    return YES;
}
@end

@implementation DefaultEncryptionController
- (uint64_t)encryptionTimeForIdentity:(IBEncryptionIdentity *)hid {
    return *(uint64_t*)hid.hashed.bytes;
}
- (BOOL)hasEncryptionKey:(IBEncryptionIdentity *)hid {
    return YES;
}
@end

@implementation TransientTransportDataProvider

@synthesize blacklistProvider, signatureController, encryptionController, store, encryptionScheme,signatureScheme,myIdentity,deviceName,identities,identityLookup,devices,deviceLookup,encodedMessages,encodedMessageLookup,incomingSecrets,outgoingSecrets,missingSequenceNumbers;

- (id)initWithEncryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss identity:(IBEncryptionIdentity *)me blacklistProvicer:(id<BlackListProvider>)blacklist signatureController:(id<SignatureController>)sigController encryptionController:(id<EncryptionController>)encController {
    
    self = [super init];
    if (self != nil) {
        PersistentModelStoreFactory* factory = [[PersistentModelStoreFactory alloc] initWithName:@"TestStore1"];
        [self setStore: [factory newStore]];
        
        [self setEncryptionScheme: es];
        [self setSignatureScheme: ss];
        [self setMyIdentity: me];
        
        [self setDeviceName: random()];
        
        [self setIdentities: [[NSMutableDictionary alloc] init]];
        [self setIdentityLookup: [[NSMutableDictionary alloc] init]];
        [self setDevices: [[NSMutableDictionary alloc] init]];
        [self setDeviceLookup: [[NSMutableDictionary alloc] init]];
        [self setEncodedMessages: [[NSMutableDictionary alloc] init]];
        [self setEncodedMessageLookup: [[NSMutableDictionary alloc] init]];
        [self setIncomingSecrets: [[NSMutableDictionary alloc] init]];
        [self setOutgoingSecrets: [[NSMutableDictionary alloc] init]];
        [self setMissingSequenceNumbers: [[NSMutableDictionary alloc] init]];
        
        MIdentity* ident = [store createIdentity];
        [ident setClaimed: YES];
        [ident setOwned: YES];
        [ident setType: kIdentityTypeEmail];
        [ident setPrincipal: me.principal];
        [ident setPrincipalHash: me.hashed];
        [ident setPrincipalShortHash: *(uint64_t*)me.hashed.bytes];
        
        [identities setObject:ident forKey:[NSNumber numberWithLongLong: ident.principalShortHash]];
        [identityLookup setObject:ident forKey:[NSArray arrayWithObjects:ident.principalHash, nil]];
        
        [self addDeviceWithName:[self deviceName] forIdentity:ident];
        
        if (blacklist != nil) {
            [self setBlacklistProvider: blacklist];
        } else {
            [self setBlacklistProvider: [[DefaultBlackListProvider alloc] init]];
        }

        if (sigController != nil) {
            [self setSignatureController: sigController];
        } else {
            [self setSignatureController: [[DefaultSignatureController alloc] init]];
        }

        if (encController != nil) {
            [self setEncryptionController: encController];
        } else {
            [self setEncryptionController: [[DefaultEncryptionController alloc] init]];
        }

    }

    return self;
}

- (IBSignatureUserKey *)signatureKeyFrom:(MIdentity *)from myIdentity:(IBEncryptionIdentity *)me {
    if (![self.signatureController hasSignatureKey:me])
        @throw [NSException exceptionWithName:kMusubiExceptionNeedSignatureUserKey reason:@"Signature key not found for identity" userInfo:nil];
    
    return [self.signatureScheme userKeyWithIdentity:me];
}

- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me {
    if (![self.encryptionController hasEncryptionKey:me])
        @throw [NSException exceptionWithName:kMusubiExceptionNeedEncryptionUserKey reason:@"Encryption key not found for identity" userInfo:nil];
    
    return [self.encryptionScheme userKeyWithIdentity:me];
}

- (uint64_t)signatureTimeFrom:(MIdentity *)from {
    IBEncryptionIdentity* ibeIdent = [[IBEncryptionIdentity alloc] initWithAuthority:from.type hashedKey:from.principalHash temporalFrame:0];
    return [self.signatureController signingTimeForIdentity:ibeIdent];
}

- (uint64_t)encryptionTimeTo:(MIdentity *)to {
    IBEncryptionIdentity* ibeIdent = [[IBEncryptionIdentity alloc] initWithAuthority:to.type hashedKey:to.principalHash temporalFrame:0];
    return [self.encryptionController encryptionTimeForIdentity:ibeIdent];
}

- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    NSArray* key = [NSArray arrayWithObjects: [NSNumber numberWithUnsignedLongLong: from.principalShortHash], [NSNumber numberWithUnsignedLongLong: to.principalShortHash], [NSNumber numberWithUnsignedLongLong: me.temporalFrame], [NSNumber numberWithUnsignedLongLong: other.temporalFrame], nil];
    
    return [outgoingSecrets objectForKey:key];
}

- (void)insertOutgoingSecret:(MOutgoingSecret *)os myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    NSArray* key = [NSArray arrayWithObjects: [NSNumber numberWithUnsignedLongLong: os.myIdentity.principalShortHash], [NSNumber numberWithUnsignedLongLong: os.otherIdentity.principalShortHash], [NSNumber numberWithUnsignedLongLong: me.temporalFrame], [NSNumber numberWithUnsignedLongLong: other.temporalFrame], nil];
    
    [outgoingSecrets setObject:os forKey:key];
}

- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice:(MDevice *)device to:(MIdentity *)to withSignature:(NSData *)signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSArray* key = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong: device.deviceName], [NSNumber numberWithUnsignedLongLong:to.principalShortHash], signature, me, nil];
    
    return [incomingSecrets objectForKey:key];
}

- (void)insertIncomingSecret:(MIncomingSecret *)is otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSArray* key = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong:is.device.deviceName], [NSNumber numberWithUnsignedLongLong:is.myIdentity.principalShortHash], is.signature, me, nil];
    
    [incomingSecrets setObject:is forKey:key];
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    MIdentity* ident = [identities objectForKey:[NSNumber numberWithUnsignedLongLong:to.principalShortHash]];
    ident.nextSequenceNumber++;
}

- (void)receivedSequenceNumber:(uint64_t)sequenceNumber from:(MDevice *)device {
    NSArray* key = [NSArray arrayWithObjects: [NSNumber numberWithUnsignedLongLong:device.identity.principalShortHash], [NSNumber numberWithUnsignedLongLong:device.deviceName], nil];
    uint64_t maxSequenceNumber = ((MDevice*)[devices objectForKey:[NSNumber numberWithUnsignedLongLong:device.deviceName]]).maxSequenceNumber;
    if (sequenceNumber > maxSequenceNumber) {
        [((MDevice*)[devices objectForKey:[NSNumber numberWithUnsignedLongLong:device.deviceName]]) setMaxSequenceNumber:sequenceNumber];
    }
   
    NSMutableSet* missing = [missingSequenceNumbers objectForKey:key];
    if (missing != nil)
        [missing removeObject: [NSNumber numberWithUnsignedLongLong: sequenceNumber]];
    
    if (sequenceNumber > maxSequenceNumber + 1) {
        if (missing == nil) {
            missing = [[NSMutableSet alloc] init];
            [missingSequenceNumbers setObject:missing forKey:key];
        }
        for (uint64_t q = maxSequenceNumber + 1; q < sequenceNumber; ++q) {
            [missing addObject: [NSNumber numberWithUnsignedLongLong: q]];
        }
    }
}

- (BOOL)haveHash:(NSData*)hash {
    MEncodedMessage* encoded = [encodedMessageLookup objectForKey:hash];
    return (encoded != nil);
}

- (void)storeSequenceNumbers:(NSDictionary *)seqNumbers forEncodedMessage:(MEncodedMessage *)encoded {
    /*
    sequence_numbers.forEachEntry(new TLongLongProcedure() {
        public boolean execute(long identityId, long sequenceNumber) {
            encodedMessageForPersonBySequenceNumber.put(Pair.with(identityId, sequenceNumber), encoded.id_);
            return true;
        }
    });
    */
}

- (BOOL)isBlackListed:(MIdentity *)ident {
    return [blacklistProvider isBlackListed:[[IBEncryptionIdentity alloc] initWithAuthority:ident.type hashedKey:ident.principalHash temporalFrame:0]];
}

- (BOOL)isMe:(IBEncryptionIdentity *)ident {
    return [ident equalsStable: myIdentity];  
}

- (MIdentity *)addClaimedIdentity:(IBEncryptionIdentity *)hid {
    NSArray* lookupKey = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedChar: [hid authority]], [hid hashed], nil];
    
    MIdentity* ident = [identityLookup objectForKey:lookupKey];
    if (ident != nil)
        return ident;
    
    ident = [store createIdentity];
    [ident setClaimed: YES];
    [ident setOwned: NO];
    [ident setType: kIdentityTypeEmail];
    [ident setPrincipalHash: [hid hashed]];
    [ident setPrincipalShortHash: *(uint64_t*)hid.hashed.bytes];
    
    [identities setObject:ident forKey:[NSNumber numberWithUnsignedLongLong: ident.principalShortHash]];
    [identityLookup setObject:ident forKey:lookupKey];
    return ident;
}

- (MIdentity *)addUnclaimedIdentity:(IBEncryptionIdentity *)hid {
    NSArray* lookupKey = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedChar: [hid authority]], [hid hashed], nil];
    
    MIdentity* ident = [identityLookup objectForKey:lookupKey];
    if (ident != nil)
        return ident;
    
    ident = [store createIdentity];
    [ident setClaimed: NO];
    [ident setOwned: NO];
    [ident setType: kIdentityTypeEmail];
    [ident setPrincipalHash: [hid hashed]];
    [ident setPrincipalShortHash: *(uint64_t*)hid.hashed.bytes];
    
    [identities setObject:ident forKey:[NSNumber numberWithUnsignedLongLong: ident.principalShortHash]];
    [identityLookup setObject:ident forKey:lookupKey];
    return ident;
}

- (MDevice *)addDeviceWithName:(uint64_t)devName forIdentity:(MIdentity *)ident {
    NSArray* lookupKey = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedLongLong: ident.principalShortHash], [NSNumber numberWithUnsignedLongLong:devName], nil];

    MDevice* d = [deviceLookup objectForKey:lookupKey];
    if(d != nil)
        return d;
    
    d = [store createDevice];
    [d setIdentity: ident];
    [d setDeviceName: devName];
    [d setMaxSequenceNumber: -1];
    
    [devices setObject:d forKey:[NSNumber numberWithUnsignedLongLong: d.deviceName]];
    [deviceLookup setObject:d forKey:lookupKey];
    
    return d;
}

- (void)updateEncodedMetadata:(MEncodedMessage *)encoded {
    [encodedMessageLookup setObject:encoded forKey:[encoded.encoded sha256Digest]];
}

- (void)insertEncodedMessage:(MEncodedMessage *)encoded forOutgoingMessage:(OutgoingMessage *)om {
    
    NSLog(@"Inserting message with message hash:\n%@\nand hash:\n%@", [encoded messageHash], [encoded.encoded sha256Digest]);

    [encodedMessages setObject:encoded forKey:encoded.messageHash];
    [encodedMessageLookup setObject:encoded forKey:[encoded.encoded sha256Digest]];
}

- (MEncodedMessage *)insertEncodedMessageData:(NSData *)data {
    MEncodedMessage* encodedMessage = [store createEncodedMessage];
    [encodedMessage setEncoded: data];
    [encodedMessages setObject:encodedMessage forKey:[NSNumber numberWithInt:encodedMessage.hash]];
    return encodedMessage;
}
@end
