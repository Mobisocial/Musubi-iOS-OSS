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


#import "GoogleIdentityUpdater.h"
#import "GoogleAuth.h"
#import "Musubi.h"
#import "IBEncryptionScheme.h"
#import "MIdentity.h"
#import "Authorities.h"
#import "IdentityManager.h"
#import "FeedManager.h"
#import "PersistentModelStore.h"
#import "AccountManager.h"
#import "MAccount.h"
#import "MFeed.h"
#import "GTMOAuth2Authentication.h"
#import "SBJSON.h"
#import "AccountAuthManager.h"


@implementation GoogleIdentityUpdater

#define kMusubiSettingsGoogleLastIdentityFetch @"GoogleLastIdentityFetch"

@synthesize queue, storeFactory = _storeFactory;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)storeFactory {
    self = [super init];
    if (self) {
        [self setQueue: [NSOperationQueue new]];
        [queue setMaxConcurrentOperationCount:1];
        
        [self setStoreFactory: storeFactory];
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(refreshFriends) name:kMusubiNotificationGoogleFriendRefresh object:nil];
        [self refreshFriendsIfNeeded];
    }
    return self;
}

- (void) refreshFriendsIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate* lastFetch = [defaults objectForKey:kMusubiSettingsGoogleLastIdentityFetch];
    AccountAuthManager* authMgr = [[AccountAuthManager alloc] initWithDelegate:self];
    BOOL gConnected = [authMgr isConnected:kAccountTypeGoogle];

    if ((lastFetch == nil || [lastFetch timeIntervalSinceNow] < -kGoogleIdentityUpdaterFrequency / 2) && gConnected)
    {
        [self refreshFriends];
    }
}

- (void) refreshFriends {
    NSLog(@"Fetching Google friends");
    if (queue.operationCount == 0) {
        GoogleIdentityFetchOperation* op = [[GoogleIdentityFetchOperation alloc] initWithStoreFactory:_storeFactory];
        [queue addOperation: op];
    }
}

@end

@implementation GoogleIdentityFetchOperation

@synthesize authManager = _authManager, storeFactory = _storeFactory, store = _store;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)storeFactory {
    self = [super init];
    if (self) {
        [self setAuthManager: [[GoogleAuthManager alloc] init]];
        [self setStoreFactory: storeFactory];
    }
    return self;
}

- (void)main {
    [super main];
        
    [self setStore: [_storeFactory newStore]];
    
    if ([_authManager activeAccessToken]) {
        // Fetch list of friends, handled by request:didLoad:
        [self fetchFromURL:@"https://www.google.com/m8/feeds/contacts/default/full?v=3.0&alt=json&max-results=500"];
    }
}

- (void) fetchFromURL: (NSString*) url {
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    if ([[_authManager activeAuth] authorizeRequest:req]) {
        
        NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
        NSString* json = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        SBJsonParser* parser = [[SBJsonParser alloc] init];
        NSDictionary* feed = [parser objectWithString:json];
        
        if (feed) {
            [self storeContacts: [[feed objectForKey:@"feed"] objectForKey:@"entry"]];                
            
            NSString* next = nil;
            for (NSDictionary* link in [[feed objectForKey:@"feed"] objectForKey:@"link"]) {
                if ([[link objectForKey:@"rel"] isEqualToString:@"next"]) {
                    next = [link objectForKey:@"href"];
                    break;
                }
            }
            
            if (next) {
                NSLog(@"Next: %@", next);
                [self fetchFromURL: next];
            }
        }
    }
}

- (void) storeContacts: (NSDictionary*) dict {
    NSMutableArray* identities = [NSMutableArray array];
    NSMutableDictionary* photoURIs = [NSMutableDictionary dictionary];
    
    IdentityManager* im = [[IdentityManager alloc] initWithStore: _store];
    AccountManager* am = [[AccountManager alloc] initWithStore: _store];
    FeedManager* fm = [[FeedManager alloc] initWithStore:_store];
    
    // Create/update the identities
    int index = 0;
    for (NSDictionary* contact in dict) {
        NSString* name = [[[contact objectForKey:@"gd$name"] objectForKey:@"gd$fullName"] objectForKey:@"$t"];
        NSString* picture = nil;
        
        for (NSDictionary* link in [contact objectForKey:@"link"]) {
            if ([[link objectForKey:@"type"] isEqualToString:@"image/*"]) {
                picture = [link objectForKey:@"href"];
            }
        }
                        
        for (NSDictionary* email in [contact objectForKey:@"gd$email"]) {
            NSString* address = [email objectForKey:@"address"];
            if (address) {
                IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:address temporalFrame:0];
                
                MIdentity* mId = [im ensureIdentity:ident withName:name ? name : address identityAdded:&_identityAdded profileDataChanged:&_profileDataChanged];
                
                [identities addObject: mId];
                
                /* for fetching thumbnail later
                if (picture)
                    [photoURIs setObject:picture forKey:mId.objectID];*/
                
                if (picture && mId.thumbnail == nil) {
                    mId.thumbnail = [self fetchImageFromURL: picture];
                    if (mId.thumbnail != nil) {
                        _profileDataChanged = YES;
                    }
                }
            }
        }
        
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationIdentityImported object:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:index], @"index", [NSNumber numberWithInt:[dict count]], @"total", @"google", @"type", nil]];
        index++;
    }
    
    /*
    // Update the profile photos
    for (MIdentity* mId in identities) {
        if (mId.thumbnail != nil)
            continue;
        
        mId.thumbnail = [self fetchImageFromURL: [photoURIs objectForKey:mId.objectID]];
        if (mId.thumbnail != nil) {
            _profileDataChanged = YES;
        }
    }*/
    
    NSString* email = _authManager.activeAuth.userEmail;

    assert (email != nil);
    MAccount* account = [am accountWithName:email andType:kAccountTypeGoogle];
    
        if (account.feed == nil) {
            MFeed* feed = [fm create];
            [feed setAccepted: NO];
            [feed setType: kFeedTypeAsymmetric];
            [feed setName: kFeedNameLocalWhitelist];
            
            //[_store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:feed] error:nil];
            [_store save];
            
            account.feed = feed;
        }
        
        [fm attachMembers:identities toFeed:account.feed];    
        

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:kMusubiSettingsGoogleLastIdentityFetch];
    [defaults synchronize];
    NSLog(@"Google import done");
}

- (NSData*) fetchImageFromURL: (NSString*) url {
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    if ([[_authManager activeAuth] authorizeRequest:req]) {
        return [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    }
    
    return nil;
}



@end
