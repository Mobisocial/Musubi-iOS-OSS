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

#import "AccountManager.h"
#import "MAccount.h"
#import "PersistentModelStore.h"
#import "MFeed.h"

@implementation AccountManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Account" andStore:s];
    if (self != nil) {
    }
    return self;
}

- (NSArray*) accountsWithType: (NSString*) type {
    return [self query:[NSPredicate predicateWithFormat:@"type = %@", type]];
}

- (NSArray*) claimedAccounts {
    return [self query:[NSPredicate predicateWithFormat:@"identity.owned = %d", YES]];
}

- (MAccount*) accountWithName: (NSString*) name andType: (NSString*) type {
    return (MAccount*)[self queryFirst: [NSPredicate predicateWithFormat:@"name = %@ AND type = %@", name, type]];
}

- (void) deleteAccount: (MAccount*) account {
    MAccount* provWhitelistAcc = (MAccount*)[self queryFirst:[NSPredicate predicateWithFormat:@"name = %@ AND identity = %@", kAccountNameProvisionalWhitelist, account.identity]];
    if (provWhitelistAcc) {
        if (provWhitelistAcc.feed)
            [store.context deleteObject: provWhitelistAcc.feed];
        [store.context deleteObject: provWhitelistAcc];
    }

    MAccount* localWhitelistAcc = (MAccount*)[self queryFirst:[NSPredicate predicateWithFormat:@"name = %@ AND identity = %@", kAccountNameLocalWhitelist, account.identity]];
    if (localWhitelistAcc) {
        if (localWhitelistAcc.feed)
            [store.context deleteObject: localWhitelistAcc.feed];
        [store.context deleteObject: localWhitelistAcc];
    }
    
    [store.context deleteObject: account];
}

@end
