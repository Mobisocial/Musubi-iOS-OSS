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
#import "FriendPickerViewController.h"
#import "FeedViewController.h"
#import "FirstIdentityViewController.h"

@interface FeedListViewControllerDelegate : TTTableViewVarHeightDelegate

@end

@interface FeedListViewController : TTTableViewController<FriendPickerViewControllerDelegate, FeedViewControllerDelegate, UIActionSheetDelegate, FirstIdentityViewControllerDelegate> {
    UILabel* incomingLabel;
    
    NSString* _connectionState;
    TTStyleSheet *previousStyleSheet;
}

@property (nonatomic, strong) NSMutableArray* unclaimed;
@property (nonatomic, strong) MIdentity* ownedId;
@property (nonatomic, readonly) UIView* noFeedsView;
@property (nonatomic, strong) Obj* clipboardObj;

- (IBAction)newConversation:(id)sender;
- (void) showFriendPicker;

- (void) setClipboardObj:(Obj*)obj;

@end
