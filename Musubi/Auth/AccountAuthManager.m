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


#import "AccountAuthManager.h"

#import "NSObject+DDExtensions.h"

#import "Musubi.h"

#import "FacebookAuth.h"
#import "GoogleAuth.h"
#import "IBEncryptionScheme.h"

#import "PersistentModelStore.h"
#import "AccountManager.h"
#import "MusubiDeviceManager.h"
#import "IdentityManager.h"

#import "MIdentity.h"
#import "MAccount.h"
#import "MDevice.h"
#import "MFeed.h"
#import "Authorities.h"

#import "GTMOAuth2ViewControllerTouch.h"

@implementation AccountAuthManager

@synthesize delegate, queue;

- (id)init {
    self = [super init];
    if (self) {
        [self setQueue: [[NSOperationQueue alloc] init]];
    }
    return self;
}

- (id)initWithDelegate:(id<AccountAuthManagerDelegate>)d {
    self = [self init];
    if (self) {
        [self setDelegate: d];
    }
    return self;
}

- (NSArray *)principalsForAccount:(NSString *)type {
    NSMutableArray* principals = [NSMutableArray array];
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    for (MAccount* acc in [accMgr accountsWithType:type]) {
        [principals addObject:acc.name];
    }
    return principals;
}

- (BOOL)isConnected:(NSString *)type {
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    NSArray* accounts = [accMgr accountsWithType:type];
    return (accounts != nil && accounts.count > 0);
}

- (void) checkStatus:(NSString *)type {
    [self checkStatus:type withPrincipal:nil];
}

- (void) checkStatus:(NSString *)type withPrincipal:(NSString*)principal {
    assert(delegate != nil);
    
    // First see if there is an account for the network.
    if (![self isConnected: type]) {
        [self onAccount:type isValid:NO];
        return;
    }
    
    // Then see if it is still valid
    if ([type isEqualToString:kAccountTypeFacebook]) {
        FacebookCheckValidOperation* op = [[FacebookCheckValidOperation alloc] initWithManager:self];
        [queue addOperation: op];
    } else if ([type isEqualToString:kAccountTypeGoogle]) {
        GoogleOAuthCheckValidOperation* op = [[GoogleOAuthCheckValidOperation alloc] initWithManager:self];
        [queue addOperation: op];
    } else {
        @throw [NSException exceptionWithName:kMusubiExceptionInvalidAccountType reason:[NSString stringWithFormat:@"Account type %@ unknown", type] userInfo:nil];
    }
}

- (void)connect:(NSString *)type withPrincipal: (NSString*) principal {
    if ([type isEqualToString:kAccountTypeFacebook]) {
        FacebookLoginOperation* op = [[FacebookLoginOperation alloc] initWithManager:self];
        [queue addOperation: op];
    } else if ([type isEqualToString:kAccountTypeGoogle]){
        GoogleOAuthLoginOperation* op = [[GoogleOAuthLoginOperation alloc] initWithManager:self];
        [queue addOperation: op];
    } else {
        @throw [NSException exceptionWithName:kMusubiExceptionInvalidAccountType reason:[NSString stringWithFormat:@"Account type %@ unknown", type] userInfo:nil];
    }
}

- (void)connect:(NSString *)type {
    [self connect:type withPrincipal:nil];
}

