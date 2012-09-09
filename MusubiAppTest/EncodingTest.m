//
//  EncodingTest.m
//  Musubi
//
//  Created by Willem Bult on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncodingTest.h"
#import "IBEncryptionScheme.h"
#import "MEncodedMessage.h"
#import "BSONEncoder.h"
#import "Recipient.h"
#import "TransientTransportDataProvider.h"
#import "MessageEncoder.h"
#import "MessageDecoder.h"
#import "OutgoingMessage.h"
#import "IncomingMessage.h"
#import "NSData+Crypto.h"
#import "Musubi.h"
#import <stdlib.h>

@implementation EncodingTestBlacklistProvider
@synthesize blacklist;

- (id)initWithBlacklist:(NSArray *)list {
    self = [super init];
    if (self != nil) {
        [self setBlacklist: list];
    }
    return self;
}

- (BOOL)isBlackListed:(IBEncryptionIdentity *)identity {
    for (IBEncryptionIdentity* i in blacklist) {
        if ([i equals:identity]) {
            return YES;
        }
    }
    
    return NO;
}

@end

@implementation EncodingTestSignatureController

- (BOOL)hasSignatureKey:(IBEncryptionIdentity *)hid {
    return hid.temporalFrame == 0;
}

- (uint64_t)signingTimeForIdentity:(IBEncryptionIdentity *)hid {
    return t++;
}

@end

@implementation EncodingTestEncryptionController

- (BOOL)hasEncryptionKey:(IBEncryptionIdentity *)hid {
    return hid.temporalFrame == 0;
}

- (uint64_t)encryptionTimeForIdentity:(IBEncryptionIdentity *)hid {
    return t++; 
}

@end

@implementation EncodingTest

