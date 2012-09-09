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

#import "FeedPhotoViewController.h"
#import "FeedPhoto.h"
#import "FeedViewController.h"
#import "AppManager.h"
#import "IdentityManager.h"
#import "MIdentity.h"
#import "HTMLAppViewController.h"
#import "FeedNameObj.h"
#import "ObjHelper.h"
#import "SHK.h"
#import "PersistentModelStore.h"
#import "ProfileObj.h"
#import "PictureObj.h"
#import "SHKFacebook.h"
#import "MusubiStyleSheet.h"
#import <QuartzCore/QuartzCore.h>
#import "AFPhotoEditorController.h"
#import "MusubiAnalytics.h"

@implementation FeedPhotoViewController

@synthesize feedViewController = _feedViewController, actionButton = _actionButton;


#define kMainActionSheetTag 0
#define kSetAsActionSheetTag 1
#define kEditActionSheetTag 2

- (id)initWithFeedViewController:(FeedViewController *)feedVC andPhoto: (FeedPhoto*) photo {
    self = [super initWithPhoto:photo];
    if (self) {
        _feedViewController = feedVC;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIBarItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                        UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSMutableArray* items = [NSMutableArray arrayWithObjects: space, self.actionButton, nil];
    //NSMutableArray* items = [NSMutableArray arrayWithArray:_toolbar.items];
    //[items addObject: space];
    //[items addObject: self.actionButton];
    _toolbar.items = items;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    NSError *error;
    if (![[GANTracker sharedTracker] trackPageview:kAnalyticsPageFeedGallery withError:&error]) {
        NSLog(@"error in trackPageview");
    }    
}

- (UIBarButtonItem*) actionButton {
    if (!_actionButton) {
        _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                            target:self
                        action:@selector(openMainActionSheet)];
        
        
        
    }
    
    return _actionButton;
}

- (void)openMainActionSheet 
{
    UIActionSheet* actions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save", @"Share", @"Edit", @"Set as...", nil];   
    
    [actions setTag:kMainActionSheetTag];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [actions showInView:self.view];
    } else {
        
        CGRect pictureFrame = CGRectMake(self.view.frame.size.width-25, self.view.frame.size.height-35, 20, 20);
        [actions showFromRect:pictureFrame inView:self.view animated:YES];
    }
    [actions showInView:self.view];
}

- (void)openSetAsActionSheet 
{
    UIActionSheet* actions = [[UIActionSheet alloc] initWithTitle:@"Set as..." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Profile Picture", @"Chat Photo", nil];
    
    [actions setTag:kSetAsActionSheetTag];
    [actions showInView:self.view];
}

- (void)showSuccessIndicatorWithText:(NSString*)text {
    UIView *progressDialogView = [[UIView alloc] initWithFrame: CGRectMake (0,0,200,150)];
    progressDialogView.center = self.view.center;
    progressDialogView.backgroundColor = [UIColor clearColor];
    progressDialogView.alpha = 1.0; //you can leave this line out, since this is the default.
    
    
    UIView *halfTransparentBackgroundView = [[UIView alloc] initWithFrame:CGRectMake (0,0,200,150)];
    halfTransparentBackgroundView.backgroundColor = [UIColor blackColor]; //or whatever...
    halfTransparentBackgroundView.alpha = 0.5;
    halfTransparentBackgroundView.layer.cornerRadius = 10;
    halfTransparentBackgroundView.layer.masksToBounds = YES;
    [progressDialogView addSubview: halfTransparentBackgroundView];
    
    UILabel *successLabel = [[UILabel alloc] initWithFrame:CGRectMake (progressDialogView.frame.size.width/3,progressDialogView.frame.size.height*2/3+5,100,50)];
    
    [successLabel setTextColor:[UIColor whiteColor]];
    [successLabel setBackgroundColor:[UIColor clearColor]];
    successLabel.adjustsFontSizeToFitWidth = YES;
    //[successLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 20.0f]]; 
    //[successLabel setCenter:progressDialogView.center];
    successLabel.text = text;
    [progressDialogView addSubview:successLabel];
    
    UIImage* check = [UIImage imageNamed:@"check.png"];
    
    int checkWidth = 80;
    int checkHeight = 88;
    int checkX = (progressDialogView.frame.size.width - checkWidth)/2;
    int checkY = (progressDialogView.frame.size.height - checkHeight)/2;
    UIImageView* checkmark = [[UIImageView alloc] initWithFrame:CGRectMake (checkX,checkY,checkWidth,checkHeight)];
    checkmark.alpha = 0.7;
    [checkmark setImage:check];
    //checkmark.center = progressDialogView.center;
    
    [progressDialogView addSubview:checkmark];
    
    [UIView transitionWithView:[self view] duration: 0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{ [[self view] addSubview:progressDialogView]; }
                    completion: nil];
    
    // Delay execution of my block for 1 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        [UIView animateWithDuration:0.5
                         animations:^{progressDialogView.alpha = 0.0;}
                         completion:^(BOOL finished){ [progressDialogView removeFromSuperview]; }];
    });
    
    

}

- (void)doSetAsActionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex: (NSInteger)buttonIndex {
    switch(buttonIndex)  {
        case 0:
        {
            PersistentModelStore* store = [[Musubi sharedInstance] newStore];
            IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
            NSArray* mine = [idm ownedIdentities];
            if(mine.count == 0) {
                NSLog(@"No identity, connect an account");
                return;
            }
            NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
            NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
            [NSURLConnection sendAsynchronousRequest:request 
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage  *img  = [[UIImage alloc] initWithData:data];
                                       UIImage* resized = [img centerFitAndResizeTo:CGSizeMake(256, 256)];
                                       NSData* thumbnail = UIImageJPEGRepresentation(resized, 0.90);
                                       
                                       long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
                                       for(MIdentity* me in mine) {
                                           me.musubiThumbnail = thumbnail;
                                           me.receivedProfileVersion = now;
                                       }
                                       [store save];
                                       [ProfileObj sendAllProfilesWithStore:store];
                                       [self showSuccessIndicatorWithText:@"Success"];
                                   }];
            
           
            
            break;
        }
        case 1:
        {
            NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
                        
            NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
            [NSURLConnection sendAsynchronousRequest:request 
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage  *img  = [[UIImage alloc] initWithData:data];
                                       [self performSelectorOnMainThread:@selector(setFeedPicture:) withObject:img waitUntilDone:NO];
                                       
                                   }];
            
            break;
        }
    }
}

