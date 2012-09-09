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

#import "FeedViewController.h"
#import "ProfileViewController.h"
#import "PictureOverlayViewController.h"
#import "FeedSettingsViewController.h"
#import "CheckinViewController.h"
#import "FeedPhotoViewController.h"
#import "FeedDataSource.h"
#import "FeedModel.h"
#import "FeedItem.h"
#import "Musubi.h"
#import "PersistentModelStore.h"
#import "APNPushManager.h"
#import "LocationViewController.h"

#import "FeedManager.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "ObjHelper.h"
#import "LikeObj.h"
#import "PictureObj.h"
#import "StatusObj.h"
#import "LocationObj.h"
#import "StoryObj.h"
#import "FeedNameObj.h"
#import "IntroductionObj.h"

#import "StoryObjItemCell.h"
#import "PictureObjItemCell.h"
#import "LocationObjItemCell.h"

#import "AppManager.h"
#import "MApp.h"

#import "MusubiStyleSheet.h"
#import "Three20/Three20.h"
#import "Three20UI/UIViewAdditions.h"
#import "StatusTextView.h"
#import "DejalActivityView.h"
#import "MIdentity.h"
#import "HTMLAppViewController.h"
#import "FeedPhoto.h"
#import "FeedPhotoViewController.h"
#import "MusubiAnalytics.h"

#import "IndexedTTTableView.h"

@implementation FeedViewController

