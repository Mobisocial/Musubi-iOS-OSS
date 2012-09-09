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

@class PictureObj, TTView, PictureEditViewController;

@protocol PictureEditViewControllerDelegate

- (void) pictureEditViewController: (PictureEditViewController*) vc chosePicture: (UIImage*) picture;
- (void) pictureEditViewController: (PictureEditViewController*) vc didCancel: (BOOL) cancel;

@end

@interface PictureEditViewController : UIViewController {
    BOOL shown;
    
    UIImageView* _pictureView;
}

@property (nonatomic, weak) id<PictureEditViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage* picture;
@property (nonatomic, readonly) UIImageView* pictureView;
@property (nonatomic, retain) UIViewController* overlayViewController;

- (IBAction)share:(id)sender;

@end