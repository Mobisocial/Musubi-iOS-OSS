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

#import "PictureObjItemCell.h"
#import "ManagedObjFeedItem.h"
#import "ObjHelper.h"
#import "UIViewAdditions.h"
#import "CorralHTTPServer.h"
#import "AFPhotoEditorController.h"
#import "PictureObj.h"
#import "AppManager.h"
#import "Musubi.h"
#import "FeedViewController.h"
#import "MusubiAnalytics.h"
#import "QuartzCore/CALayer.h"
#import "SHK.h"

#define kEditButtonHeight 40

@implementation PictureObjItemCell

@synthesize pictureContainer = _pictureContainer, pictureBack = _pictureBack, pictureFlipButton = _pictureFlipButton;
@synthesize pictureEnhanceButton = _pictureEnhanceButton, pictureShareButton = _pictureShareButton;

+ (void)prepareItem:(ManagedObjFeedItem *)item {
    item.computedData = [UIImage imageWithData: item.managedObj.raw];
}

+ (NSString*) textForItem: (ManagedObjFeedItem*) item {
    NSString* text = nil;
    text = [[item parsedJson] objectForKey: kObjFieldText];
    if (text == nil) {
        text = [[item parsedJson] objectForKey: kObjFieldStatusText];
    }
    return text;
}

+ (CGFloat) pictureHeightForImage:(UIImage*)image {
    if (image.size.width > 250) {
        return (250 / image.size.width) * image.size.height;
    } else {
        return image.size.height;
    }
}

+ (CGFloat) pictureHeightForItem:(ManagedObjFeedItem*) item {
    UIImage* image = item.computedData;
    if(!image)
        image = [UIImage imageNamed:@"error.png"];

    return [PictureObjItemCell pictureHeightForImage:image];
}

+ (CGFloat) textHeightForItem: (ManagedObjFeedItem*) item {
    CGSize size = [[PictureObjItemCell textForItem: (ManagedObjFeedItem*)item] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    
    return size.height;
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem *)item {
    return [PictureObjItemCell pictureHeightForItem:item] + [PictureObjItemCell textHeightForItem:item] + 2*kTableCellSmallMargin;
}

// XXX awkward lazy-loading field with side-effects.
- (UIImageView *)pictureView {
    if (!_pictureView) {
        _pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [_pictureView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [_pictureView setContentMode:UIViewContentModeScaleAspectFit];
        [_pictureView.layer setMasksToBounds:YES];
        [_pictureView.layer setCornerRadius:2];
        [_pictureView.layer setBorderWidth:5.0];
        
        CGFloat nRed=191.0/255.0;
        CGFloat nGreen=185.0/255.0;
        CGFloat nBlue=172/255.0;
        
        UIColor *myColor=[[UIColor alloc]initWithRed:nRed green:nGreen blue:nBlue alpha:1];
        
        [_pictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
        
        
        //Add a shadow by wrapping the avatar into a container
        self.pictureContainer = [[UIView alloc] initWithFrame: _pictureView.frame];
        [self.pictureContainer setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        // setup shadow layer and corner
        self.pictureContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.pictureContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.pictureContainer.layer.shadowOpacity = 0.7;
        self.pictureContainer.layer.shadowRadius = 1.0;
        self.pictureContainer.layer.cornerRadius = 2.0;
        self.pictureContainer.clipsToBounds = NO;
        
        
        self.pictureBack = [[UIView alloc] initWithFrame:self.pictureContainer.frame];
        [self.pictureBack setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self.pictureBack setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"corkBoard.png"]]];
        [self.pictureBack.layer setMasksToBounds:YES];
        [self.pictureBack.layer setCornerRadius:2];
        [self.pictureBack.layer setBorderWidth:5.0];
        [self.pictureBack.layer setBorderColor:[[UIColor whiteColor] CGColor]];
        [self.pictureBack setTag:60];

        //[self.pictureContainer removeAllSubviews];
        //[self.pictureContainer addSubview:pictureBack];
        //[self.pictureView addSubview:self.pictureView];
        //[self.pictureContainer insertSubview:self.pictureBack atIndex: 1];
        
        
        self.pictureFlipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.pictureFlipButton addTarget:self
                   action:@selector(flipPicture:)
         forControlEvents:UIControlEventTouchDown];
        [self.pictureFlipButton setImage:[UIImage imageNamed:@"pencil.png"] forState:UIControlStateNormal];
        [self.pictureFlipButton setBackgroundColor:[UIColor whiteColor]];
        self.pictureFlipButton.alpha = 0.65;
        self.pictureFlipButton.contentMode = UIViewContentModeScaleAspectFit;
        
        // combine the views
        [self.pictureContainer addSubview:self.pictureBack];
        [self.pictureContainer addSubview: self.pictureView];
        [self.pictureContainer addSubview:self.pictureFlipButton];
        //[self.pictureContainer insertSubview:self.pictureFlipButton atIndex:0];
        [self.contentView addSubview: self.pictureContainer];
        
        self.pictureShareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.pictureEnhanceButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.pictureShareButton setHidden:YES];
        [self.pictureEnhanceButton setHidden:YES];
        
        [self.pictureBack addSubview:self.pictureEnhanceButton];
        [self.pictureBack addSubview:self.pictureShareButton];

    }
    
    return _pictureView;
}