@synthesize newerThan = _newerThan;
@synthesize startingAt = _startingAt;
@synthesize feed = _feed;
@synthesize delegate = _delegate;
@synthesize audioRVC = _audioRVC;
@synthesize popover = _popover;
@synthesize clipboardObj = _clipboardObj;
@synthesize getPictureViewController = _getPictureViewController;
@synthesize takePictureViewController = _takePictureViewController;
@synthesize picturePhase2ViewController = _picturePhase2ViewController;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // TTTableViewController doesn't implement initWithCoder: so do the required init here
        _lastInterfaceOrientation = self.interfaceOrientation;
        _tableViewStyle = UITableViewStylePlain;
        _clearsSelectionOnViewWillAppear = YES;
        _flags.isViewInvalid = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsMultipleSelection = YES;
    [self createModel];

    NSError *error;
    if (![[GANTracker sharedTracker] trackPageview:kAnalyticsPageFeed withError:&error]) {
        NSLog(@"error in trackPageview");
    }

    if (self.clipboardObj != nil) {
        AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        MApp* app = [am ensureSuperApp];
        [self sendObj:self.clipboardObj fromApp:app];
        self.clipboardObj = nil;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (UITableView*)tableView {
    if (nil == _tableView) {
        _tableView = [[IndexedTTTableView alloc] initWithFrame:self.view.bounds style:_tableViewStyle];
        _tableView.autoresizingMask =  UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleHeight;
        
        UIColor* separatorColor = _tableViewStyle == UITableViewStyleGrouped
        ? TTSTYLEVAR(tableGroupedCellSeparatorColor)
        : TTSTYLEVAR(tablePlainCellSeparatorColor);
        if (separatorColor) {
            _tableView.separatorColor = separatorColor;
        }
        
        _tableView.separatorStyle = _tableViewStyle == UITableViewStyleGrouped
        ? TTSTYLEVAR(tableGroupedCellSeparatorStyle)
        : TTSTYLEVAR(tablePlainCellSeparatorStyle);
        
        UIColor* backgroundColor = _tableViewStyle == UITableViewStyleGrouped
        ? TTSTYLEVAR(tableGroupedBackgroundColor)
        : [MusubiStyleSheet feedTexturedBackgroundColor];
       // : TTSTYLEVAR(tablePlainBackgroundColor);
        if (backgroundColor) {
            _tableView.backgroundColor = backgroundColor;
            self.view.backgroundColor = backgroundColor;
        }
        [self.view addSubview:_tableView];
    }
    return _tableView;
}


- (void)loadView {
    [super loadView];
    FeedManager* feedManager = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    self.title = [feedManager identityStringForFeed: _feed];
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Musubi"
                                     style:UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];

    CGRect bounds = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height - 43);
    self.tableView.frame = bounds;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.variableHeightRows = YES;
    
    postView.backgroundColor = [UIColor clearColor];
    postView.style = [MusubiStyleSheet bottomPanelStyle];
    
    TTView* statusFieldBox = [[TTView alloc] initWithFrame:CGRectMake(44, 6, postView.frame.size.width - 115, 32)];
    statusFieldBox.backgroundColor = [UIColor clearColor];
    statusFieldBox.style = [MusubiStyleSheet textViewBorder];
    
    
    [postView addSubview: statusFieldBox];    
    [self.view bringSubviewToFront:postView];
    

    statusField = [[StatusTextView alloc] initWithFrame:CGRectMake(0, 0, statusFieldBox.width, statusFieldBox.height)];
    statusField.font = [UIFont systemFontOfSize:15.0];
    statusField.backgroundColor = [UIColor clearColor];
    statusField.delegate = self;
    [statusFieldBox addSubview: statusField];

    [sendButton setBackgroundColor:[UIColor clearColor]];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    
    [sendButton setStyle:[MusubiStyleSheet embossedButton:UIControlStateNormal] forState:UIControlStateNormal];
    [sendButton setStyle:[MusubiStyleSheet embossedButton:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [sendButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
    
    //[sendButton setStyle:[TTSTYLESHEET toolbarButtonForState:UIControlStateNormal shape:shape tintColor:tintColor font:nil] forState:UIControlStateNormal];
    //[sendButton setStyle:[TTSTYLESHEET toolbarButtonForState:UIControlStateNormal shape:shape tintColor:tintColor font:nil] forState:UIControlStateHighlighted];

}

- (AudioRecorderViewController*)audioRVC
{
    if (!_audioRVC) {
        _audioRVC = [[AudioRecorderViewController alloc] init];
        _audioRVC.delegate = self;
//        _audioRVC.backgroundView = self.view;
    }
    return _audioRVC;
}

- (void)changeName
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Conversation Name" message:@"Set the name for this feed" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 1)
        return;
    NSString* name = [alertView textFieldAtIndex:0].text;
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(!name || !name.length)
        return;
    
    FeedNameObj* name_change = [[FeedNameObj alloc] initWithName:name andThumbnail:nil];
    
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    
    [self sendObj:name_change fromApp:app];
    [(UIButton*)self.navigationItem.titleView setTitle:name forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Color
    self.navigationController.navigationBar.tintColor = [((id)[TTStyleSheet globalStyleSheet]) navigationBarTintColor];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activated:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(feedUpdated:) name:kMusubiNotificationUpdatedFeed object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(reloadObj:) name:kMusubiNotificationObjSent object:nil];

    [self resetUnreadCount];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationUpdatedFeed object:nil];
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationObjSent object:nil];

}

- (void)createModel {
    self.dataSource = [[FeedDataSource alloc] initWithFeed:_feed  messagesNewerThan:_newerThan unreadCount:_feed.numUnread];
}

- (id<UITableViewDelegate>)createDelegate {
    return [[FeedViewTableDelegate alloc] initWithController:self];
}

- (BOOL)shouldLoadMore {
    return [(FeedModel*)self.model hasMore];
}

