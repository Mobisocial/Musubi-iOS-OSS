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


#import "IdentityKeyManager.h"
#import "IdentityManager.h"
#import "IdentityProvider.h"
#import "AphidIdentityProvider.h"
#import "Musubi.h"
#import "EncryptionUserKeyManager.h"
#import "SignatureUserKeyManager.h"
#import "MIdentity.h"
#import "MEncryptionUserKey.h"
#import "MSignatureUserKey.h"
#import "IBEncryptionScheme.h"
#import "PersistentModelStore.h"
#import "Authorities.h"

static long kMinimumBackoff = 10 * 1000;
static long kMaximumBackoff = 30 * 60 * 1000;

/*
 * Gets keys from the Aphid key server and refreshes them when expired
 */

@implementation IdentityKeyManager

@synthesize requestedEncryptionKeys, requestedSignatureKeys, encryptionBackoff, signatureBackoff, identityProvider;

- (id)initWithIdentityProvider:(id<IdentityProvider>)idp {
    self = [super init];
    if (self != nil) {
        [self setIdentityProvider: idp];
        
        [self setRequestedEncryptionKeys: [NSMutableArray array]];
        [self setRequestedSignatureKeys: [NSMutableArray array]];
        [self setEncryptionBackoff: [NSMutableDictionary dictionary]];
        [self setSignatureBackoff: [NSMutableDictionary dictionary]];
        
        // Handle new auth tokens
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(refreshKeys) name:kMusubiNotificationAuthTokenRefresh object:nil];
    }
    return self;
}

- (void) refreshKeys {
    NSLog(@"Refreshing keys");
    NSOperation* op = [[IdentityKeyRefreshOperation alloc] initWithManager:self];
    [[NSOperationQueue new] addOperation:op];
}

- (long) updateBackoffForIdentity: (IBEncryptionIdentity*) hid inMap: (NSMutableDictionary*) map {

    long backoff = kMinimumBackoff;
    if ([[map allKeys] containsObject: hid]) {
        backoff = [((NSNumber*)[map objectForKey:hid]) longValue] * 2;
        backoff = backoff > kMaximumBackoff ? kMaximumBackoff : backoff;
        [map setObject:[NSNumber numberWithLong:backoff] forKey:hid];
    }
    
    return backoff;
}

@end

@implementation IdentityKeyRefreshOperation

@synthesize manager, identityManager, store, encryptionUserKeyManager, signatureUserKeyManager;

- (id)initWithManager:(IdentityKeyManager *)m {
    self = [super init];
    if (self) {
        [self setManager: m];
    }
    return self;
}

- (void) main {
    [self setStore: [Musubi.sharedInstance newStore]];
    [self setIdentityManager: [[IdentityManager alloc] initWithStore: store]];
    
    [self setEncryptionUserKeyManager: [[EncryptionUserKeyManager alloc] initWithStore:store encryptionScheme:[manager.identityProvider encryptionScheme]]];
    [self setSignatureUserKeyManager: [[SignatureUserKeyManager alloc] initWithStore:store signatureScheme:[manager.identityProvider signatureScheme]]];

    NSMutableSet* idsToUpdate = [NSMutableSet set];
    
    for (MIdentity* mId in [identityManager ownedIdentities]) {
        IBEncryptionIdentity* ibeId = [identityManager ibEncryptionIdentityForIdentity:mId forTemporalFrame:[identityManager computeTemporalFrameFromPrincipal: mId.principal]];
        [idsToUpdate addObject:ibeId];
        
        NSLog(@"IdentityKeyManager: Updating key for identity: %@", mId.principal);
    }
    
    for (IBEncryptionIdentity* ident in idsToUpdate) {
        MIdentity* mId = [identityManager identityForIBEncryptionIdentity:ident];
        
        assert(mId != nil);
        
        // Local identities can't be refreshed
        if (mId.type == kIdentityTypeLocal) {
            continue;
        }
        
        @try {
            [encryptionUserKeyManager encryptionKeyTo:mId me:ident];
        }
        @catch (NSException *exception) {
            if ([exception.name isEqualToString:kMusubiExceptionNeedEncryptionUserKey])
                [self requestEncryptionKeyFor: ident];
            else
                @throw exception;
        }
        
        @try {
            [signatureUserKeyManager signatureKeyFrom:mId me:ident];
        }
        @catch (NSException *exception) {
            if ([exception.name isEqualToString:kMusubiExceptionNeedSignatureUserKey])
                [self requestSignatureKeyFor: ident];
            else
                @throw exception;
        }
    }
}