- (void)setObject:(ManagedObjFeedItem*)object {
    if (_item != object) {
        [super setObject:object];
        if (object.computedData != nil) {
            self.pictureView.image = object.computedData;
            if ([[self.pictureContainer.subviews objectAtIndex:1] tag] == 60) {
                [self.pictureContainer exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
                [self.pictureEnhanceButton setHidden:YES];
                [self.pictureShareButton setHidden:YES];
            }
        } else {
            self.pictureView.image = [UIImage imageNamed:@"error.png"];
        }
        
        NSString* text = [PictureObjItemCell textForItem:(ManagedObjFeedItem*)object];
        self.detailTextLabel.text = text;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.pictureView.image != nil) {
        CGFloat left = self.detailTextLabel.origin.x;
        CGFloat top = self.timestampLabel.origin.y + self.timestampLabel.height + kTableCellMargin;
        
        float pictureHeight = [PictureObjItemCell pictureHeightForImage:self.pictureView.image];
        self.pictureContainer.frame = CGRectMake(left, top, self.detailTextLabel.frame.size.width, pictureHeight);
        self.pictureView.frame = CGRectMake(0, 0, self.detailTextLabel.frame.size.width, pictureHeight);
        self.pictureBack.frame = CGRectMake(0, 0, self.detailTextLabel.frame.size.width, pictureHeight);
        self.pictureFlipButton.frame = CGRectMake(self.pictureContainer.frame.size.width-45, self.pictureContainer.frame.size.height-40, 35, 30);
        self.pictureFlipButton.layer.cornerRadius = 12;
        self.pictureFlipButton.clipsToBounds = YES;
        
        CGFloat textTop = top + self.pictureView.height;
        CGFloat textHeight = [PictureObjItemCell textHeightForItem:(ManagedObjFeedItem*)_item] + kTableCellSmallMargin;
        self.detailTextLabel.frame = CGRectMake(left, textTop, self.detailTextLabel.width, textHeight);

        
        /*UIView* enhance = [self.contentView viewWithTag:9];
        if (enhance != nil) {
            [enhance removeFromSuperview];
        }*/
        float editTop = textTop + textHeight;
        float editWidth = 80;
        

        [self.pictureEnhanceButton setTitle:@"Enhance" forState:UIControlStateNormal];
        [self.pictureEnhanceButton addTarget:self action:@selector(enhancePicture:) forControlEvents:UIControlEventTouchUpInside];
        [self.pictureEnhanceButton setTag:9];
        self.pictureEnhanceButton.frame = CGRectMake(self.pictureBack.frame.size.width/2-editWidth/2, self.pictureBack.frame.size.height/3-kEditButtonHeight/2, editWidth, kEditButtonHeight);
        
        
        
        [self.pictureShareButton setTitle:@"Share" forState:UIControlStateNormal];
        [self.pictureShareButton addTarget:self action:@selector(sharePicture:) forControlEvents:UIControlEventTouchUpInside];
        [self.pictureShareButton setTag:9];
        self.pictureShareButton.frame = CGRectMake(self.pictureBack.frame.size.width/2-editWidth/2, self.pictureEnhanceButton.frame.origin.y + self.pictureEnhanceButton.frame.size.height + 20, editWidth, kEditButtonHeight);
    }
}

- (void) sharePicture: (id)sender {
    ManagedObjFeedItem* item = self.object;
    NSURL    *aUrl  = [NSURL URLWithString:[CorralHTTPServer urlForRaw:item.managedObj]];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               UIImage  *img  = [[UIImage alloc] initWithData:data];
                               NSString *shareCaption = nil;
                               
                               if (self.detailTextLabel.text == nil) {
                                   shareCaption = @"sent via Musubi";
                               } else {
                                   shareCaption = self.detailTextLabel.text;
                               }
                               
                               SHKItem *item = [SHKItem image:img title:shareCaption];
                               
                               // Get the ShareKit action sheet
                               SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
                               
                               // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
                               // but sometimes it may not find one. To be safe, set it explicitly
                               //[SHK setRootViewController:self];
                               
                               // Display the action sheet
                               [actionSheet showInView:self.superview];
                           }];
}

