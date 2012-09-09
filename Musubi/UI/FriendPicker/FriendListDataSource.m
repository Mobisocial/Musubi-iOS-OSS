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

#import "FriendListDataSource.h"
#import "FriendListModel.h"
#import "IdentityManager.h"
#import "Musubi.h"
#import "MIdentity.h"
#import "FriendListItem.h"
#import "FriendListItemCell.h"
#import "IBEncryptionScheme.h"
#import "PersistentModelStore.h"

@implementation FriendListDataSource {
    FriendListItem* itemToDelete;
    UITableView* tableViewToUpdate;
    NSMutableDictionary* feedCache;
}

@synthesize pickerTextField = _pickerTextField;
@synthesize selection = _selection;
@synthesize pinnedIdentities = _pinnedIdentities;

- (id) init {
    self = [super init];
    if (self) {
        self.model = [[FriendListModel alloc] init];

        _identityManager = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        _selection = [NSMutableArray array];
    }
    return self;
}


- (void)tableViewDidLoadModel:(UITableView *)tableView {
    NSMutableArray* sections = [NSMutableArray array];
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:self.sections.count];
    
    NSComparisonResult (^compare) (MIdentity*, MIdentity*) = ^(MIdentity* obj1, MIdentity* obj2) {
        NSString* a = [IdentityManager displayNameForIdentity:obj1];
        NSString* b = [IdentityManager displayNameForIdentity:obj2];
        a = [a stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        b = [b stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        return [a caseInsensitiveCompare:b];
    };
    
    NSMutableArray* idents = ((FriendListModel*)self.model).results;
    [idents sortUsingComparator: compare];
    
    NSMutableArray* sectionItems = nil;
    if (_pinnedIdentities && _pinnedIdentities.count) {
        [sections addObject:[NSString stringWithFormat:@"\u2713"]];
        sectionItems = [NSMutableArray array];
        [items addObject:sectionItems];
        
        for (MIdentity* ident in _pinnedIdentities) {
            if (!ident.owned)
                [sectionItems addObject:[self itemForIdentity:ident]];
        }
    }
    
    char sectionChar = 0;
    for (MIdentity* ident in idents) {
        if (ident.owned)
            continue;
        
        if ([_pinnedIdentities containsObject:ident])
            continue;
        
        char curChar = [[IdentityManager displayNameForIdentity:ident] characterAtIndex:0];
        if (curChar >= 'a')
            curChar -= ('a' - 'A');

        if (curChar != sectionChar) {
            sectionChar = curChar;
            [sections addObject:[NSString stringWithFormat:@"%c", curChar]];
            sectionItems = [NSMutableArray array];
            [items addObject:sectionItems];
        }
        
        [sectionItems addObject:[self itemForIdentity:ident]];
    }
    
    self.sections = sections;
    _allSections = sections;
    self.items = items;
    _allItems = items;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString* t = [_sections objectAtIndex:section];
    if([t isEqualToString:@"\u2713"])
        t = @"Already Added";
    return t;
    
}


- (FriendListItem*) itemForIdentity: (MIdentity*) ident {
    FriendListItem* item = [[FriendListItem alloc] initWithIdentity:ident];
    
    item.selected = [_selection containsObject:ident];
    item.pinned = [_pinnedIdentities containsObject:ident];
    
    return item;
}

- (FriendListItem*) existingItemByPrincipal: (NSString*) principal {
    for (NSMutableArray* section in self.items) {
        for (FriendListItem* sectionItem in section) {
            if ([sectionItem.identity.principal isEqualToString:principal]) {
                return sectionItem;
            }
        }
    }
    return nil;
}

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITableView * tableView = tableViewToUpdate;
    tableViewToUpdate = nil;
    FriendListItem* originalItem = itemToDelete;
    itemToDelete = nil;
    if(buttonIndex != 1)
        return;
    
    

    MIdentity* identity = originalItem.identity;
    
    [tableView beginUpdates];
    
    if (!originalItem.pinned) {
        if (originalItem.selected) {
            [_pickerTextField removeCellWithObject: originalItem];
        }
    }
    
    for(int i = self.items.count - 1; i >= 0; --i) {
        NSMutableArray* section_items = [self.items objectAtIndex:i];
        for(int j = section_items.count - 1; j >= 0; --j) {
            FriendListItem* item = [section_items objectAtIndex:j];
            if([item.identity.principal isEqual:identity.principal]) {
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:j inSection:i]] withRowAnimation:UITableViewRowAnimationFade];
                [section_items removeObjectAtIndex:j];
            }
        }
        if(!section_items.count) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            [self.items removeObjectAtIndex:i];
            [self.sections removeObjectAtIndex:i];
        }
    }
    
    PersistentModelStore *store = [[Musubi sharedInstance] newStore];
    IdentityManager* identMgr = [[IdentityManager alloc] initWithStore: store];
    [identMgr deleteIdentity:originalItem.identity];
    
    [tableView endUpdates];
}*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Delete Person" message:@"Are you sure?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        
        itemToDelete = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        
        tableViewToUpdate = tableView;
        [alert show];
    }
}

