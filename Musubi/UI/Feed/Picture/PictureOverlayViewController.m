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

#import "PictureOverlayViewController.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"
#import "Three20UI+Additions.h"
#import "FeedViewController.h"

@implementation PictureOverlayViewController

@synthesize delegate = _delegate;
@synthesize toolBar = _toolBar;
@synthesize auxiliaryTitle = _auxiliaryTitle;
@synthesize image = _image;
@synthesize edited = _edited;

- (id)init
{
    self = [super init];
    if (!self) return nil;
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
    self.preview.hidden = NO;
    self.captionButton.hidden = NO;
    self.editButton.hidden = NO;
    [self toolBar];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.preview.image = image;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:YES];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _screenHeight = self.view.height;
    //caption clearing if clicked outside?
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
}


//relayout on rotate
- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    UIButton* cameraButton = [[self.toolBar.items objectAtIndex:2] customView];
    UIButton* cancelButton = [[self.toolBar.items objectAtIndex:0] customView];
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.15];
            cameraButton.transform = CGAffineTransformIdentity;
            cancelButton.transform = CGAffineTransformIdentity;

            [UIView commitAnimations];

            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            
            cameraButton.transform = CGAffineTransformMakeRotation(M_PI);
            cancelButton.transform = CGAffineTransformMakeRotation(M_PI);
            
            [UIView commitAnimations];
            break;
            
        case UIDeviceOrientationLandscapeLeft:
        {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            

            cameraButton.transform = CGAffineTransformMakeRotation(M_PI/2);
            cancelButton.transform = CGAffineTransformMakeRotation(M_PI/2);
            
            [UIView commitAnimations];
            break;
        }
        case UIDeviceOrientationLandscapeRight:
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.2];
            
            cameraButton.transform = CGAffineTransformMakeRotation(-M_PI/2);
            cancelButton.transform = CGAffineTransformMakeRotation(-M_PI/2);

            [UIView commitAnimations];
            break;
            
        default:
            break;
    };
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (IBAction) showCaption:(id)sender {
    self.captionView.hidden = NO;
    [self.captionField becomeFirstResponder];
}
- (void)auxiliaryAction
{
    [self.delegate picturePickerAuxiliaryButton:self];
}

- (NSArray*) toolbarItems {
    UIBarButtonItem* retakeItem = [[UIBarButtonItem alloc] initWithTitle:self.auxiliaryTitle style:UIBarButtonItemStyleBordered target:self action:@selector(auxiliaryAction)];
    
    UIBarButtonItem* useItem = [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStyleDone target:self action:@selector(usePicture:)];
    
    return [NSArray arrayWithObjects:
                    retakeItem,
                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                    useItem,
                    nil];
}

- (UIImageView*) preview {
    if (!_preview) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _preview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.height-55)];
        } else {
            _preview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height-25)];
        }
        _preview.backgroundColor = [UIColor blackColor];
        _preview.contentMode = UIViewContentModeScaleAspectFit;
        _preview.hidden = YES;
        [self.view addSubview:_preview];
    }
    return _preview;
}

- (UIToolbar*) toolBar {
    if (!_toolBar) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _toolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.height-55, 320, 55)];
            _toolBar.barStyle = UIBarStyleBlackOpaque;
            _toolBar.items = self.toolbarItems;
            [self.view addSubview:_toolBar];
        } else {
            _toolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.height-55, self.view.width, 55)];
            _toolBar.barStyle = UIBarStyleBlackOpaque;
            _toolBar.items = self.toolbarItems;
            [self.view addSubview:_toolBar];
        }
    }
    return _toolBar;
}

- (TTButton*) editButton {
    if (!_editButton) {
        _editButton = [[TTButton alloc] init];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _editButton.frame = CGRectMake(10, self.view.height-100, 80, 34);
        } else {
            _editButton.frame = CGRectMake(10, self.view.height-100, 80, 34);
        }
        [_editButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateNormal] forState:UIControlStateNormal];
        [_editButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateHighlighted] forState:UIControlStateHighlighted]; 
        [_editButton setTitle:@"Edit" forState:UIControlStateNormal];
        [_editButton addTarget:self action:@selector(editPicture:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_editButton];
    }
    return _editButton;
}

