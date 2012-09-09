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

#import "FriendListItem.h"
#import "MIdentity.h"
#import "IdentityManager.h"

@implementation FriendListItem

@synthesize musubiName = _musubiName, realName = _realName, structuredNames = _structuredNames, profilePicture = _profilePicture, selected = _selected, pinned = _pinned, identity = _identity;

- (id)initWithIdentity:(MIdentity *)ident {
    
    self = [super init];
    if (self) {
        
        self.identity = ident;
        self.musubiName = [IdentityManager displayNameForIdentity: ident];
        self.realName = ![ident.name isEqualToString: self.musubiName] ? ident.name : ident.principal;
        
        /* Delay this until cell render, expensive operation
        if(ident.musubiThumbnail) {
            self.profilePicture = [UIImage imageWithData:ident.musubiThumbnail];
        } else {
            self.profilePicture = [UIImage imageWithData:ident.thumbnail];
        }*/
        
        NSCharacterSet* splitChars = [NSCharacterSet characterSetWithCharactersInString:@" -,."];

        _structuredNames = [NSMutableArray arrayWithObjects:self.realName, self.musubiName, nil];
        [_structuredNames addObjectsFromArray:[self.realName componentsSeparatedByCharactersInSet:splitChars]];
        [_structuredNames addObjectsFromArray:[self.musubiName componentsSeparatedByCharactersInSet:splitChars]];
        
        self.selected = NO;
        self.pinned = NO;
    }
    return self;
}

@end