- (void)disconnect:(NSString *)type withPrincipal: (NSString*) principal {
    AccountManager* accMgr = [[AccountManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    
    if ([type isEqualToString:kAccountTypeFacebook]) {
        for (MAccount* acc in [accMgr accountsWithType:kAccountTypeFacebook]) {
            if (principal == nil || [principal isEqualToString:acc.name]) {
                [accMgr deleteAccount:acc];
            }
        }
    } else if ([type isEqualToString:kAccountTypeGoogle]){
        for (MAccount* acc in [accMgr accountsWithType:kAccountTypeGoogle]) {
            if (principal == nil || [principal isEqualToString:acc.name]) {
                [accMgr deleteAccount:acc];
            }
        }
        
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kGoogleKeyChainItemName];
    } else {
        @throw [NSException exceptionWithName:kMusubiExceptionInvalidAccountType reason:[NSString stringWithFormat:@"Account type %@ unknown", type] userInfo:nil];
    }
    
    [accMgr.store save];
    [self onAccount:type isValid:NO];
}

- (void)disconnect:(NSString *)type {
    [self disconnect: type withPrincipal:nil];
}

- (void)onAccount:(NSString *)type isValid:(BOOL)valid {
    if (delegate != nil) {
        [[((NSObject*)delegate) invokeOnMainThread] accountWithType:type isConnected:valid];
    }
}

- (void) populateIdentity: (MIdentity*) mIdent fromIBEIdentity: (IBEncryptionIdentity*) ibeId andOriginal: (MIdentity*) original withManager: (IdentityManager*) identityManager andAccountName: (NSString*) accountName {
    
    [mIdent setClaimed: YES];
    [mIdent setOwned: YES];
    //    [mIdent setWhiteListed: YES];
    //    [mIdent setHasSentEmail: YES];
    [mIdent setName: accountName];
    [mIdent setPrincipal: ibeId.principal];
    [mIdent setType: ibeId.authority];
    [mIdent setPrincipalHash: ibeId.hashed];
    [mIdent setPrincipalShortHash: *(uint64_t*)ibeId.hashed.bytes];
    //    [mIdent setSentProfileVersion: 1];
    //    [mIdent setMusubiName: original.musubiName];
    //    [mIdent setMusubiThumbnail: identityManager.musubiThumbNailFor: original];
    //    [mIdent setReceivedProfileVersion: original.receivedProfileVersion];
    
    switch (mIdent.type) {
        case kIdentityTypeFacebook:
        {
            //TODO: fetch name and photo from facebook
            //break;
        }
        default:
        {
            /*
             if (mIdent.musubiName == nil) {
             [mIdent setMusubiName: mIdent.name];
             }
             if (mIdent.musubiName == nil) {
             [mIdent setMusubiName: randomFunName()];
             }*/
        }
            
    }
}
- (BOOL) checkAccount: (NSString*) type name: (NSString*) name principal: (NSString*) principal{
    IBEncryptionIdentity* ibeId = nil;
    
    if ([type isEqualToString:kAccountTypeFacebook]) {
        ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeFacebook principal:principal temporalFrame:0];
    } else if([type isEqualToString:kAccountTypeGoogle]) {
        ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:principal temporalFrame:0];
    } else if([type isEqualToString:kAccountTypeEmail]) {
        ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:principal temporalFrame:0];
    } else {
        @throw [NSException exceptionWithName:kMusubiExceptionInvalidAccountType reason:[NSString stringWithFormat: @"Unsupported account type %@", type] userInfo:nil];
    }
    
    @try {
        PersistentModelStore* store = [[Musubi sharedInstance] newStore];
        IdentityManager* identityManager = [[IdentityManager alloc] initWithStore:store];
        
        //TODO: DB transaction start?
        MAccount* mAccount = (MAccount*)[store queryFirst:[NSPredicate predicateWithFormat:@"name=%@ AND type=%@", name, type] onEntity:@"Account"];
        
        // Don't repeatedly add profile broadcast groups or do any
        // of this processing if the account is already owned.
        MIdentity* mId = [identityManager identityForIBEncryptionIdentity:ibeId];
        if (mAccount != nil && mId != nil && mId.owned) {
            return YES;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Err: %@", exception);
    }
    @finally {
        
    }
    return NO;
}
- (MAccount*) storeAccount: (NSString*) type name: (NSString*) name principal: (NSString*) principal{
    IBEncryptionIdentity* ibeId = nil;
    
    if ([type isEqualToString:kAccountTypeFacebook]) {
        ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeFacebook principal:principal temporalFrame:0];
    } else if([type isEqualToString:kAccountTypeGoogle]) {
        ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:principal temporalFrame:0];
    } else if([type isEqualToString:kAccountTypeEmail]) {
        ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:principal temporalFrame:0];
    } else {
        @throw [NSException exceptionWithName:kMusubiExceptionInvalidAccountType reason:[NSString stringWithFormat: @"Unsupported account type %@", type] userInfo:nil];
    }
    
    @try {
        PersistentModelStore* store = [[Musubi sharedInstance] newStore];
        IdentityManager* identityManager = [[IdentityManager alloc] initWithStore:store];
        
        //TODO: DB transaction start?
        MAccount* mAccount = (MAccount*)[store queryFirst:[NSPredicate predicateWithFormat:@"name=%@ AND type=%@", name, type] onEntity:@"Account"];
        
        // Don't repeatedly add profile broadcast groups or do any
        // of this processing if the account is already owned.
        MIdentity* mId = [identityManager identityForIBEncryptionIdentity:ibeId];
        if (mAccount != nil && mId != nil && mId.owned) {
            return mAccount;
        }
        
        NSArray* existing = [identityManager ownedIdentities];
        MIdentity* original = existing.count > 0 ? [existing objectAtIndex:0] : nil;
        if (mId == nil) {
            mId = (MIdentity*)[identityManager create];
            [self populateIdentity:mId fromIBEIdentity:ibeId andOriginal:original withManager:identityManager andAccountName:name];
            [identityManager createIdentity:mId];
        } else {
            [self populateIdentity:mId fromIBEIdentity:ibeId andOriginal:original withManager:identityManager andAccountName:name];
            [identityManager updateIdentity:mId];
        }
        
        // [identityManager updateMyProfileName: mId.musubiName];
        // [identityManager updateMyProfilePicture: mId.musubiThumbnail];
        
        // Ensure account entry exists
        
        if (mAccount == nil) {
            mAccount = (MAccount*)[store createEntity:@"Account"];
            [mAccount setName: principal];
            [mAccount setType: type];
            [mAccount setIdentity: mId];
            //[store save];
        } else {
            [mAccount setIdentity: mId];
            //[store save];
        }
        
        MusubiDeviceManager* deviceManager = [[MusubiDeviceManager alloc] initWithStore:store];
        MDevice* device = [deviceManager deviceForName: [deviceManager localDeviceName] andIdentity: mId];
        if (device == nil) {
            device = (MDevice*)[store createEntity:@"Device"];
            [device setDeviceName: [deviceManager localDeviceName]];
            [device setIdentity: mId];
            //[store save];
        }
        
        // This feed will contain all members who should receive
        // a profile for the account because of a friend introduction
        MFeed* provisionalFeed = (MFeed*) [store createEntity:@"Feed"];
        [provisionalFeed setName: kFeedNameProvisionalWhitelist];
        [provisionalFeed setType: kFeedTypeAsymmetric];
        //[store save];
        
        // TODO: in other places in the code, we should be pruning the
        // Provisional whitelist feed as people become whitelisted..
        
        MAccount* provAccount = (MAccount*)[store createEntity:@"Account"];
        [provAccount setName: kAccountNameProvisionalWhitelist];
        [provAccount setType: kAccountTypeInternal];
        [provAccount setIdentity: mId];
        [provAccount setFeed: provisionalFeed];
        //[store save];
        
        // This feed will contain all members who should receive
        // a profile for the account because they are whitelisted
        // and contacted you on one of your accounts.
        MFeed* accountBroadcastFeed = (MFeed*)[store createEntity:@"Feed"];
        [accountBroadcastFeed setName: kFeedNameLocalWhitelist];
        [accountBroadcastFeed setType: kFeedTypeAsymmetric];
        //[store save];
        
        MAccount* localAccount = (MAccount*) [store createEntity:@"Account"];
        [localAccount setName: kAccountNameLocalWhitelist];
        [localAccount setType: kAccountTypeInternal];
        [localAccount setIdentity: mId];
        [localAccount setFeed: accountBroadcastFeed];
        //[store save];
        
        // End DB transaction
        [store save];
        
        // Notify OwnedIdentityAvailable
        [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationOwnedIdentityAvailable object:nil]];
        [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationMyProfileUpdate object:nil]];
        [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationAuthTokenRefresh object:nil]];
        
        //TODO: wizard, account linked complete
        //TODO: report account connected

        return mAccount;
    }
    @catch (NSException *exception) {
        NSLog(@"Err: %@", exception);
    }
    @finally {
        
    }
}


@end
