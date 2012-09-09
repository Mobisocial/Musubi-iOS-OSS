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

@class MIdentity;

@interface OutgoingMessage : NSObject {
    MIdentity* fromIdentity; // the reference to the identity that i send the message as
    NSArray* recipients; // a list of all of the recipients, some of which I may or may not really know, it probably includes me
    NSData* data; // the actual private message bytes that are decrypted
    NSData* hash; // the hash of data
    BOOL blind; // a flag that control whether client should see the full recipient list
    NSData* app; // the id of the application namespace
}

@property (nonatomic) MIdentity* fromIdentity;
@property (nonatomic) NSArray* recipients;
@property (nonatomic) NSData* data;
@property (nonatomic) NSData* hash;
@property (nonatomic, assign) BOOL blind;
@property (nonatomic) NSData* app;

@end
