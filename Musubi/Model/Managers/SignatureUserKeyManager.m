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


#import "SignatureUserKeyManager.h"
#import "Musubi.h"
#import "IBEncryptionScheme.h"
#import "PersistentModelStore.h"
#import "MSignatureUserKey.h"

@implementation SignatureUserKeyManager

@synthesize signatureScheme;

- (id)initWithStore:(PersistentModelStore *)s signatureScheme:(IBSignatureScheme *)ss {
    self = [super initWithEntityName:@"SignatureUserKey" andStore:s];
    
    if (self != nil) {
        [self setSignatureScheme: ss];
    }
    
    return self;
}

- (void)createSignatureUserKey:(MSignatureUserKey *)signatureKey {
    [store save];
}

- (IBSignatureUserKey *)signatureKeyFrom:(MIdentity *)from me:(IBEncryptionIdentity *)me {
    MSignatureUserKey* key = (MSignatureUserKey*)[self queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %llu", from, me.temporalFrame]];
    if (key != nil) {
        return [[IBSignatureUserKey alloc] initWithRaw: key.key];
    }
    
    @throw [NSException exceptionWithName:kMusubiExceptionNeedSignatureUserKey reason:@"Don't have signature key" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:me, @"identity", nil]];
}

- (void)updateSignatureUserKey:(MSignatureUserKey *)signatureKey {
    [store save];
}

@end
