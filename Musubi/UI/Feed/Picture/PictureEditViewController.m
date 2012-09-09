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

#import "PictureEditViewController.h"
#import "PictureObj.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"
#import "UIImage+Resize.h"

@implementation PictureEditViewController

@synthesize picture = _picture, delegate = _delegate;
@synthesize pictureView = _pictureView;
@synthesize overlayViewController = _overlayViewController;

- (void)loadView {
    [super loadView];
    
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 416, 320, 44)];
    toolbar.tintColor = [UIColor colorWithWhite:240.0/255.0 alpha:1.0];
    [self.view addSubview:toolbar];
    
    UIBarButtonItem* retakeButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(rechoosePhoto:)];
    retakeButton.tintColor = [UIColor lightGrayColor];
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem* useButton = [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStyleBordered target:self action:@selector(usePhoto:)];
    useButton.tintColor = [UIColor blueColor];
    [toolbar setItems:[NSArray arrayWithObjects:retakeButton, flex, useButton, nil]];
}

- (IBAction)usePhoto:(id)sender {
    if (self.delegate) {
        [self.delegate pictureEditViewController:self chosePicture:_picture];
    }
}

- (IBAction)rechoosePhoto:(id)sender {
    if (self.delegate) {
        [self.delegate pictureEditViewController:self didCancel:YES];
    }
}

- (void)setPicture:(UIImage *)picture {
    _picture = picture;
    
    /* For some bizar reason, UIViewContentModeScaleAspectFit doesn't always scale images properly, so we'll do it ourselves */
    
    CGFloat xScale = picture.size.width / 320;
    CGFloat yScale = picture.size.height / 427;
    CGFloat scale = MAX(xScale, yScale);
    CGSize bounds = CGSizeMake(picture.size.width / scale * 2, picture.size.height / scale * 2);
    
    UIImage* scaledImage = [picture resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:bounds interpolationQuality:0.9];

    if (bounds.height > self.pictureView.frame.size.height * 2) {
        self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        self.pictureView.contentMode = UIViewContentModeScaleAspectFit;
    }
    self.pictureView.image = scaledImage;
}

- (void)setOverlayViewController:(UIViewController *)overlayViewController {
    if (_overlayViewController != nil) {
        [_overlayViewController.view removeFromSuperview];
    }
    
    _overlayViewController = overlayViewController;
    _overlayViewController.view.frame = CGRectMake(0, 0, 320, 436);
    [self.view addSubview:_overlayViewController.view];
    [self.view bringSubviewToFront:_overlayViewController.view];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIImageView *)pictureView {
    if (_pictureView == nil) {
        _pictureView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320.0, 416.0)];
        _pictureView.backgroundColor = [UIColor blackColor];
        _pictureView.clipsToBounds = YES;

        [self.view addSubview:_pictureView];
        [self.view bringSubviewToFront:_overlayViewController.view];
    }
    
    return _pictureView;
}
@end
