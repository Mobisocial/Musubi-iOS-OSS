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


#import "EncryptionUserKeyManager.h"
#import "Musubi.h"

#import "IBEncryptionScheme.h"
#import "MIdentity.h"
#import "MEncryptionUserKey.h"

@implementation EncryptionUserKeyManager

@synthesize encryptionScheme;

- (id)initWithStore:(PersistentModelStore *)s encryptionScheme:(IBEncryptionScheme *)es {
    self = [super initWithEntityName:@"EncryptionUserKey" andStore:s];
    
    if (self != nil) {
        [self setEncryptionScheme: es];
    }
    
    return self;
}


- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to me:(IBEncryptionIdentity *)me {
    MEncryptionUserKey* key = (MEncryptionUserKey*)[self queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %llu", to, me.temporalFrame]];
    if (key != nil) {
        return [[IBEncryptionUserKey alloc] initWithRaw: key.key];
    }
    
    @throw [NSException exceptionWithName:kMusubiExceptionNeedEncryptionUserKey reason:@"Don't have encryption key" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:me, @"identity", nil]];
}

@end
