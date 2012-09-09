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

#import "IntroductionObjItemCell.h"
#import "IdentityManager.h"
#import "Musubi.h"
#import "NSData+Base64.h"
#import "IBEncryptionScheme.h"
#define kAddedSomePeople @"Added some people."

@implementation IntroductionObjItemCell

+ (NSString*) textForItem: (ManagedObjFeedItem*)item {
    IdentityManager* im = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    NSArray* identities = [[item parsedJson] objectForKey:@"identities"];
    int max = 5;
    int count = MIN(identities.count, max);
    BOOL more = identities.count > max;
    NSMutableString* buffer = [[NSMutableString alloc] initWithCapacity:50];
    [buffer appendString:@"Added: "];
    for (int i = 0; i < count; i++) {
        uint8_t authority = [(NSNumber*)[[identities objectAtIndex:i] objectForKey:@"authority"] unsignedCharValue];
        NSData* hash = [(NSString*)[[identities objectAtIndex:i] objectForKey:@"hash"] decodeBase64];
        if(!hash)
            continue;
        IBEncryptionIdentity* hid = [[IBEncryptionIdentity alloc] initWithAuthority:authority hashedKey:hash temporalFrame:0];
        MIdentity* ident = [im identityForIBEncryptionIdentity:hid];
        if(!ident)
            continue;
        [buffer appendString: [IdentityManager displayNameForIdentity:ident]];
        if (i < (count-1)) {
            [buffer appendString: @", "];
        } else if (i == count-2) {
            if (!more) {
                if (count == 2) {
                    [buffer appendString: @" and "];
                } else {
                    [buffer appendString: @", and "];
                }
            }
        }
    }
    if (more) {
        [buffer appendFormat:@" and %d more.", (identities.count - max)];
    } else {
        [buffer appendString:@"."];
    }
    return buffer;
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem*)item {
    NSString* text = [IntroductionObjItemCell textForItem:item];
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

- (void)setObject:(ManagedObjFeedItem*)object {
    [super setObject:object];

    self.detailTextLabel.text = [IntroductionObjItemCell textForItem:object];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
