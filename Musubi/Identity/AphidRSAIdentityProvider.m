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

#import "AphidRSAIdentityProvider.h"
#import "Musubi.h"

#import "NSData+Base64.h"
#import "AccountManager.h"
#import "IdentityManager.h"
#import "CryptoIdentity.h"

#import "MAccount.h"
#import "MIdentity.h"
#import "FacebookAuth.h"
#import "GoogleAuth.h"
#import "SBJSON.h"
#import "XQueryComponents.h"
#import "Authorities.h"

#import "RSAEncryptionScheme.h"

static NSString* kAphidServerLocation = @"http://localhost:9005/key";

static uint8_t kAphidPropertySignature = 1;

static uint8_t kAphidPropertyCrypto = 2;


@implementation AphidRSAIdentityProvider

@synthesize identityManager, knownTokens;

- (id) init {
    self = [super init];
    if (self != nil) {
        [self setIdentityManager: [[IdentityManager alloc] initWithStore: [[Musubi sharedInstance] newStore]]];
        [self setKnownTokens: [NSMutableDictionary dictionary]];
    }
    return self;
}

- (RSAKey *)signatureKeyForIdentity:(RSAIdentity *)ident {
    if(ident.principal == nil) {
        ident = [identityManager rsaIdentityForHashedIdentity:ident];
        if (ident.principal == nil)
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidRequest reason:@"Identity's principal must be known to request signature from Aphid" userInfo:nil];
    }
    
    NSData* raw = [self queryAphidProperty: kAphidPropertySignature forIdentity: ident];
    assert (raw != nil);
    return [[RSAKey alloc] initWithEncoded: raw];
}

- (RSAKey *)encryptionKeyForIdentity:(RSAIdentity *)ident {
    if(ident.principal == nil) {
        ident = [identityManager rsaIdentityForHashedIdentity:ident];
        if (ident.principal == nil)
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidRequest reason:@"Identity's principal must be known to request encryption from Aphid" userInfo:nil];
    }
    
    NSData* raw = [self queryAphidProperty: kAphidPropertyCrypto forIdentity: ident];
    assert (raw != nil);
    return [[RSAKey alloc] initWithEncoded:raw];
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


- (NSData*) queryAphidProperty: (uint8_t) property forIdentity: (id<CryptoIdentity>) ident {
    [self cacheFacebookToken];
    [self cacheGoogleToken];
    
    // Get a service-specific token if it exists
    NSArray* userProps = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedChar:ident.authority], ident.principal, nil];
    NSString* aphidToken = [knownTokens objectForKey:userProps];
    
    // The IBE server has its own identifiers for providers
    NSString* aphidType = nil;
    switch (ident.authority) {
		case kIdentityTypeFacebook:
			aphidType = @"facebook";
			break;
		case kIdentityTypeEmail:
            if ([[knownTokens allKeys] containsObject:userProps])
                aphidType = @"google";
			else
				aphidType = @"email";
			break;
		default:
			// Do not ask the server for identities we don't know how to handle
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidAccountType reason:[NSString stringWithFormat: @"Aphid doesn't support authority type %d", ident.authority] userInfo:nil];
    }
    
    NSMutableDictionary* requestDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [requestDict setObject: aphidType forKey:@"type"];
//    [requestDict setObject: ident. forKey:@"identity"];
    if (property == kAphidPropertySignature)
        [requestDict setObject: aphidToken forKey:@"token"];
    
    NSLog(@"Request dict: %@", requestDict);
    
    // Make the request
    AphidRSARequest* req = [[AphidRSARequest alloc] initWithRequestDictionary: requestDict];
    [req performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
    
    // TODO: smarter wait
    while (![req isFinished]) {
        [NSThread sleepForTimeInterval:0.1];
    }
    
    id result = [req response];
    if (result == nil) {
        @throw [NSException exceptionWithName:kMusubiExceptionAphidNeedRetry reason:@"Aphid request failed: no response" userInfo:nil];
    }
    
    NSString* encodedKey = result;//[result objectForKey:property];
    NSLog(@"Key: %@", encodedKey);
    BOOL hasError = [[result allKeys] containsObject:@"error"];
    
    if (!hasError) {
        return [encodedKey decodeBase64];
    } else {
        // Aphid authentication error means Musubi has a bad token
        NSString* error = [result objectForKey:@"error"];
        if ([error rangeOfString:@"401"].location != NSNotFound) {
            // Authentication errors require user action
            //sendNotification(accountType);
            @throw [NSException exceptionWithName:kMusubiExceptionAphidBadToken reason:@"Bad token" userInfo:nil];
        }
        else {
            // Other failures should be retried silently
            @throw [NSException exceptionWithName:kMusubiExceptionAphidNeedRetry reason:@"Aphid request failed: unspecified error" userInfo:nil];
        }
    }
    
    @throw [NSException exceptionWithName:kMusubiExceptionAphidNeedRetry reason:@"Aphid request failed: not handled" userInfo:nil];
}

@end


@implementation AphidRSARequest

@synthesize request, response, error, finished, connection;

- (id)initWithRequestDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        finished = NO;
        
        [self setRequest: [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kAphidServerLocation]]];
        
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody: [[dict stringFromQueryComponents] dataUsingEncoding:NSUTF8StringEncoding]]; 
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];        
    }
    return self;
}

- (void)main {
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];}

- (BOOL)isFinished {
    return finished;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    id arr = [parser objectWithString:json];    
    if ([arr count] > 0) {
        [self setResponse: [arr objectAtIndex:0]];
    }
    
    finished = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)e {
    [self setError: e];
    finished = YES;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {    
    
    // TODO: Check SSL cert
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (YES)//|| [trustedHosts containsObject:challenge.protectionSpace.host])
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

@end