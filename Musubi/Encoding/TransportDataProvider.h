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

@class IBEncryptionScheme, IBSignatureScheme, IBEncryptionUserKey, IBSignatureUserKey, IBEncryptionIdentity;
@class PersistentModelStore, MIdentity, MOutgoingSecret, MIncomingSecret, MDevice, MEncodedMessage, OutgoingMessage;

@protocol TransportDataProvider

- (PersistentModelStore*) store;

/* IBE secrets */
- (IBEncryptionScheme*) encryptionScheme;
- (IBSignatureScheme*) signatureScheme;

- (IBSignatureUserKey*) signatureKeyFrom:(MIdentity *)from myIdentity: (IBEncryptionIdentity*) me;
- (IBEncryptionUserKey*) encryptionKeyTo:(MIdentity *)to myIdentity: (IBEncryptionIdentity*) me;

/* Compute times given an identity, might consult for revocation etc */
- (uint64_t) signatureTimeFrom: (MIdentity*) from;
- (uint64_t) encryptionTimeTo: (MIdentity*) to;

/* My one and only */
- (uint64_t) deviceName;

/* Channel secret management */
- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other;
- (void) insertOutgoingSecret: (MOutgoingSecret*) os myIdentity:(IBEncryptionIdentity*)me otherIdentity: (IBEncryptionIdentity*) other;
- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice: (MDevice*) device to:(MIdentity *)to withSignature: (NSData*) signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me;
- (void) insertIncomingSecret: (MIncomingSecret*) is otherIdentity: (IBEncryptionIdentity*) other myIdentity: (IBEncryptionIdentity*) me;

/* Sequence number manipulation */
- (void) incrementSequenceNumberTo: (MIdentity*) to;
- (void) receivedSequenceNumber: (uint64_t) sequenceNumber from: (MDevice*) device;
- (BOOL) haveHash: (NSData*) hash;
//- (NSData*) hashForSequenceNumber: (long) sequenceNumber from: (MDevice*) device;
- (void) storeSequenceNumbers: (NSDictionary*) seqNumbers forEncodedMessage: (MEncodedMessage*) encoded;

/* Misc identity info queries */
- (BOOL) isBlackListed: (MIdentity*) ident;
- (BOOL) isMe: (IBEncryptionIdentity*) ident;
- (MIdentity*) addClaimedIdentity: (IBEncryptionIdentity*) ident;
- (MIdentity*) addUnclaimedIdentity: (IBEncryptionIdentity*) ident;
- (MDevice *) addDeviceWithName: (uint64_t) deviceName forIdentity: (MIdentity *)ident;

/* Final message handled */
- (void) updateEncodedMetadata: (MEncodedMessage*) encoded;
- (void) insertEncodedMessage: (MEncodedMessage*) encoded forOutgoingMessage: (OutgoingMessage*) om;



@end