- (void) scrollToBottomAnimated: (BOOL) animated {
    FeedDataSource* source = (FeedDataSource*)self.dataSource;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(source.items.count - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void) feedUpdated: (NSNotification*) notification {    
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(feedUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    if ([((NSManagedObjectID*)notification.object) isEqual:_feed.objectID]) {
        [self refreshFeed];
    }
}


- (void) reloadObj: (NSNotification*) notification {
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(reloadObj:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    if ([notification.object isKindOfClass:[NSManagedObjectID class]]) {
        NSManagedObjectID* objId = (NSManagedObjectID*)notification.object;
        MObj* obj = (MObj*)[[Musubi sharedInstance].mainStore.context existingObjectWithID:objId error:nil];
        if (obj) {
            [(FeedDataSource*)self.dataSource loadItemsForObjs:[NSArray arrayWithObject:obj] inTableView: self.tableView];
            NSIndexPath* ip = [(FeedDataSource*)self.dataSource indexPathForObj:obj];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:ip] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void) refreshFeed {
    FeedModel* model = (FeedModel*)self.model;
    CGPoint old = self.tableView.contentOffset;
    BOOL last = [self isLastRowVisible];
    [model loadNew];
    if(last)
        [self scrollToBottomAnimated:NO];
    else
        self.tableView.contentOffset = old;
    [self resetUnreadCount];
}
- (BOOL)isLastRowVisible
{
    FeedDataSource* source = (FeedDataSource*)self.dataSource;
    return (source.items.count - 1 == [self lastVisibleRow]);
}

- (int)lastVisibleRow
{
    int row = -1;
    NSArray* visible = self.tableView.indexPathsForVisibleRows;
    for(NSIndexPath* i in visible) {
        if(i.row > row)
            row = i.row;
    }
    return row;
}
- (void)activated: (NSNotification*) notification
{
    [self resetUnreadCount];
}

- (void) resetUnreadCount {
    if([UIApplication sharedApplication].backgroundTimeRemaining < 10000)
        return;
    if (_feed.numUnread > 0) {
        [_feed setNumUnread:0];
        [[Musubi sharedInstance].mainStore save];
        [APNPushManager resetLocalUnreadInBackgroundTask:NO];
        
        // Refresh the feed list view
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationUpdatedFeed object:_feed.objectID];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
CGFloat desiredHeight = [[NSString stringWithFormat: @"%@\n", textView.text] sizeWithFont:textView.font constrainedToSize:CGSizeMake(textView.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap].height + 13; // 13 is the border + margin, etc.
    
    CGFloat diff = desiredHeight - textView.height;
        
    if (diff != 0 && self.tableView.height - diff > 80) {
        self.tableView.height -= diff;
        postView.frame = CGRectMake(0, self.tableView.height, postView.width, postView.height + diff);
        textView.height += diff;
        textView.superview.height += diff;
        
        
        sendButton.frame = CGRectMake(sendButton.frame.origin.x, postView.height - sendButton.height - 2, sendButton.width, sendButton.height);
        actionButton.frame = CGRectMake(actionButton.frame.origin.x, postView.height - actionButton.height - 6, actionButton.width, actionButton.height);
    }
}

/// ACTIONS

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    /*
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"];
    NSNumber* height = [NSNumber numberWithInt:[output intValue]];
    [cellHeights setObject:height forKey:[NSNumber numberWithInteger:[webView tag]]];
    
    CGRect frame = [webView frame];
    [webView setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [height floatValue])];
    
    [self.tableView beginUpdates];
    [self.tableView setNeedsLayout];
    [self.tableView endUpdates];*/
}

- (void) keyboardWillShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIWindow *window = [[[UIApplication sharedApplication] windows]objectAtIndex:0];
    UIView *mainSubviewOfWindow = window.rootViewController.view;
    CGRect keyboardFrameConverted = [mainSubviewOfWindow convertRect:keyboardFrame fromView:window];

    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];

    
    [self.tableView setFrame: CGRectMake(0, 0, self.tableView.frame.size.width, self.view.frame.size.height - postView.frame.size.height - keyboardFrameConverted.size.height + 1)]; // +1 to hide bottom border
    [postView setFrame:CGRectMake(0, self.tableView.frame.size.height - 1, postView.frame.size.width, postView.frame.size.height)]; // -1 to hide bottom border
    
    [UIView commitAnimations]; 

    [self scrollToBottomAnimated:NO];
}

- (void) keyboardWillHide:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];

    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    [postView setFrame:CGRectMake(0, self.view.frame.size.height - postView.frame.size.height, postView.frame.size.width, postView.frame.size.height)];
    [self.tableView setFrame: CGRectMake(0, 0, self.tableView.frame.size.width, postView.frame.origin.y + 1)]; // +1 to hide bottom border
    
    [UIView commitAnimations]; 

}
- (void) hideKeyboard {
    
    [statusField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}


- (IBAction)sendMessage:(id)sender {
    //[self hideKeyboard];
    
    if (statusField.text.length > 0) {
        NSMutableString* text = [NSMutableString stringWithString:[statusField text]];
        NSURL *urlInString = [self getURLFromString:text];
        
        if (urlInString){
            [DejalBezelActivityView activityViewForView:self.view withLabel:@"Downloading Story Information" width:200];
            
            dispatch_queue_t fetchQueue = dispatch_queue_create("storyobj meta information download", NULL);
            dispatch_async(fetchQueue, ^{
                StoryObj *story = [[StoryObj alloc] initWithURL:urlInString text:text];
                dispatch_async(dispatch_get_main_queue(), ^{                    
                    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
                    MApp* app = [am ensureSuperApp];
                    
                    [self sendObj:story fromApp:app];
                    [statusField setText:@""];
                    [self refreshFeed];
                    [DejalBezelActivityView removeViewAnimated:YES];

                });
            });
            dispatch_release(fetchQueue);  
                        
        }else {
            StatusObj* status = [[StatusObj alloc] initWithText: [statusField text]];
            
            AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
            MApp* app = [am ensureSuperApp];
            
            [self sendObj:status fromApp:app];
            
            [statusField setText:@""];
            [self refreshFeed];
        }
        
    }
}

- (NSURL*) getURLFromString:(NSMutableString*) source{
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:source options:0 range:NSMakeRange(0, [source length])];
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeLink) {
            [source replaceCharactersInRange:match.range withString:@" "];
            NSURL *url = [match URL];
            NSLog(@"found URL: %@", url);
            return url;
        }
    }
    return nil;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self hideKeyboard];
    [statusField setText:@""];
    [self textViewDidChange:statusField];
    [self refreshFeed];
}