- (void) setFeedPicture: (UIImage*) img {
    MFeed* feed = ((FeedPhoto*)self.centerPhoto).obj.feed;
    
    UIImage* resized = [img centerFitAndResizeTo:CGSizeMake(256, 256)];
    NSData* thumbnail = UIImageJPEGRepresentation(resized, 0.90);
    
    
    NSString* name = feed.name;
    
    FeedNameObj* name_change = [[FeedNameObj alloc] initWithName:name andThumbnail:thumbnail];
    
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    
    [ObjHelper sendObj:name_change toFeed:feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
    
    [_feedViewController refreshFeed];
    
    
    [[self modalViewController] dismissModalViewControllerAnimated:YES];
    [self showSuccessIndicatorWithText:@"Success"];

}

- (void)doMainActionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex: (NSInteger)buttonIndex {
    switch(buttonIndex)  {
        case 0:
        {
            // Save the image to the Camera Roll
            NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
            NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
            [NSURLConnection sendAsynchronousRequest:request 
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage  *img  = [[UIImage alloc] initWithData:data];
                                       UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);                                       
                                   }];

            
            break;
        }
        case 1:
        {
            // Share the image
            FeedPhoto* feedPhoto = (FeedPhoto*)self.centerPhoto;
            NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
            NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
            [NSURLConnection sendAsynchronousRequest:request 
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage  *img  = [[UIImage alloc] initWithData:data];
                                       NSString *shareCaption = nil;
                                       
                                       if (feedPhoto.caption == nil) {
                                           shareCaption = [NSString stringWithString:@"sent via Musubi"];
                                       } else {
                                           shareCaption = feedPhoto.caption;
                                       }
                                       
                                       SHKItem *item = [SHKItem image:img title:shareCaption];
                                       
                                       // Get the ShareKit action sheet
                                       SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
                                       
                                       // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
                                       // but sometimes it may not find one. To be safe, set it explicitly
                                       [SHK setRootViewController:self];
                                       
                                       // Display the action sheet
                                       [actionSheet showInView:self.view];
                                   }];
                        break;
        }
        case 2:
        {

            NSError* error;
            if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryEditor
                                                 action:kAnalyticsActionEdit
                                                  label:kAnalyticsLabelEditFromGallery
                                                  value:-1
                                              withError:&error]) {
                // Handle error here
            }

            // Edit image
            /*
            UIActionSheet* actions = [[UIActionSheet alloc] initWithTitle:@"Edit..." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Aviary", @"Sketch", @"Caption", nil];
            
            [actions setTag:kEditActionSheetTag];
            [actions showInView:self.view];
            break;*/
            
            // Open the image in Aviary
            NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
            
            
            NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
            [NSURLConnection sendAsynchronousRequest:request 
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage  *img  = [[UIImage alloc] initWithData:data];
                                       
                                       AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage: img];
                                       [editorController setDelegate:self];
                                       [self presentModalViewController:editorController animated:YES];
                                       
                                   }];
            
            break;

        }
        case 3:
        {
            [self openSetAsActionSheet];
            break;
        }
    }
}

-(void)doEditActionSheet: (UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            // Open the image in Aviary
            NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
            
            
            NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
            [NSURLConnection sendAsynchronousRequest:request 
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage  *img  = [[UIImage alloc] initWithData:data];
                                       
                                       AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage: img];
                                       [editorController setDelegate:self];
                                       [self presentModalViewController:editorController animated:YES];

                                   }];
                        
            break;
        }
        case 1: {
            // Open the image in Sketch
            FeedPhoto* feedPhoto = (FeedPhoto*)self.centerPhoto;
            NSString* appId = @"musubi.sketch";
            AppManager* appMgr = [[AppManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
            MApp* app = [appMgr ensureAppWithAppId:appId];
            MObj* obj = feedPhoto.obj;
            [FeedViewController launchApp:app withObj:obj feed:obj.feed andController:_feedViewController popViewController:true];
            
            break;
        }
        case 2: {
            // Open the image in MemeYou
            FeedPhoto* feedPhoto = (FeedPhoto*)self.centerPhoto;
            NSString* appId = @"musubi.memeyou";
            AppManager* appMgr = [[AppManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
            MApp* app = [appMgr ensureAppWithAppId:appId];
            MObj* obj = feedPhoto.obj;
            [FeedViewController launchApp:app withObj:obj feed:obj.feed andController:_feedViewController popViewController:true];
            
            break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch ([actionSheet tag]) {
        case kMainActionSheetTag:
            [self doMainActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
        case kSetAsActionSheetTag:
            [self doSetAsActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
        case kEditActionSheetTag:
            [self doEditActionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
            break;
    }
}

#pragma mark AFPhotoEditorController delegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    PictureObj* obj = [[PictureObj alloc] initWithImage:image andText:@""];
        
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    [_feedViewController sendObj:obj fromApp:app];
    [_feedViewController refreshFeed];
    [[self modalViewController] dismissModalViewControllerAnimated:YES];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    [[self modalViewController] dismissModalViewControllerAnimated:YES];
}
            
@end