- (void)search:(NSString *)text {
    text = [text uppercaseString];
    
    NSArray* searchItems = nil;
    NSArray* searchSections = nil;
    
    int searchStartSection = 0;
    if (text.length > 0 && _lastSearch != nil && [text rangeOfString:_lastSearch].location == 0) {
        searchItems = self.items;
        searchSections = self.sections;
    } else {
        searchItems = _allItems;
        searchSections = _allSections;
        // If we are searching, ignore the possible pinned identities section
        if (text.length > 0 && _pinnedIdentities && _pinnedIdentities.count) {
            searchStartSection = 1;
        }
    }
    
    NSMutableArray* matchedItems = [NSMutableArray array];
    NSMutableArray* matchedSections = [NSMutableArray array];
    
    
    for (int i=searchStartSection; i<searchSections.count; i++) {
        NSString* section = [searchSections objectAtIndex:i];
        
        NSMutableArray* sectionMatches = nil;
        for (FriendListItem* item in [searchItems objectAtIndex:i]) {
            BOOL match = NO;
            if (!text || text.length == 0) {
                match = YES;
            } else {
                for (NSString* name in item.structuredNames) {
                    if (name.length >= text.length && [[[name substringToIndex:text.length] uppercaseString] isEqualToString:text]) {
                        match = YES;
                        break;
                    }
                }
            }
                
            if (match) {
                if (sectionMatches == nil) {
                    sectionMatches = [NSMutableArray array];
                    [matchedSections addObject:section];
                }
                
                [sectionMatches addObject:item];
            }
        }
        
        if (sectionMatches != nil)
            [matchedItems addObject:sectionMatches];
    }
    
    _lastSearch = text;
    self.items = matchedItems;
    self.sections = matchedSections;
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    return [FriendListItemCell class];
}

- (FriendListItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
    return [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}

- (NSIndexPath*) indexPathForItem: (FriendListItem*) item {
    NSIndexPath* path = nil;
    for (int section = 0; section < self.items.count; section++) {
        NSArray* items = [self.items objectAtIndex:section];
        int row = [items indexOfObject:item];
        if (row >= 0) {
            path = [NSIndexPath indexPathForRow:row inSection:section];
        }
    }
    return path;
}

- (BOOL)toggleSelectionForItem:(FriendListItem *)item {
    if ([_selection containsObject:item]) {
        [_selection removeObject:item];
        [item setSelected:NO];
    } else {
        NSComparisonResult (^compare) (FriendListItem*, FriendListItem*) = ^(FriendListItem* obj1, FriendListItem* obj2) {
            NSString* a = [obj1 musubiName];
            NSString* b = [obj2 musubiName];
            a = [a stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            b = [b stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            return [a caseInsensitiveCompare:b];
        };
        
        [_selection addObject:item];
        [_selection sortedArrayUsingComparator:compare];
        [item setSelected:YES];
    }
    
    return item.selected;
}

- (NSArray *)selectedIdentities {
    NSMutableArray* ids = [NSMutableArray array];
    for (FriendListItem* item in _selection) {
        [ids addObject:item.identity];
    }
    return ids;
}

@end