- (IBAction)commandButtonPushed: (id) sender {
    UIActionSheet* commandPicker = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Picture From Album", @"Record Audio", @"Sketch", @"Check-in", nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

        [commandPicker showInView:mainView];
    } else {
        CGRect pictureFrame = CGRectMake(15, self.view.frame.size.height-10, 1, 60);
        [commandPicker showFromRect:pictureFrame inView:self.view animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSError *error;

    switch (buttonIndex) {
        case 0: // take picture
        {
            if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionFeedAction label:kAnalyticsLabelFeedActionCamera value:nil withError:&error]) {
                // error
            }

            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                [self showPhotoTaker:YES];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't have a camera" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            break;
        }
        case 1: // existing picture
        {   
            if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionFeedAction label:kAnalyticsLabelFeedActionGallery value:nil withError:&error]) {
                // error
            }

            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                [self showPhotoPicker];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't support the photo library" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            break;
        }
        case 2: // Audio
        {
            if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionFeedAction label:kAnalyticsLabelFeedActionRecordAudio value:nil withError:&error]) {
                // error
            }

            [self hideKeyboard];
            [self slideSubView:self.audioRVC.view];
            break;
        }
        case 3: // app (sketch)
        {
            if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionFeedAction label:kAnalyticsLabelFeedActionSketch value:nil withError:&error]) {
                // error
            }

            NSString* appId = @"musubi.sketch";
            AppManager* appMgr = [[AppManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
            MApp* app = [appMgr ensureAppWithAppId:appId];

            NSMutableArray* userKeys = [NSMutableArray array];
            FeedManager* feedMgr = [[FeedManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
            for (MIdentity* ident in [feedMgr identitiesInFeed:_feed]) {
                [userKeys addObject: ident.principalHash];
                
                if ([userKeys count] >= 2)
                    break;
            }
            
            NSMutableDictionary* appDict = [[NSMutableDictionary alloc] init];
            [appDict setObject:userKeys forKey:@"membership"];
            
            // don't need to send an obj to launch an app.
            /*
            Obj* obj = [[Obj alloc] initWithType:@"appstate"];
            [obj setData:appDict];
            MObj* mObj = [ObjHelper sendObj:obj toFeed:_feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
            */
            
            [FeedViewController launchApp: app withObj:nil feed: _feed andController:self popViewController:false];
            break;
        }
        case 4: // check in
        {
            if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionFeedAction label:kAnalyticsLabelFeedActionCheckIn value:nil withError:&error]) {
                // error
            }

            [self performSegueWithIdentifier:@"ShowCheckinController" sender:_feed];
            break;
        }
    }
}

