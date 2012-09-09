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


#import "AphidIdentityProvider.h"
#import "Musubi.h"

#import "NSData+Base64.h"
#import "AccountManager.h"
#import "IdentityManager.h"

#import "MAccount.h"
#import "MIdentity.h"
#import "FacebookAuth.h"
#import "GoogleAuth.h"
#import "SBJSON.h"
#import "Authorities.h"

#import "IBEncryptionScheme.h"

@implementation AphidIdentityProvider

@synthesize signatureScheme, encryptionScheme, identityManager, knownTokens;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.encryptionScheme = [IBEncryptionScheme alloc];
        self.signatureScheme = [IBSignatureScheme alloc];
        
        [self setIdentityManager: [[IdentityManager alloc] initWithStore: [[Musubi sharedInstance] newStore]]];
        
        [self setKnownTokens: [NSMutableDictionary dictionary]];
    }
    return self;
}


- (IBSignatureUserKey *)signatureKeyForIdentity:(IBEncryptionIdentity *)ident {
    if(ident.principal == nil) {
        ident = [identityManager ibEncryptionIdentityForHasedIdentity:ident];
        if (ident.principal == nil)
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidRequest reason:@"Identity's principal must be known to request signature from Aphid" userInfo:nil];
    }

    return [[IBSignatureUserKey alloc] initWithRaw:[NSData data]];
}

- (IBEncryptionUserKey *)encryptionKeyForIdentity:(IBEncryptionIdentity *)ident {
    if(ident.principal == nil) {
        ident = [identityManager ibEncryptionIdentityForHasedIdentity:ident];
        if (ident.principal == nil)
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidRequest reason:@"Identity's principal must be known to request encryption from Aphid" userInfo:nil];
    }
    
    return [[IBEncryptionUserKey alloc] initWithRaw:[NSData data]];
}

- (void) setToken: (NSString*) token forUser: (NSString*) principal withAuthority: (int) authority {
    [knownTokens setObject:token forKey:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedChar:authority], principal, nil]];
}
- (void) cacheFacebookToken {
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    NSString* facebookId = nil;

    NSArray* accounts = [accMgr accountsWithType: kAccountTypeFacebook];
    if (accounts.count > 0) {
        facebookId = ((MAccount*)[accounts objectAtIndex:0]).identity.principal;
    }
    
    NSString* facebookToken = nil;
    if (facebookId != nil) {
        FacebookAuthManager* mgr = [[FacebookAuthManager alloc] init];
        facebookToken = [mgr activeAccessToken];
    }
    
    if (facebookToken != nil) {
        [self setToken:facebookToken forUser:facebookId withAuthority:kIdentityTypeFacebook];
    } else if (facebookId != nil) {
        // Authentication failures should be reported
        //        sendNotification("Facebook");
        @throw [NSException exceptionWithName:kMusubiExceptionAphidBadToken reason:@"Bad token" userInfo:nil];
    }
}

- (void) cacheGoogleToken {
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    NSString* googleId = nil;
    
    NSArray* accounts = [accMgr accountsWithType: kAccountTypeGoogle];
    
    if (accounts.count > 0) {
        googleId = ((MAccount*)[accounts objectAtIndex:0]).identity.principal;
    }
    
    NSString* googleToken = nil;
    if (googleId != nil) {
        GoogleAuthManager* mgr = [[GoogleAuthManager alloc] init];
        googleToken = [mgr activeAccessToken];
    }
    
    if (googleToken != nil) {
        [self setToken:googleToken forUser:googleId withAuthority:kIdentityTypeEmail];
    } else if (googleId != nil) {
        // Authentication failures should be reported
        //        sendNotification("Google");
        @throw [NSException exceptionWithName:kMusubiExceptionAphidBadToken reason:@"Bad token" userInfo:nil];
    }
}

- (NSDictionary*) googleTokens {
    NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
    
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    GoogleAuthManager* mgr = [[GoogleAuthManager alloc] init];
    
    
    for (MAccount* acc in [accMgr accountsWithType: kAccountTypeGoogle]) {
        NSString* googleId = acc.identity.principal;
        NSString* token = [mgr activeAccessToken];
        
        if (googleId && !token) {
            @throw [NSException exceptionWithName:kMusubiExceptionAphidBadToken reason:@"Bad token" userInfo:nil];
        }
        
        [tokens setObject:token forKey:googleId];
    }
    
    return tokens;
}

- (NSDictionary*) facebookTokens {
    NSMutableDictionary* tokens = [NSMutableDictionary dictionary];
    
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    FacebookAuthManager* mgr = [[FacebookAuthManager alloc] init];
    
    for (MAccount* acc in [accMgr accountsWithType: kAccountTypeFacebook]) {
        NSString* facebookId = acc.identity.principal;
        
        //assert(facebookId != nil);
        
        NSString* token = [mgr activeAccessToken];
        
        if (facebookId && !token) {
            @throw [NSException exceptionWithName:kMusubiExceptionAphidBadToken reason:@"Bad token" userInfo:nil];
        }
        
        if (facebookId != nil) {
            [tokens setObject:token forKey:facebookId];
        }
    }

    return tokens;
}

@end