- (void) requestEncryptionKeyFor: (IBEncryptionIdentity*) ident {
    assert (ident.authority != kIdentityTypeLocal);

    [manager.requestedEncryptionKeys addObject: ident];
    
    BOOL addedNewKeys = NO;
    while (manager.requestedEncryptionKeys.count > 0) {
        IBEncryptionIdentity* hid = [manager.requestedEncryptionKeys objectAtIndex:0];
        
        NSLog(@"Getting enc key for %@", hid.principal);
        
        // Retrieve this specific encryption key if possible
        MIdentity* mId = [identityManager identityForIBEncryptionIdentity:hid];
        IBEncryptionIdentity* ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:hid.authority principal:hid.principal temporalFrame:hid.temporalFrame];
        
        @try {
            IBEncryptionUserKey* userKey = [manager.identityProvider encryptionKeyForIdentity: ibeId];
            assert(userKey != nil);
            
            MEncryptionUserKey* key = (MEncryptionUserKey*)[store createEntity:@"EncryptionUserKey"];
            [key setIdentity: mId];
            [key setPeriod: hid.temporalFrame];
            [key setKey: userKey.raw];
            [store save];
            
            NSLog(@"New encryption key: %@", key);
            
            [manager.encryptionBackoff removeObjectForKey: hid];
            addedNewKeys = YES;
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:kMusubiExceptionAphidNeedRetry]) {
                long backoff = [manager updateBackoffForIdentity:hid inMap:manager.encryptionBackoff];
                NSLog(@"Encryption key fetchfailed for %@, retrying in %ld msec", mId.principal, backoff);
                //requestEncryptionKeyAfterDelay(hid, backoff);
            } else {
                NSLog(@"Server unable to obtain key for %@: %@", mId.principal, exception);
            }
        }
        
        [manager.requestedEncryptionKeys removeObject: hid];
        
    }

    if (addedNewKeys) {
        [[Musubi sharedInstance].notificationCenter postNotification: [NSNotification notificationWithName:kMusubiNotificationEncodedMessageReceived object:nil]];
    }
}


- (void) requestSignatureKeyFor: (IBEncryptionIdentity*) ident {
    assert (ident.authority != kIdentityTypeLocal);
    
    [manager.requestedSignatureKeys addObject: ident];
    
    BOOL addedNewKeys = NO;
    while (manager.requestedSignatureKeys.count > 0) {
        IBEncryptionIdentity* hid = [manager.requestedSignatureKeys objectAtIndex:0];
        
        NSLog(@"Getting sig key for %@", hid.principal);
        
        // Retrieve this specific encryption key if possible
        MIdentity* mId = [identityManager identityForIBEncryptionIdentity:hid];
        IBEncryptionIdentity* ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:hid.authority principal:hid.principal temporalFrame:hid.temporalFrame];
        
        @try {
            IBSignatureUserKey* userKey = [manager.identityProvider signatureKeyForIdentity: ibeId];
            assert(userKey != nil);
            
            MSignatureUserKey* key = (MSignatureUserKey*)[store createEntity:@"SignatureUserKey"];
            [key setIdentity: mId];
            [key setPeriod: hid.temporalFrame];
            [key setKey: userKey.raw];
            
            [signatureUserKeyManager createSignatureUserKey:key];
            [manager.signatureBackoff removeObjectForKey: hid];
            addedNewKeys = YES;
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:kMusubiExceptionAphidNeedRetry]) {
                long backoff = [manager updateBackoffForIdentity:hid inMap:manager.signatureBackoff];
                NSLog(@"Signature key fetchfailed for %@, retrying in %ld msec", mId.principal, backoff);
                //requestEncryptionKeyAfterDelay(hid, backoff);
            } else {
                NSLog(@"Server unable to obtain key for %@: %@", mId.principal, exception);
            }
        }
        
        [manager.requestedSignatureKeys removeObject: hid];
        
    }
    
    if (addedNewKeys) {
        [[Musubi sharedInstance].notificationCenter postNotification: [NSNotification notificationWithName:kMusubiNotificationPlainObjReady object:nil]];
    }

}


@end
