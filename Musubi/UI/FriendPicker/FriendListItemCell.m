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

#import "FriendListItemCell.h"
#import "Three20UI/UIViewAdditions.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "FriendListItem.h"

static const CGFloat    kDefaultMessageImageWidth   = 50.0f;
static const CGFloat    kDefaultMessageImageHeight  = 50.0f;

@implementation FriendListItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self profilePictureView];
    _profilePictureView.contentMode = UIViewContentModeScaleAspectFit;
    _profilePictureView.frame = CGRectMake(0, 0, kDefaultMessageImageWidth, kDefaultMessageImageHeight);

    int left = _profilePictureView.right + kTableCellSmallMargin;
    int width = self.contentView.width - left - kTableCellMargin;
    
    self.textLabel.left = left;
    self.textLabel.width = width;
    self.detailTextLabel.left = left;
    self.detailTextLabel.width = width;

}

- (void)setObject:(FriendListItem*)object {
    self.textLabel.text = object.musubiName;
    self.detailTextLabel.text = object.realName;
    if (object.selected || object.pinned) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    if(object.identity.musubiThumbnail) {
        _profilePictureView.image = [UIImage imageWithData:object.identity.musubiThumbnail];
    } else {
        _profilePictureView.image = [UIImage imageWithData:object.identity.thumbnail];
    }
}

- (UIImageView*)profilePictureView {
    if (!_profilePictureView) {
        _profilePictureView = [[UIImageView alloc] init];
        [self.contentView addSubview:_profilePictureView];
    }
    return _profilePictureView;
}

+ (CGFloat)tableView:(UITableView *)tableView rowHeightForObject:(id)object {
    return 50;
}

@end
