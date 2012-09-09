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

#import "FirstIdentityViewController.h"
#import "MusubiStyleSheet.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "UIImage+Resize.h"
#import "Musubi.h"
#import "MAccount.h"
#import "AccountAuthManager.h"
#import "AccountManager.h"

@implementation FirstIdentityViewController

@synthesize delegate = _delegate;

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [((id)[TTStyleSheet globalStyleSheet]) tablePlainBackgroundColor];
    
    // Setup views for iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _scroll.contentSize = CGSizeMake(320, 920);
        _scroll.scrollEnabled = NO;
        [self.view addSubview:_scroll];
      
        TTView* buttonContainer = [[TTView alloc] initWithFrame:CGRectMake(90, 30, 140, 140)];
        _buttonContainer = buttonContainer;
        buttonContainer.backgroundColor = [UIColor clearColor];
        buttonContainer.style = [MusubiStyleSheet textViewBorder];
        UILabel* imageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, 120, 20)];
        imageLabel.font = [UIFont systemFontOfSize:12];
        imageLabel.textAlignment = UITextAlignmentCenter;
        imageLabel.text = @"Choose your picture";
        [buttonContainer addSubview:imageLabel];
        _thumbnailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _thumbnailButton.frame = CGRectMake(10, 10, 120, 120);
        [_thumbnailButton addTarget:self action:@selector(choosePicture:) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:_thumbnailButton];
        [_scroll addSubview:buttonContainer];
        
        _nameField = [[UITextField alloc] initWithFrame:CGRectMake(50, 200, 220, 29)];
        _nameField.borderStyle = UITextBorderStyleRoundedRect;
        _nameField.delegate = self;
        _nameField.placeholder = @"Your name";
        _nameField.textAlignment = UITextAlignmentCenter;
        [_scroll addSubview:_nameField];
        
        TTButton* startButton = [[TTButton alloc] initWithFrame:CGRectMake(60, 320, 200, 50)];
        [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
        [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
        [startButton setTitle:@"Start a chat" forState:UIControlStateNormal];
        [startButton addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
        [_scroll addSubview:startButton];
    
    // Setup views for iPad
    } else {
        _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _scroll.contentSize = CGSizeMake(320, 920);
        _scroll.scrollEnabled = NO;
        [self.view addSubview:_scroll];
        
        NSInteger centerWidth = self.view.frame.size.width/2;
        NSInteger centerHeight = self.view.frame.size.height/2;
        NSInteger pictureSize = 300;
        
        TTView* buttonContainer = [[TTView alloc] initWithFrame:CGRectMake(centerWidth-(pictureSize/2), 100, pictureSize, pictureSize)];
        buttonContainer.backgroundColor = [UIColor clearColor];
        buttonContainer.style = [MusubiStyleSheet textViewBorder];
        UILabel* imageLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, pictureSize/2-20, pictureSize-10, 50)];
        imageLabel.font = [UIFont systemFontOfSize:22];
        imageLabel.textAlignment = UITextAlignmentCenter;
        imageLabel.text = @"Choose your picture";
        [buttonContainer addSubview:imageLabel];
        _thumbnailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _thumbnailButton.frame = CGRectMake(0, 0, pictureSize, pictureSize);
        [_thumbnailButton addTarget:self action:@selector(choosePicture:) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:_thumbnailButton];
        buttonContainer.layer.masksToBounds = YES;
        buttonContainer.layer.cornerRadius = 25; // if you like rounded corners
        /*buttonContainer.layer.shadowOffset = CGSizeMake(0, 0);
        buttonContainer.layer.shadowRadius = 20;
        buttonContainer.layer.shadowOpacity = 0.2;*/
        [buttonContainer.layer setBorderColor: [[UIColor blackColor] CGColor]];
        [buttonContainer.layer setBorderWidth: 5.0];
        [_scroll addSubview:buttonContainer];
        
        _nameField = [[UITextField alloc] initWithFrame:CGRectMake(centerWidth-(pictureSize/2), centerHeight-40, pictureSize, 29)];
        _nameField.borderStyle = UITextBorderStyleRoundedRect;
        _nameField.delegate = self;
        _nameField.placeholder = @"Your name";
        _nameField.textAlignment = UITextAlignmentCenter;
        [_scroll addSubview:_nameField];
        
        TTButton* startButton = [[TTButton alloc] initWithFrame:CGRectMake(centerWidth-(200/2), centerHeight+40, 200, 50)];
        [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
        [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
        [startButton setTitle:@"Start a chat" forState:UIControlStateNormal];
        [startButton addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
        [_scroll addSubview:startButton];
        
    }
    AccountAuthManager *authMgr = [[AccountAuthManager alloc] initWithDelegate:self];
    
    if ([authMgr isConnected:kAccountTypeGoogle]) {
        AccountManager* accMgr = [[AccountManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        MAccount *acc = [[accMgr accountsWithType:kAccountTypeGoogle] objectAtIndex:0];
        
        [_nameField setText:acc.identity.name];
        [_thumbnailButton setImage:[[UIImage alloc] initWithData:acc.identity.musubiThumbnail] forState:UIControlStateNormal];
    }
}

- (IBAction)startChat:(id)sender {
    if (_nameField.text.length < 2) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"Please enter your name so your friends can see who you are." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        return;
    }
    
    IdentityManager* idMgr = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    
    for (MIdentity* ident in idMgr.ownedIdentities) {
        ident.musubiName = _nameField.text;
        ident.musubiThumbnail = UIImageJPEGRepresentation([_thumbnailButton imageForState:UIControlStateNormal], 0.9);
        [idMgr updateIdentity:ident];
    }
    
    [self.navigationController popViewControllerAnimated:NO];
    [_delegate identityCreated];
}

- (IBAction)choosePicture:(id)sender {    
    UIActionSheet* commandPicker = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Picture From Album", nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [commandPicker showInView:self.view];
    } else {
        NSInteger centerWidth = self.view.frame.size.width/2;
        NSInteger pictureSize = 300;

        /*UIView* test = [[UIView alloc] init];
        test.frame = commandPicker.frame;
        
        _popover=[[UIPopoverController alloc] initWithContentViewController:test];
        _popover.delegate=self;
        
        [_popover presentPopoverFromRect:CGRectMake(centerWidth-(pictureSize/2), 100, pictureSize, pictureSize) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        [commandPicker showInView:test];*/

        [commandPicker showFromRect:CGRectMake(centerWidth-(pictureSize/2), 100, pictureSize, pictureSize) inView:self.view animated:YES];
    }

}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0: // take picture
        {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController* picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.delegate = self;
                [self presentModalViewController:picker animated:YES];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't have a camera" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            break;
        }
        case 1: // existing picture
        {
                    
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController* picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.delegate = self;
                
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                    
                    [self presentModalViewController:picker animated:YES];
                
                } else {
                
                    _popover=[[UIPopoverController alloc] initWithContentViewController:picker];
                    _popover.delegate=self;
                    
                    NSInteger centerWidth = self.view.frame.size.width/2;
                    NSInteger pictureSize = 300;
                    
                    [_popover presentPopoverFromRect:CGRectMake(centerWidth-(pictureSize/2), 100, pictureSize, pictureSize) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];

                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't support the photo library" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            
            break;
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [self dismissModalViewControllerAnimated:YES];
    
    UIImage* resized = [image centerFitAndResizeTo:CGSizeMake(300, 300)];
    
    [_thumbnailButton setImage:resized forState:UIControlStateNormal];
    [_popover dismissPopoverAnimated:YES];
}


- (UINavigationItem *)navigationItem {
    UINavigationItem* item = [super navigationItem];
    item.hidesBackButton = YES;
    item.title = @"Tell us about yourself";
    return item;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) keyboardWillShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
        
    _scroll.contentOffset = CGPointMake(0, 40);
    [UIView commitAnimations];
}

- (void) keyboardWillHide:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    _scroll.contentOffset = CGPointMake(0, 0); 
    [UIView commitAnimations]; 
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_nameField resignFirstResponder];
    return YES;
}



@end