- (void)slideSubView:(UIView*)subView
{
    subView.frame = CGRectMake(0, 480, 320, 100); 
    [self.view addSubview:subView];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.3];
    subView.frame = [UIScreen mainScreen].bounds;
    [UIView commitAnimations];
}

- (void)userChoseAudioData:(NSURL *)file withDuration:(int)seconds
{
    NSLog(@"Audio recorded at %@", [file description]);
    
    NSData   *deletethis = [NSData dataWithContentsOfURL:file];
    NSLog(@"Audio size is %d bytes", [deletethis length]);
    
    VoiceObj* audio = [[VoiceObj alloc] initWithURL:file withData:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:seconds], kObjFieldVoiceDuration, @"audio/x-caf", kMimeField, nil]];
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    [self sendObj:audio fromApp:app];
    //    [self dismissModalViewControllerAnimated:YES];    
    [self.audioRVC.view removeFromSuperview];
    [self refreshFeed];
}

+ (void)launchApp: (MApp*) app withObj: (MObj*) obj feed: (MFeed*)feed andController: (UIViewController*) controller popViewController: (BOOL) shouldPop { 
    HTMLAppViewController* appViewController = (HTMLAppViewController*) [[controller storyboard] instantiateViewControllerWithIdentifier:@"AppView"];
    appViewController.app = app;
    appViewController.feed = feed;
    appViewController.obj = obj;
    
    // If we are editing an existing gallery photo, we should pop the TTPhotoViewController off the
    // stack so that clicking "Post" from MusuSketch will return the user to the feed view
    if (shouldPop) {
        [[controller navigationController] popViewControllerAnimated:false];
    }
    [[controller navigationController] pushViewController:appViewController animated:YES];
}

- (void)friendsSelected:(NSArray *)selection {
    PersistentModelStore* store = [Musubi sharedInstance].mainStore;

    if (selection.count == 0) {
        return;
    }

    FeedManager* fm = [[FeedManager alloc] initWithStore:store];
    AppManager* am = [[AppManager alloc] initWithStore:store];
    MApp* app = [am ensureSuperApp];
    
    //add members to feed
    [fm attachMembers:selection toFeed:_feed];
    //send an introduction
    Obj* invitationObj = [[IntroductionObj alloc] initWithIdentities:selection];
    [self sendObj: invitationObj fromApp:app];
    
    [self.navigationController popViewControllerAnimated:NO]; // back to the feed
}

- (void) changedName:(NSString *) name {
    [(UIButton*)self.navigationItem.titleView setTitle:name forState:UIControlStateNormal];
    [self refreshFeed];
}

- (void) reloadFeed {
    [self refreshFeed];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddPeopleSegue"]) {
        FriendPickerViewController *vc = segue.destinationViewController;
        FeedManager* fm = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        vc.pinnedIdentities = [NSSet setWithArray:[fm identitiesInFeed:_feed]];
        vc.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"ShowProfile"]) {
        ProfileViewController *vc = [segue destinationViewController];
        [vc setIdentity: (MIdentity*) sender];
        [vc setDelegate:self];
        //[vc.view addSubview:incomingLabel];
        //[self updatePending:nil];
    }
    else if ([[segue identifier] isEqualToString:@"ShowFeedSettings"]) {
        FeedSettingsViewController *vc = [segue destinationViewController];
        [vc setFeed: _feed];
        [vc setDelegate:self];
        //[vc.view addSubview:incomingLabel];
        //[self updatePending:nil];
    }
    else if ([[segue identifier] isEqualToString:@"ShowCheckinController"]) {
        CheckinViewController *vc = [segue destinationViewController];
        [vc setFeed: _feed];
        [vc setDelegate: self];
    }
    else if ([[segue identifier] isEqualToString:@"ShowLocationController"]) {
        LocationViewController *vc = [segue destinationViewController];
        [vc setManagedObjFeedItem:(ManagedObjFeedItem*) sender];
        //NSLog(@"show location controller");
    }
}

