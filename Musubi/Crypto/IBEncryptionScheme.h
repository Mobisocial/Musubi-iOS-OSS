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
#import "NSData+Crypto.m"

@interface IBEncryptionKey : NSObject
@property (nonatomic, strong) NSData* raw;
@end

@interface IBEncryptionMasterKey : IBEncryptionKey

@end

@interface IBEncryptionUserKey : IBEncryptionKey
- (id)initWithRaw:(NSData *)r;
@end

@interface IBSignatureUserKey : IBEncryptionKey
- (id)initWithRaw:(NSData *)r;
@end

@interface IBEncryptionConversationKey : IBEncryptionKey
@property (nonatomic, strong) NSData* encrypted;

- (id) initWithRaw:(NSData*)r andEncrypted:(NSData*) e;

@end

@interface IBEncryptionIdentity : NSObject
@property (nonatomic, strong) NSString* principal;
@property (nonatomic, strong) NSData* key;
@property (nonatomic, strong) NSData* hashed;
@property (nonatomic, assign) uint8_t authority;
@property (nonatomic, assign) uint64_t temporalFrame;

- (id) initWithAuthority:(uint8_t)a hashedKey:(NSData*) h temporalFrame: (uint64_t) tf;
- (id) initWithAuthority:(uint8_t)a principal:(NSString*) p temporalFrame: (uint64_t)tf;
- (id) initWithKey: (NSData*) key;
- (IBEncryptionIdentity*) keyAtTemporalFrame: (uint64_t) tf;
- (BOOL) equals: (IBEncryptionIdentity*) other;
- (BOOL) equalsStable: (IBEncryptionIdentity*) other;
@end

@interface IBEncryptionScheme : NSObject
- (IBEncryptionUserKey*) userKeyWithIdentity: (IBEncryptionIdentity*) identity;
- (IBEncryptionConversationKey*) randomConversationKeyWithIdentity: (IBEncryptionIdentity*) identity;
- (NSData*) encryptKey:(NSMutableData *)key withIdentity:(IBEncryptionIdentity *)identity;
- (NSData*) decryptKey:(NSData*) ek withUserKey:(IBEncryptionUserKey*) uk;
- (NSData*) decryptConversationKey:(IBEncryptionConversationKey*) ck withUserKey: (IBEncryptionUserKey*) uk;
@end



@interface IBSignatureScheme : NSObject
- (IBSignatureUserKey*) userKeyWithIdentity: (IBEncryptionIdentity*) identity;
- (NSData*) signHash:(NSData*)hash withUserKey:(IBSignatureUserKey*) uk andIdentity:(IBEncryptionIdentity*) identity;
- (BOOL) verifySignature:(NSData*)sig forHash:(NSData*)hash withIdentity:(IBEncryptionIdentity*)identity;

@end
