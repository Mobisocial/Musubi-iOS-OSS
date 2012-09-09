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

#import "Three20/Three20.h"
#import "MIdentity.h"

@class IdentityManager, FriendListItem;

@interface FriendListDataSource : TTSectionedDataSource {
    IdentityManager* _identityManager;
    NSMutableArray* _allItems;
    NSMutableArray* _allSections;
    NSString* _lastSearch;
}

@property (nonatomic, retain) NSMutableArray* selection;
@property (nonatomic, retain) TTPickerTextField* pickerTextField;
@property (nonatomic, readonly) NSArray* selectedIdentities;
@property (nonatomic, retain) NSArray* pinnedIdentities;

- (FriendListItem*) itemAtIndexPath: (NSIndexPath*) indexPath;
- (NSIndexPath*) indexPathForItem: (FriendListItem*) item;
- (FriendListItem*) itemForIdentity: (MIdentity*) identity;
- (BOOL) toggleSelectionForItem: (FriendListItem*) item;
- (FriendListItem*) existingItemByPrincipal: (NSString*) principal;
@end