- (void)selectedFeed:(MFeed *)feed {
    [self setFeed:feed];
    [self invalidateModel];
    [self createModel];
    [self reload];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)newConversation:(MIdentity*) ident {
    [self.navigationController popViewControllerAnimated:NO];
    NSArray* selection = [NSArray arrayWithObject:ident];
    [_delegate friendsForNewConversationSelected:selection];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (MObj*) sendObj:(Obj *)obj fromApp: (MApp*) app {
    return [FeedViewController sendObj:obj toFeed:_feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
}

+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed fromApp: (MApp*) app usingStore: (PersistentModelStore*) store {
    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionSendObj label:obj.type value:nil withError:&error]) {
        // error
    }

    @try {
        MObj* res = [ObjHelper sendObj:obj toFeed:feed fromApp:app usingStore:store];
        return res;
    } @catch (NSException* e) {
        NSString* msg = nil;
        
        if ([e.name isEqualToString:kMusubiExceptionFeedWithoutOwnedIdentity]) {
            msg = @"You have disconnected your account in this feed. To send messages, please reconnect your account on the settings page";
        } else {
            msg = @"Something went wrong, please retry";
        }
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Sorry" message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    
    return nil;
}
////////////
//Methods for the camera overlay view
////////
- (UIToolbar*) cameraToolbar {
    UIToolbar* toolBar;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        toolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, screenHeight-55, 320, 55)];
        toolBar.barStyle = UIBarStyleBlackOpaque;
        toolBar.items = self.cameraToolbarItems;
    } else {
        toolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, screenHeight-55, screenWidth, 55)];
        toolBar.barStyle = UIBarStyleBlackOpaque;
        toolBar.items = self.cameraToolbarItems;
    }
    return toolBar;
}

- (void)shootPicture:(id)sender
{
    [_takePictureViewController takePicture];
}
- (void)cancelPicture:(id)sender
{
    [self imagePickerControllerDidCancel:_takePictureViewController];
}

