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


#import "FacebookIdentityUpdater.h"
#import "FacebookAuth.h"
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

@implementation FacebookIdentityUpdater

#define kMusubiSettingsFacebookLastIdentityFetch @"FBLastIdentityFetch"

@synthesize queue, storeFactory = _storeFactory;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)storeFactory {
    self = [super init];
    if (self) {
        [self setQueue: [NSOperationQueue new]];
        [queue setMaxConcurrentOperationCount:1];
        
        [self setStoreFactory: storeFactory];
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(refreshFriends) name:kMusubiNotificationFacebookFriendRefresh object:nil];
        [self refreshFriendsIfNeeded];
    }
    return self;
}

-(void) refreshFriendsIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate* lastFetch = [defaults objectForKey:kMusubiSettingsFacebookLastIdentityFetch];
    
    if (lastFetch == nil || [lastFetch timeIntervalSinceNow] < -kFacebookIdentityUpdaterFrequency / 2) {
        [self refreshFriends];
    }
}

- (void) refreshFriends {
    if (queue.operationCount == 0) {
        FacebookIdentityFetchOperation* op = [[FacebookIdentityFetchOperation alloc] initWithStoreFactory:_storeFactory];
        [queue addOperation: op];
    }
}

@end

@implementation FacebookIdentityFetchOperation

@synthesize authManager = _authManager, storeFactory = _storeFactory, store = _store, request = _request;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)storeFactory {
    self = [super init];
    if (self) {
        [self setAuthManager: [[FacebookAuthManager alloc] init]];
        [self setStoreFactory: storeFactory];
    }
    return self;
}

- (void)main {
    [super main];
    
    NSLog(@"Fetching Facebook friends");
    
    // Keep this reference around, otherwise it gets released for some reason
    me = self;
    
    [self setStore: [_storeFactory newStore]];
    
    if ([_authManager.facebook isSessionValid]) {
        // Fetch list of friends, handled by request:didLoad:
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:2];
        [params setObject:@"fql.query" forKey:@"method"];
        [params setObject:@"SELECT uid, name, pic_square FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1 = me())" forKey:@"query"];
        _request = [_authManager.facebook requestWithParams:params andDelegate:self];
    } else {
        NSLog(@"Facebook not valid!");
    }
    
    CFRunLoopRun();
}

- (void)finish
{
    CFRunLoopStop(CFRunLoopGetCurrent());
    me = nil;
    
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationIdentityImportFinished object:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook", @"type", nil]];

}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    [self finish];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    NSMutableArray* identities = [NSMutableArray array];
    NSMutableDictionary* photoURIs = [NSMutableDictionary dictionary];
    
    IdentityManager* im = [[IdentityManager alloc] initWithStore: _store];
    AccountManager* am = [[AccountManager alloc] initWithStore: _store];
    FeedManager* fm = [[FeedManager alloc] initWithStore:_store];

    int index = 0;
    // Create/update the identities
    for (NSDictionary* f in result) {
        long long uid = [[f objectForKey:@"uid"] longLongValue];
        IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeFacebook principal:[NSString stringWithFormat:@"%llu", uid] temporalFrame:0];
        
        MIdentity* mId = [im ensureIdentity:ident withName:[f objectForKey:@"name"] identityAdded:&_identityAdded profileDataChanged:&_profileDataChanged];
        
        if (mId.thumbnail == nil) {
            mId.thumbnail = [self fetchImageFromURL: [f objectForKey:@"pic_square"]];
            if (mId.thumbnail != nil) {
                _profileDataChanged = YES;
            }            
        }        

        /* for fetching photos outside of this loop
        [identities addObject: mId];
        if ([f objectForKey:@"pic_square"])
            [photoURIs setObject:[f objectForKey:@"pic_square"] forKey:mId.objectID];
         */

        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationIdentityImported object:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:index], @"index", [NSNumber numberWithInt:[result count]], @"total", @"facebook", @"type", nil]];
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
    
    NSString* email = @""; // facebook logged in user email
    NSString* facebookId = @""; // facebook user id
    assert (email != nil && facebookId != nil);
    

    MAccount* account = [am accountWithName: email andType: kAccountTypeFacebook];
    if (account == nil) {
        IBEncryptionIdentity* ibeId = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeFacebook principal:facebookId temporalFrame:0];
        account = [am create];
        [account setName: email];
        [account setType: kAccountTypeFacebook];
        
        MIdentity* existing = [im identityForIBEncryptionIdentity: ibeId];
        if (existing != nil) {
            [account setIdentity: existing];
        }
        
        [_store save];
    }
    
    if (account.feed == nil) {
        MFeed* feed = [fm create];
        [feed setAccepted: NO];
        [feed setType: kFeedTypeAsymmetric];
        [feed setName: kFeedNameLocalWhitelist];
        [_store save];
    }
    
    [fm attachMembers:identities toFeed:account.feed];    

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:kMusubiSettingsFacebookLastIdentityFetch];
    [defaults synchronize];    
    
    [self finish];
}

- (NSData*) fetchImageFromURL: (NSString*) url {
    NSURLResponse* response;
    NSError* error;
    return [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL: [NSURL URLWithString:url]] returningResponse:&response error:&error];
}

@end