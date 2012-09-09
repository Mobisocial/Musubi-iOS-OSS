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

#import "PicturePickerOverlayDelegate.h"

@implementation PicturePickerOverlayDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo 
{
    
}
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}

+ (void) setupImagePicker:(UIImagePickerController*)imagePickerController sourceType:(UIImagePickerControllerSourceType)type 
{
    imagePickerController.sourceType = type;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            imagePickerController.showsCameraControls = NO;
            imagePickerController.cameraOverlayView addSubview:self.view];
            self.view.frame = CGRectMake(0.0, 0.0, 320, 480);
        } else {            
            self.view.frame = CGRectMake(0.0, 0.0, 320, 460);
        }
        
        self.preview.hidden = YES;
        self.toolBar.hidden = NO;
        self.editButton.hidden = YES;
        self.captionButton.hidden = YES;
        self.captionView.hidden = YES;
    } else {
        // Setup iPad Views
        if (self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
            self.imagePickerController.showsCameraControls = NO;
            [self.imagePickerController.cameraOverlayView addSubview:self.view];
            self.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        } else {
            self.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
        }
        
        self.preview.hidden = YES;
        self.toolBar.hidden = NO;
        self.editButton.hidden = YES;
        self.captionButton.hidden = YES;
        self.captionView.hidden = YES;
    }
    
}
@end
