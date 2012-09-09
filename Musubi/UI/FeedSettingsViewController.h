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

#import <UIKit/UIKit.h>
#import "FriendPickerViewController.h"
#import "FeedNameCell.h"
#import "UIImage+Resize.h"

@class MFeed;
@class FeedManager;


@protocol FeedSettingsViewControllerDelegate<FriendPickerViewControllerDelegate>
- (void) changedName: (NSString*) name;
@end

@interface FeedSettingsViewController : UITableViewController<UITextFieldDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
    UIButton* broadcastSwitch;
    UIPopoverController* _popover;
}

@property (nonatomic, retain) MFeed* feed;
@property (nonatomic, strong) FeedManager* feedManager;
@property (nonatomic, weak) id<FeedSettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage* thumb;

- (IBAction)flip:(id)sender;

- (IBAction) pictureClicked: (id)sender;

@end
