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


#import "IBEncryptionScheme.h"

@implementation IBEncryptionKey

@synthesize raw;

- (id)initWithRaw:(NSData *)r {
    self = [super init];
    if (self != nil) {
        [self setRaw: r];
    }
    return self;
}

@end

@implementation IBEncryptionMasterKey

@end

@implementation IBEncryptionConversationKey

@synthesize encrypted;

- (id)initWithRaw:(NSData *)r andEncrypted:(NSData *)e {
    self = [super initWithRaw:r];
    if (self != nil) {
        [self setEncrypted: e];
    }
    return self;
}
@end

@implementation IBEncryptionUserKey
- (id)initWithRaw:(NSData *)r {
    return [super initWithRaw:r];
}

@end

@implementation IBSignatureUserKey
- (id)initWithRaw:(NSData *)r {
    return [super initWithRaw:r];
}

@end

@implementation IBEncryptionIdentity

@synthesize key, principal, hashed, authority, temporalFrame;

- (id)initWithAuthority:(uint8_t)a principal:(NSString *)p temporalFrame:(uint64_t)tf {
    NSData* hash = [[[p lowercaseString] dataUsingEncoding:NSUTF8StringEncoding] sha256Digest];
    
    self = [self initWithAuthority:a hashedKey:hash temporalFrame:tf];
    if (self != nil) {
        [self setPrincipal: p];
    }
    return self;
}

- (id)initWithAuthority:(uint8_t)a hashedKey:(NSData *)h temporalFrame:(uint64_t)tf {
    self = [super init];
    if (self != nil) {
        [self setAuthority:a];
        [self setHashed:h];
        [self setTemporalFrame:tf];
        
        uint8_t a8bit = (uint8_t)a;
        uint64_t tfBigEndian = CFSwapInt64HostToBig(tf);
        
        NSMutableData* k = [NSMutableData data];
        [k appendBytes:&a8bit length:1];
        [k appendData:h];
        [k appendBytes:&tfBigEndian length: sizeof(tfBigEndian)];
        
        [self setKey:k];
    }
    return self;
}

- (id)initWithKey:(NSData *)k {
    self = [super init];
    if (self != nil) {
        [self setKey: k];
        
        [self setAuthority:*(uint8_t*)[key bytes]];
        [self setHashed: [NSData dataWithBytes: [key bytes]+sizeof(uint8_t) length:32]];
        [self setTemporalFrame:CFSwapInt64BigToHost(*(uint64_t*)([key bytes]+sizeof(uint8_t)+32))];
    }
    
    return self;
}

- (IBEncryptionIdentity *)keyAtTemporalFrame:(uint64_t)tf {
    if (principal) {
        return [[IBEncryptionIdentity alloc] initWithAuthority:authority principal:principal temporalFrame:tf];
    } else {
        return [[IBEncryptionIdentity alloc] initWithAuthority:authority hashedKey:hashed temporalFrame:tf];
    }
}

- (BOOL) equals: (IBEncryptionIdentity*) other {
    return [self equalsStable: other] && temporalFrame == other.temporalFrame;
}

- (BOOL) equalsStable:(IBEncryptionIdentity *)other {
    return authority == other.authority && [hashed isEqualToData:other.hashed];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<IBEIdentity: %d, %@, %@, %llu>", authority, principal, hashed, temporalFrame];
}

- (BOOL) isEqual:(id)object
{
    if(![object isKindOfClass:[IBEncryptionIdentity class]])
        return NO;
    return [self equals:object];
}
- (NSUInteger)hash
{
    return [self.key hash];
}

@end

@implementation IBEncryptionScheme


- (IBEncryptionUserKey *) userKeyWithIdentity:(IBEncryptionIdentity *)identity {
    return [IBEncryptionUserKey alloc];
}

- (NSData *)encryptKey:(NSMutableData *)key withIdentity:(IBEncryptionIdentity *)identity {
    return [NSData data];
}

- (NSData*)decryptKey:(NSData*)ek withUserKey: (IBEncryptionUserKey*)uk {
    return [NSData data];
}

- (NSData *)decryptConversationKey:(IBEncryptionConversationKey *)ck withUserKey:(IBEncryptionUserKey *)uk {
    return ck.encrypted;
}

- (IBEncryptionConversationKey *)randomConversationKeyWithIdentity:(IBEncryptionIdentity *)identity {
    NSData* key = [NSData generateSecureRandomKeyOf:32];
    return [[IBEncryptionConversationKey alloc] initWithRaw:key andEncrypted:key];
}

@end
 
@implementation IBSignatureScheme
- (IBSignatureUserKey *)userKeyWithIdentity:(IBEncryptionIdentity *)identity {
    return [NSData data];
}

- (NSData*) signHash:(NSData*)hash withUserKey:(IBSignatureUserKey*) uk andIdentity:(IBEncryptionIdentity*) identity {
    return [NSData data];
}

- (BOOL) verifySignature:(NSData*)sig forHash:(NSData*)hash withIdentity:(IBEncryptionIdentity*)identity {
    return YES;
}

@end
