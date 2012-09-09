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
#import "AFPhotoEditorController.h"

@class TTButton;
@class PictureOverlayViewController;

@protocol PictureOverlayViewControllerDelegate
- (void) picturePickerFinished:(PictureOverlayViewController*)overlay withPicture:(UIImage *)picture withCaption: (NSString*) caption;
- (void) picturePickerAuxiliaryButton:(PictureOverlayViewController*)overlay;
@end

@interface PictureOverlayViewController : UIViewController<UINavigationControllerDelegate,UITextFieldDelegate,AFPhotoEditorControllerDelegate> {
    UIView* _captionView;
    UITextField* _captionField;
    UILabel* _captionLabel;
    TTButton* _captionButton;
    TTButton* _editButton;
    UIToolbar *_toolBar;
    
    UIImageView* _preview;
    int    _screenHeight;
    UIPopoverController* _popover;
}
-(id)init;

@property (nonatomic, strong) UIImage* image;
@property (nonatomic, readonly) UIView* captionView;
@property (nonatomic, readonly) UITextField* captionField;
@property (nonatomic, readonly) UILabel* captionLabel;
@property (nonatomic, readonly) TTButton* captionButton;
@property (nonatomic, readonly) TTButton* editButton;
@property (nonatomic, readonly) UIToolbar* toolBar;
@property (nonatomic, readonly) UIImageView* preview;
@property (nonatomic, strong) NSString* auxiliaryTitle;
@property (nonatomic, assign) BOOL edited;
@property (nonatomic, strong) id<PictureOverlayViewControllerDelegate> delegate;

@end