- (void)testBSONEncodeDecodeSecret
{
    Secret* s = [[Secret alloc] init];
    [s setH:[@"hash" dataUsingEncoding:NSUTF8StringEncoding]];
    [s setQ:1234];
    [s setK:[@"key" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* bson = [BSONEncoder encodeSecret: s];
    STAssertNotNil(bson, @"BSON should not be nil");
    
    Secret* s2 = [BSONEncoder decodeSecret:bson];
    
    STAssertTrue([s.h isEqualToData: s2.h], @"Secret H don't match");
    STAssertTrue(s.q == s2.q, @"Secret Q don't match");
    STAssertTrue([s.k isEqualToData: s2.k], @"Secret K don't match");
}

- (void)testBSONEncodeDecodeMessage
{
    Recipient* r1 = [[Recipient alloc] init];
    [r1 setI: [@"serialized hashed identity 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [r1 setK: [@"encrypted key block 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [r1 setS: [@"signature block 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [r1 setD: [@"encrypted secrets 1" dataUsingEncoding:NSUTF8StringEncoding]];
    
    Recipient* r2 = [[Recipient alloc] init];
    [r2 setI: [@"serialized hashed identity 2" dataUsingEncoding:NSUTF8StringEncoding]];
    [r2 setK: [@"encrypted key block 2" dataUsingEncoding:NSUTF8StringEncoding]];
    [r2 setS: [@"signature block 2" dataUsingEncoding:NSUTF8StringEncoding]];
    [r2 setD: [@"encrypted secrets 2" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:2];
    [r addObject:r1];
    [r addObject:r2];
    
    Sender* s = [[Sender alloc] init];
    [s setI: [@"serialized hashed identity" dataUsingEncoding:NSUTF8StringEncoding]];
    [s setD: [@"device identifier" dataUsingEncoding:NSUTF8StringEncoding]];
    
    Message* m = [[Message alloc] init];
    [m setV: 3];
    [m setS: s];
    [m setI: [@"init vector" dataUsingEncoding:NSUTF8StringEncoding]];
    [m setL: YES];
    [m setA: [@"app" dataUsingEncoding:NSUTF8StringEncoding]];
    [m setR: r];
    [m setD: [@"encrypted data" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* bson = [BSONEncoder encodeMessage:m];
    STAssertNotNil(bson, @"BSON should not be nil");
    
    Message* m2 = [BSONEncoder decodeMessage:bson];
    
    STAssertTrue(m.v == m2.v, @"Version doesn't match");
    STAssertTrue([m.s.i isEqualToData: m2.s.i], @"Sender identity doesn't match");
    STAssertTrue([m.s.d isEqualToData: m2.s.d], @"Sender device doesn't match");
    STAssertTrue([m.i isEqualToData: m2.i], @"Init vector doesn't match");
    STAssertTrue(m.l == m2.l, @"Blind doesn't match");
    STAssertTrue([m.a isEqualToData: m2.a], @"App doesn't match");
    STAssertTrue([m.r count] == [m2.r count], @"Number of recipients doesn't match");
    for (int i=0; i<[m.r count]; i++) {
        Recipient* r = [m.r objectAtIndex:i];
        Recipient* r2 = [m2.r objectAtIndex:i];
        
        STAssertTrue([r.i isEqualToData: r2.i], @"Recipient identity doesn't match");       
        STAssertTrue([r.k isEqualToData: r2.k], @"Recipient key block doesn't match");       
        STAssertTrue([r.s isEqualToData: r2.s], @"Recipient signature block doesn't match");       
        STAssertTrue([r.d isEqualToData: r2.d], @"Recipient secrets don't match");       
    }
    STAssertTrue([m.d isEqualToData: m2.d], @"Encrypted data doesn't match");
    
}

- (void) testSelfMessageAcrossDevices 
{
    IBEncryptionIdentity* me = [self randomIdentity];
    
    STAssertTrue([[me hashed] length] == 32, @"Hash is not 32 bytes");
    STAssertTrue([[me key] length] == 32 + 1 + 8, @"Key is of wrong length");
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    
    TransientTransportDataProvider* tdpDev0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpDev1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpDev0];
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpDev1];

    // Encode a message
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpDev0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: om.fromIdentity]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];
    
    // Pop the message into the transient provider for device 1
    MEncodedMessage* encodedIncoming = [tdpDev1 insertEncodedMessageData:[encodedOutgoing encoded]];
    IncomingMessage* im = [decoder decodeMessage: encodedIncoming];
    [self assertMessage:om isEqualTo:im];
}


- (void) testMessageBetweenFriends {
    IBEncryptionIdentity* me = [self randomIdentity];
    IBEncryptionIdentity* you = [self randomIdentity];

    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpUser0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpUser1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:you blacklistProvicer:nil signatureController:nil encryptionController:nil];

    
    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpUser0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpUser0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: [tdpUser0 addClaimedIdentity:you]]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];


    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpUser1];
    MEncodedMessage* encodedIncoming = [tdpUser1 insertEncodedMessageData:[encodedOutgoing encoded]];
    IncomingMessage* im = [decoder decodeMessage: encodedIncoming];
    [self assertMessage:om isEqualTo:im];

}


- (void) testBroadcastMessageBetweenFriends {
    IBEncryptionIdentity* me = [self randomIdentity];
    IBEncryptionIdentity* you = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpUser0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpUser1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:you blacklistProvicer:nil signatureController:nil encryptionController:nil];

    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpUser0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpUser0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: [tdpUser0 addClaimedIdentity:you]]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    //this changes the signature, computation, so we use this 
    //test to verify that it works right
    [om setBlind: YES];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];
    
    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpUser1];
    MEncodedMessage* encodedIncoming = [tdpUser1 insertEncodedMessageData:[encodedOutgoing encoded]];
    IncomingMessage* im = [decoder decodeMessage: encodedIncoming];
    [self assertMessage:om isEqualTo:im];
}

- (void) testSelfMessageDetectedAsDuplicate {
    IBEncryptionIdentity* me = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdp = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdp];
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdp];
    
    // Encode a message
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdp addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: om.fromIdentity]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];
    
    // Pop the message into the transient provider for device 1
    MEncodedMessage* encodedIncoming = [tdp insertEncodedMessageData:[encodedOutgoing encoded]];
    @try {
        [decoder decodeMessage: encodedIncoming];
        STFail(@"Message should have been detected as duplicate");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionDuplicateMessage]) {
            @throw exception;
        }
    }
}

- (void) testMessageMisrouted {
    IBEncryptionIdentity* me = [self randomIdentity];
    IBEncryptionIdentity* you = [self randomIdentity];
    IBEncryptionIdentity* bob = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpUser0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpUser1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:you blacklistProvicer:nil signatureController:nil encryptionController:nil];
    
    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpUser0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpUser0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: [tdpUser0 addClaimedIdentity:bob]]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];

    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpUser1];
    MEncodedMessage* encodedIncoming = [tdpUser1 insertEncodedMessageData:[encodedOutgoing encoded]];
    @try {
        [decoder decodeMessage: encodedIncoming];
        STFail(@"Message should have been detected as misrouted");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionRecipientMismatch]) {
            @throw exception;
        }
    }
}

