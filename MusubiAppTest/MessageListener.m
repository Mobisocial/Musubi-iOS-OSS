//
//  MessageListener.m
//  Musubi
//
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageListener.h"
#import "SignatureUserKeyManager.h"
#import "EncryptionUserKeyManager.h"
#import "EncodedMessageManager.h"

@implementation MessageListener

@synthesize identityProvider, identity, transportManager, transport;

- (id)initWithIdentityProvider:(UnverifiedIdentityProvider *)ip andIdentity:(IBEncryptionIdentity *)i {
    NSAssert(i.principal != nil);
    self = [super init];
    if (self != nil) {
        [self setIdentityProvider: ip];
        [self setIdentity: i];
        
        // Create a new store factory
        [PersistentModelStoreFactory deleteStoreWithName:@"TestStore2"];
        PersistentModelStoreFactory* factory = [[PersistentModelStoreFactory alloc] initWithName:@"TestStore2"];

        transportManager = [[TransportManager alloc] initWithStore:[factory newStore] encryptionScheme:ip.encryptionScheme signatureScheme:ip.signatureScheme deviceName:random()];
        
        
        // Store our identity, device and signature key
        
        MIdentity* mIdent0 = [transportManager addClaimedIdentity: identity];
        [mIdent0 setOwned:YES];
        [mIdent0 setPrincipal: [i principal]];
        
        //MDevice* dev = [store newDevice];
        //[dev setDeviceName:transport.deviceName];
        
        IBEncryptionIdentity* requiredKey = [i keyAtTemporalFrame: [transportManager signatureTimeFrom:mIdent0]];
        MSignatureUserKey* sigKey = (MSignatureUserKey*)[transportManager.store createEntity: @"SignatureUserKey"];
        [sigKey setIdentity: mIdent0];
        [sigKey setKey: [identityProvider signatureKeyForIdentity:requiredKey].raw];
        [sigKey setPeriod: requiredKey.temporalFrame];
        [transportManager.store save];

        // Start the transport
        [self setTransport: [[AMQPTransport alloc] initWithStoreFactory:factory]];
        [self.transport start];
    }
    return self;
}

- (MEncodedMessage*) waitForMessage:(int)seq during:(NSTimeInterval)interval {
    EncodedMessageManager* emm = [[EncodedMessageManager alloc] initWithStore:[transportManager store]];
    NSDate* start = [NSDate date];
    
    while ([[NSDate date] timeIntervalSinceDate:start] < interval) {
        NSArray* res = [emm query:nil];
        if (res != nil && res.count > seq) {
            return [res objectAtIndex: seq];
        }
        [NSThread sleepForTimeInterval:1];
    }
    return nil;
}

- (void) stop {
    [transport stop];
}
@end
