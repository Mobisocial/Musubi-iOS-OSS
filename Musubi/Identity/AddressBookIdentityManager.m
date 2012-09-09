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


#import "AddressBookIdentityManager.h"
#import <AddressBook/AddressBook.h>
#import "AccountAuthManager.h"
#import "Authorities.h"
#import "AccountManager.h"
#import "IdentityManager.h"
#import "FeedManager.h"
#import "Musubi.h"
#import "PersistentModelStore.h"
#import "MIdentity.h"
#import "IBEncryptionScheme.h"
#import "MAccount.h"
#import "MFeed.h"

@implementation AddressBookIdentityManager

#define kMusubiSettingsAddressBookLastIdentityFetch @"AddressBookLastIdentityFetch"

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
    NSDate* lastFetch = [defaults objectForKey:kMusubiSettingsAddressBookLastIdentityFetch];
    
    if ((lastFetch == nil || [lastFetch timeIntervalSinceNow] < -kAddressBookIdentityUpdaterFrequency / 2))
    {
        [self refreshFriends];
    }
}

- (void) refreshFriends {
    NSLog(@"Fetching Address book friends");
    if (queue.operationCount == 0) {
        AddressBookIdentityFetchOperation* op = [[AddressBookIdentityFetchOperation alloc] initWithStoreFactory:_storeFactory];
        [queue addOperation: op];
    }
}

@end



@implementation AddressBookIdentityFetchOperation

@synthesize storeFactory = _storeFactory, store = _store;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)storeFactory {
    self = [super init];
    if (self) {
        [self setStoreFactory: storeFactory];
    }
    return self;
}

- (void)main {
    [super main];
    
    [self setStore: [_storeFactory newStore]];
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    NSMutableArray* identities = [NSMutableArray arrayWithCapacity:CFArrayGetCount(people)];
    
    IdentityManager* im = [[IdentityManager alloc] initWithStore: _store];
    AccountManager* am = [[AccountManager alloc] initWithStore: _store];
    FeedManager* fm = [[FeedManager alloc] initWithStore:_store];
    
    // Create/update the identities
    for (CFIndex i = 0; i < CFArrayGetCount(people); i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(people, i);
        
        NSString* firstName = (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
        NSString* lastName  = (__bridge NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
        if (firstName == nil)
            continue;
        
        NSString* name = [NSString stringWithFormat: @"%@ %@", firstName, lastName != nil ? lastName : @""];
        
        ABMultiValueRef emails = ABRecordCopyValue(person, kABPersonEmailProperty);

        for (CFIndex j=0; j < ABMultiValueGetCount(emails); j++) {
            NSString* email = (__bridge NSString*)ABMultiValueCopyValueAtIndex(emails, j);
                        
            IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:email temporalFrame:0];            
            MIdentity* mId = [im ensureIdentity:ident withName:name ? name : email identityAdded:&_identityAdded profileDataChanged:&_profileDataChanged];
            
            [identities addObject: mId];
            
            if (ABPersonHasImageData(person)) {
                mId.thumbnail = (__bridge NSData*) ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
                _profileDataChanged = YES;
            }
        }
        
        CFRelease(emails);
                
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationIdentityImported object:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"index", [NSNumber numberWithInt:CFArrayGetCount(people)], @"total", @"email", @"type", nil]];
    }

    for (MAccount* account in [am accountsWithType: kAccountTypeEmail]) {
        if (account.feed == nil) {
            MFeed* feed = [fm create];
            [feed setAccepted: NO];
            [feed setType: kFeedTypeAsymmetric];
            [feed setName: kFeedNameLocalWhitelist];            
            
            [_store save];            
            account.feed = feed;
        }
        
        [fm attachMembers:identities toFeed:account.feed];    

    }
    
    [_store save];
            
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:kMusubiSettingsAddressBookLastIdentityFetch];
    [defaults synchronize];
    NSLog(@"Address book import done");
}



@end