- (void) testMessageBlacklisted {
    IBEncryptionIdentity* me = [self randomIdentity];
    IBEncryptionIdentity* you = [self randomIdentity];

    EncodingTestBlacklistProvider* blacklist = [[EncodingTestBlacklistProvider alloc] initWithBlacklist:[NSArray arrayWithObject:me]];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpUser0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpUser1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:you blacklistProvicer:blacklist signatureController:nil encryptionController:nil];
    
    
    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpUser0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpUser0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: [tdpUser0 addClaimedIdentity:you]]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];
    
    
    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpUser1];
    MEncodedMessage* encodedIncoming = [tdpUser1 insertEncodedMessageData:[encodedOutgoing encoded]];
    @try {
        [decoder decodeMessage: encodedIncoming];
        STFail(@"Message should have failed because of blacklist");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionSenderBlacklisted]) {
            @throw exception;
        }
    }
}

- (void) testMessingSigningKey {
    EncodingTestSignatureController* sigController = [[EncodingTestSignatureController alloc] init];
    
    IBEncryptionIdentity* me = [self randomIdentity];
    IBEncryptionIdentity* you = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpUser0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:sigController encryptionController:nil];
    
    
    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpUser0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpUser0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: [tdpUser0 addClaimedIdentity:you]]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];

    @try {
        encodedOutgoing = [encoder encodeOutgoingMessage:om];
        STFail(@"Encoding should have failed because of missing key");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionNeedSignatureUserKey]) {
            @throw exception;
        }
    }
}

- (void) testMissingEncryptionKey {
    EncodingTestEncryptionController* encController = [[EncodingTestEncryptionController alloc] init];

    IBEncryptionIdentity* me = [self randomIdentity];
    IBEncryptionIdentity* you = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpUser0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:encController];
    TransientTransportDataProvider* tdpUser1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:you blacklistProvicer:nil signatureController:nil encryptionController:encController];
    
    
    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpUser0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpUser0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: [tdpUser0 addClaimedIdentity:you]]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];
    MEncodedMessage* encodedOutgoingUnreadable = [encoder encodeOutgoingMessage:om];
    
    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpUser1];
    MEncodedMessage* encodedIncoming = [tdpUser1 insertEncodedMessageData:[encodedOutgoing encoded]];
    [decoder decodeMessage: encodedIncoming];

    encodedIncoming = [tdpUser1 insertEncodedMessageData:[encodedOutgoingUnreadable encoded]];
    @try {
        [decoder decodeMessage: encodedIncoming];
        STFail(@"Message should have needed a different encryption key");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionNeedEncryptionUserKey]) {
            @throw exception;
        }
    }

}

- (void) testCorruptedPacket {
    IBEncryptionIdentity* me = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpDev0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpDev1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];

    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpDev0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpDev0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: om.fromIdentity]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];
    
    for (int i=0; i<encodedOutgoing.encoded.length; i++) {
        ((char*)[encodedOutgoing.encoded bytes])[i] += 37;
    }

    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpDev1];
    MEncodedMessage* encodedIncoming = [tdpDev1 insertEncodedMessageData:[encodedOutgoing encoded]];
    @try {
        [decoder decodeMessage: encodedIncoming];
        STFail(@"Message should have been detected as corrupted");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionMessageCorrupted]) {
            @throw exception;
        }
    }
}

- (void) testCorruptedBody {
    IBEncryptionIdentity* me = [self randomIdentity];
    
    IBEncryptionScheme* encryptionScheme = [[IBEncryptionScheme alloc] init];
    IBSignatureScheme* signatureScheme = [[IBSignatureScheme alloc] init];
    
    TransientTransportDataProvider* tdpDev0 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    TransientTransportDataProvider* tdpDev1 = [[TransientTransportDataProvider alloc] initWithEncryptionScheme:encryptionScheme signatureScheme:signatureScheme identity:me blacklistProvicer:nil signatureController:nil encryptionController:nil];
    
    // Encode a message
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:tdpDev0];
    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setFromIdentity: [tdpDev0 addClaimedIdentity:me]];
    [om setRecipients: [NSArray arrayWithObject: om.fromIdentity]];
    [om setData: [NSData generateSecureRandomKeyOf:16]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setHash: [[om data] sha256Digest]];
    
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage:om];

    // Manipulate message body
    ((char*)[[encodedOutgoing encoded] bytes])[encodedOutgoing.encoded.length - 17] += 37;
    
    // Pop the message into the transient provider for user 1
    MessageDecoder* decoder = [[MessageDecoder alloc] initWithTransportDataProvider:tdpDev1];
    MEncodedMessage* encodedIncoming = [tdpDev1 insertEncodedMessageData:[encodedOutgoing encoded]];
    @try {
        [decoder decodeMessage: encodedIncoming];
        STFail(@"Message should have been detected having bad signature");
    }
    @catch (NSException *exception) {
        if (![[exception name] isEqualToString:kMusubiExceptionBadSignature]) {
            @throw exception;
        }
    }
}
@end
