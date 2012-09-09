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

@class MIdentity, MDevice;

@interface IncomingMessage : NSObject {
    NSArray* personas; // the identities used by me to decode or encode messages
    MIdentity* fromIdentity;  // the reference to the identity that sent the message, could be me
    MDevice* fromDevice; // the device that sent the message
    NSArray* recipients; // a list of all of the recipients, some of which I may or may not really know
    NSData* hash; // the hash of the data which was validated
    NSData* data; // the actual private message bytes that are decrypted
    uint64_t sequenceNumber; // the sequence number of the message from this device
    BOOL blind; // whether or not this was state update, e.g. blind cc
    NSData* app; // application namespace
}

@property (nonatomic) NSArray* personas;
@property (nonatomic) MIdentity* fromIdentity;
@property (nonatomic) MDevice* fromDevice;
@property (nonatomic) NSArray* recipients;
@property (nonatomic) NSData* hash;
@property (nonatomic) NSData* data;
@property (nonatomic,assign) uint64_t sequenceNumber;
@property (nonatomic,assign) BOOL blind;
@property (nonatomic) NSData* app;

@end