- (NSArray*)cameraToolbarItems
{
    UIImage* cameraImage = [UIImage imageNamed:@"camera.png"];
    UIImage* cancelImage = [UIImage imageNamed:@"cancel.png"];

    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cameraButton addTarget:self action:@selector(shootPicture:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton addTarget:self action:@selector(cancelPicture:) forControlEvents:UIControlEventTouchUpInside];
    [cameraButton setImage:cameraImage forState:UIControlStateNormal];
    [cancelButton setImage:cancelImage forState:UIControlStateNormal];
    cameraButton.frame = CGRectMake(0,0, cameraImage.size.width, cameraImage.size.height);
    cancelButton.frame = CGRectMake(0,0, cancelImage.size.width, cancelImage.size.height);
    cameraButton.showsTouchWhenHighlighted = YES; // makes it highlight like normal
    cancelButton.showsTouchWhenHighlighted = YES;


    UIBarButtonItem *cameraBarButton = [[UIBarButtonItem alloc] initWithCustomView:cameraButton];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];

    return [NSArray arrayWithObjects:
        cancelBarButton,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace  target:nil action:nil],
        cameraBarButton,
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace  target:nil action:nil],
            nil];
}
//////////
// methods to allocate the ui picker controllers
// weird state tracking is done by checking if a particular controller
// is set
/////////
//lazy initialization, dunno if it is actually necessary
- (UIImagePickerController *)getPictureViewController
{
    if(_getPictureViewController) return _getPictureViewController;
    _getPictureViewController = [[UIImagePickerController alloc] init];
    _getPictureViewController.delegate = self;
    _getPictureViewController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    return _getPictureViewController;
}
//lazy initialization, dunno if it is actually necessary
- (UIImagePickerController *)takePictureViewController
{
    if(_takePictureViewController) return _takePictureViewController;
    _takePictureViewController = [[UIImagePickerController alloc] init];
    
    _takePictureViewController.delegate = self;
    _takePictureViewController.sourceType = UIImagePickerControllerSourceTypeCamera;
    _takePictureViewController.showsCameraControls = NO;
    _takePictureViewController.cameraOverlayView = [self cameraToolbar];
    
    return _takePictureViewController;
}
/////////
// after picking a picture, you show it with edit/caption
///////
- (PictureOverlayViewController*)picturePhase2ViewController
{
    if(_picturePhase2ViewController) return _picturePhase2ViewController;
    _picturePhase2ViewController = [[PictureOverlayViewController alloc] init];
    
    _picturePhase2ViewController.delegate = self;
    return _picturePhase2ViewController;
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];

    //close out the picker/pop up
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:NO completion:NULL];
    } else {
        if(picker == _getPictureViewController) {
            [self.popover dismissPopoverAnimated:YES];
        } else if(picker == _takePictureViewController) {
            [self dismissViewControllerAnimated:NO completion:NULL];
        }
    }
    
    PictureOverlayViewController* overlay = self.picturePhase2ViewController;
    overlay.image = image;
    if(picker == _getPictureViewController) {
        overlay.auxiliaryTitle = @"Cancel";
    } else if(picker == _takePictureViewController) {
        overlay.auxiliaryTitle = @"Retake";
    }
    //show the new one
    
    [self presentViewController:overlay animated:(_takePictureViewController == nil) completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    //close out the picker/pop up
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self dismissViewControllerAnimated:NO completion:NULL];
    } else {
        if(picker == _getPictureViewController) {
            [self.popover dismissPopoverAnimated:YES];
        } else if(picker == _takePictureViewController) {
            [self dismissViewControllerAnimated:NO completion:NULL];
        }
    }
    //just free it up
    _getPictureViewController = nil;
    _takePictureViewController = nil;
    _picturePhase2ViewController = nil;
}
//retake/cancel are different depending on the picture source
- (void)picturePickerAuxiliaryButton:(PictureOverlayViewController *)overlay
{
    if(_takePictureViewController) {
        [self dismissViewControllerAnimated:NO completion:NULL];
        [self showPhotoTaker:NO];
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    //clean up
    _getPictureViewController = nil;
    _takePictureViewController = nil;
    _picturePhase2ViewController = nil;
}
//send it
//TODO: if edited save in gallery
- (void)picturePickerFinished:(PictureOverlayViewController *)overlay withPicture:(UIImage *)picture withCaption:(NSString *)caption {
    //clear the controller out
    [self dismissViewControllerAnimated:YES completion:NULL];

    if (_takePictureViewController || overlay.edited) {
        //save to the album
        UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil);
    }

    //just free it up
    _getPictureViewController = nil;
    _takePictureViewController = nil;
    _picturePhase2ViewController = nil;

    //post the picture
    PictureObj* obj = [[PictureObj alloc] initWithImage:picture andText:caption];
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    
    [self sendObj:obj fromApp:app];
    
    [self refreshFeed];
    
}
- (void)showPhotoTaker:(BOOL)animated {
    //clean up
    _getPictureViewController = nil;
    _takePictureViewController = nil;
    _picturePhase2ViewController = nil;
    [self presentViewController:self.takePictureViewController animated:animated completion:NULL];
}
- (void)showPhotoPicker {
    //clean up
    _getPictureViewController = nil;
    _takePictureViewController = nil;
    _picturePhase2ViewController = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:self.getPictureViewController animated:YES completion:NULL];
    } else {
        _popover=[[UIPopoverController alloc] initWithContentViewController:self.getPictureViewController];
        _popover.delegate=self;

        CGRect frame = CGRectMake(15, self.view.frame.size.height-10, 1, 60);

        [_popover presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
}

@end



@implementation FeedViewTableDelegate

@synthesize gallery = _gallery;
@synthesize feedViewController = _feedViewController;

- (void)likedAtIndexPath:(NSIndexPath *)indexPath {
    FeedItem* item = [self.controller.dataSource tableView:self.controller.tableView objectForRowAtIndexPath:indexPath];
    
    // Commented out by Will Wu since we want to allow people to like something multiple times
    //if (!item.iLiked) {
        LikeObj* like = [[LikeObj alloc] initWithObjHash: item.obj.universalHash];
                
        AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        MApp* app = [am ensureSuperApp];
        
        FeedViewController* controller = (FeedViewController*) self.controller;
        
        MObj* mObj = [controller sendObj:like fromApp:app];
        //[like processObjWithRecord: mObj];
        
        [(FeedModel*)self.controller.model loadObj:item.obj.objectID];
    //}
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [(FeedViewController*)self.controller hideKeyboard];
    //[searchBar resignFirstResponder];
}
- (void)profilePictureButtonPressedAtIndexPath:(NSIndexPath *)indexPath {
    FeedViewController* controller = (FeedViewController*) self.controller;
    
    FeedItem* item = [self.controller.dataSource tableView:self.controller.tableView objectForRowAtIndexPath:indexPath];
    [controller performSegueWithIdentifier:@"ShowProfile" sender:item.obj.identity];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [(FeedViewController*)self.controller hideKeyboard];
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FeedItemCell* cell = (FeedItemCell*)[tableView cellForRowAtIndexPath:indexPath];

    if (indexPath.row == 0 && [cell isKindOfClass:[TTTableMoreButtonCell class]]) {
        TTTableMoreButton* moreLink = [(TTTableMoreButtonCell *)cell object];
        moreLink.isLoading = YES;
        [(TTTableMoreButtonCell *)cell setAnimating:YES];
    }else if([cell isKindOfClass:[StoryObjItemCell class]]){
        StoryObjItemCell* socell = (StoryObjItemCell*)cell;
        if(!socell.url)
            return;
        NSURL* url = [NSURL URLWithString:socell.url];
        if(!url)
            return;
        [[UIApplication sharedApplication] openURL:url];
    } else if ([cell isKindOfClass:[PictureObjItemCell class]]) {
        if ([[((PictureObjItemCell*)cell).pictureContainer.subviews objectAtIndex:1] tag] != 60) {
            ManagedObjFeedItem* objItem = cell.object;
            FeedPhoto* photo = [[FeedPhoto alloc] initWithObj:objItem.managedObj];
            NSString *callback = [objItem.parsedJson objectForKey:kFieldCallback];
            if (callback != nil) {
              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:callback]];
            } else {
              self.feedViewController = (FeedViewController*)self.controller;
              self.gallery = [[FeedPhotoViewController alloc] initWithFeedViewController:self.feedViewController andPhoto:photo];
              [[self.controller navigationController] pushViewController:self.gallery animated:true];
            }
        }
    } else if ([cell isKindOfClass:[LocationObjItemCell class]]) {
        ManagedObjFeedItem* objItem = cell.object;
        
        FeedViewController* controller = (FeedViewController*) self.controller;
        [controller performSegueWithIdentifier:@"ShowLocationController" sender:objItem];
       /* LocationObj* photo = [[FeedPhoto alloc] initWithObj:objItem.managedObj];
        
        self.feedViewController = (FeedViewController*)self.controller;
        
        self.gallery = [[FeedPhotoViewController alloc] initWithFeedViewController:self.feedViewController andPhoto:photo];
        
        [[self.controller navigationController] pushViewController:self.gallery animated:true];*/
    }
    
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    MFeed* feed = [((FeedListDataSource*)self.dataSource) feedForIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ShowFeedCustom" sender:feed];
}*/



@end