- (TTButton*) captionButton {
    if (!_captionButton) {
        _captionButton = [[TTButton alloc] init];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _captionButton.frame = CGRectMake(210, self.view.height-100, 100, 34);
        } else {
            _captionButton.frame = CGRectMake(self.view.width-110, self.view.height-100, 100, 34);

        }
        
        [_captionButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateNormal] forState:UIControlStateNormal];
        [_captionButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateHighlighted] forState:UIControlStateHighlighted]; 
        [_captionButton setTitle:@"Caption" forState:UIControlStateNormal];
        [_captionButton addTarget:self action:@selector(showCaption:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_captionButton];
    }
    return _captionButton;
}

- (UILabel*) captionLabel {
    if (!_captionLabel) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.height-100, 320, 44)];
        } else {
            _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.height-100, self.view.width, 44)];
        }
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _captionLabel.font = [UIFont systemFontOfSize:14];
        _captionLabel.textColor = [UIColor whiteColor];
        _captionLabel.textAlignment = UITextAlignmentCenter;
        
        [self.view addSubview:_captionLabel];
    }
    
    return _captionLabel;
}

- (UIView*) captionView {
    if (!_captionView) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _captionView = [[TTView alloc] initWithFrame:CGRectMake(0, self.view.height-54, 320, 44)];
        } else {
            _captionView = [[TTView alloc] initWithFrame:CGRectMake(0, self.view.height-54, self.view.width, 44)];
        }
        ((TTView*)_captionView).style = [MusubiStyleSheet bottomPanelStyle];
        _captionView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _captionView.hidden = YES;
        
        [self.view addSubview:_captionView];
    }
    return _captionView;
}

- (UITextField*) captionField {
    if (!_captionField) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            _captionField = [[UITextField alloc] initWithFrame: CGRectMake(10, 5, 290, 34)];
        } else {
            _captionField = [[UITextField alloc] initWithFrame: CGRectMake(10, 5, self.view.width-30, 34)];
        }
        _captionField.backgroundColor = [UIColor clearColor];
        _captionField.font = [UIFont systemFontOfSize:16.0];
        _captionField.delegate = self;
        _captionField.textColor = [UIColor blackColor];
        
        TTView* statusFieldBox = [[TTView alloc] initWithFrame:CGRectMake(5, 5, _captionField.frame.size.width+20, _captionField.frame.size.height)];
        statusFieldBox.backgroundColor = [UIColor whiteColor];
        statusFieldBox.style = [MusubiStyleSheet textViewBorder];
        [statusFieldBox addSubview: _captionField];
        
        [self.captionView addSubview:statusFieldBox];
    }
    
    return _captionField;
}

- (void) hideKeyboard {
    [self.captionField resignFirstResponder];
}

- (void) keyboardDidShow: (NSNotification*) notification {
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIWindow *window = [[[UIApplication sharedApplication] windows]objectAtIndex:0];
    CGRect keyboardFrameConverted = CGRectNull;
    keyboardFrameConverted = [self.view convertRect:keyboardFrame fromView:window];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.captionView.center = CGPointMake(160, keyboardFrameConverted.origin.y - self.captionView.frame.size.height / 2);
    } else {
        self.captionView.center = CGPointMake(self.view.width/2, keyboardFrameConverted.origin.y - self.captionView.frame.size.height / 2);
    }
}

- (void) keyboardWillHide: (NSNotification*) notification {
    self.captionView.hidden = YES;
    self.captionLabel.text = self.captionField.text;
    
    if (self.captionLabel.text.length) {
        self.captionLabel.hidden = NO;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.captionButton.frame = CGRectMake(210, self.view.height-100-44, 100, 34);
            self.editButton.frame = CGRectMake(10, self.view.height-100-44, 80, 34);
        } else {
            self.captionButton.frame = CGRectMake(self.view.width-110, self.view.height-100-44, 100, 34);
            self.editButton.frame = CGRectMake(10, self.view.height-100-44, 80, 34);
            
        }
    } else {
        self.captionLabel.hidden = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.captionButton.frame = CGRectMake(210, self.view.height-100, 100, 34);
            self.editButton.frame = CGRectMake(10, self.view.height-100, 80, 34);
        } else {
            self.captionButton.frame = CGRectMake(self.view.width-110, self.view.height-100, 100, 34);
            self.editButton.frame = CGRectMake(10, self.view.height-100, 80, 34);
        }
    }
}

#pragma mark - Text view delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}



#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (IBAction)usePicture:(id)sender {
    [self.delegate picturePickerFinished:self withPicture:_preview.image withCaption:self.captionLabel.text];
}

- (IBAction)editPicture:(id)sender {
    
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage: _preview.image];
    editorController.delegate = self;
    
    [self presentViewController:editorController animated:YES completion:NULL];
}

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {    
    _preview.image = image;
    _edited = YES;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