- (void) flipPicture: (id)sender {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationDuration:0.75];
    
    if ([[self.pictureContainer.subviews objectAtIndex:1] tag] == 60) {
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.pictureContainer cache:YES];
        [self.pictureFlipButton setImage:[UIImage imageNamed:@"pencil.png"] forState:UIControlStateNormal];
        [self.pictureEnhanceButton setHidden:YES];
        [self.pictureShareButton setHidden:YES];
        self.selectionStyle = UITableViewCellSelectionStyleGray;

    } else {
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.pictureContainer cache:YES];
        [self.pictureFlipButton setImage:[UIImage imageNamed:@"backArrow.png"] forState:UIControlStateNormal];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.pictureEnhanceButton setHidden:NO];
        [self.pictureShareButton setHidden:NO];

        

    }
        
    [self.pictureContainer exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
    
    [UIView commitAnimations];
}

- (void) enhancePicture: (id)sender {
    NSError* error;
    if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryEditor
                                         action:kAnalyticsActionEdit
                                          label:kAnalyticsLabelEditFromFeed
                                          value:-1
                                      withError:&error]) {
        // Handle error here
    }


    ManagedObjFeedItem* item = self.object;
    NSURL    *aUrl  = [NSURL URLWithString:[CorralHTTPServer urlForRaw:item.managedObj]];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:aUrl];
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               UIImage  *img  = [[UIImage alloc] initWithData:data];
                               
                               AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage: img];
                               [editorController setDelegate:self];
                               UIViewController* controller = self.contentView.window.rootViewController;
                               [controller presentModalViewController:editorController animated:YES];
                           }];
}

#pragma mark AFPhotoEditorController delegate

// TODO: re-use with Gallery, add options like "share w facebook / twitter"
// and also "enhance again" button to confirmation screen.
- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    ManagedObjFeedItem* parent = self.object;
    PictureObj* obj = [[PictureObj alloc] initWithImage:image andText:@""];
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];

    [FeedViewController sendObj:obj toFeed:parent.managedObj.feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
    [editor dismissModalViewControllerAnimated:YES];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    [editor dismissModalViewControllerAnimated:YES];
}

@end
