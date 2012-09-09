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
#import "Three20/Three20.h"

@class FeedListViewController;


@protocol FirstIdentityViewControllerDelegate <NSObject>

- (void) identityCreated;

@end

@interface FirstIdentityViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UITextFieldDelegate> {
    UIScrollView* _scroll;
    UIButton* _thumbnailButton;
    UITextField* _nameField;
    TTView* _buttonContainer;
    UIPopoverController* _popover;
}

@property (nonatomic) id<FirstIdentityViewControllerDelegate> delegate;

@end
