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

#import "FeedListViewController.h"
#import "Musubi.h"
#import "FeedListDataSource.h"
#import "FeedListModel.h"
#import "FeedListItem.h"
#import "FeedListStyleSheet.h"
#import "PersistentModelStore.h"
#import "AMQPTransport.h"
#import "AMQPConnectionManager.h"
#import "NearbyViewController.h"

#import "FeedViewController.h"
#import "FirstIdentityViewController.h"

#import "AppManager.h"
#import "IdentityManager.h"
#import "MApp.h"
#import "FeedManager.h"
#import "MFeed.h"

#import "ObjHelper.h"
#import "IntroductionObj.h"
#import "AccountManager.h"
#import "MIdentity.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "MusubiStyleSheet.h"
#import "EulaViewController.h"
#import "MusubiAnalytics.h"
#import "AMQPSenderService.h"
#import "MessageDecodeService.h"

@implementation FeedListViewController {
    NSDate* nextRedraw;
    NSDate* lastRedraw;
    NSDate* nextPendingRedraw;
    NSDate* lastPendingRedraw;
}

@synthesize unclaimed = _unclaimed, ownedId = _ownedId, clipboardObj = _clipboardObj;
@synthesize noFeedsView = _noFeedsView;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // TTTableViewController doesn't implement initWithCoder: so do the required init here
        _lastInterfaceOrientation = self.interfaceOrientation;
        _tableViewStyle = UITableViewStylePlain;
        _clearsSelectionOnViewWillAppear = YES;
        _flags.isViewInvalid = YES;
        

        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(feedUpdated:) name:kMusubiNotificationUpdatedFeed object:nil];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    incomingLabel = [[UILabel alloc] init];
    incomingLabel.font = [UIFont systemFontOfSize: 13.0];
    incomingLabel.text = @"";
    incomingLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5];
    incomingLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    
    self.variableHeightRows = YES;
    //self.tableView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.4];
    UIColor* backgroundColor = _tableViewStyle == UITableViewStyleGrouped
    ? TTSTYLEVAR(tableGroupedBackgroundColor)
    : [MusubiStyleSheet feedTexturedBackgroundColor];
    // : TTSTYLEVAR(tablePlainBackgroundColor);
    if (backgroundColor) {
        _tableView.backgroundColor = backgroundColor;
        self.view.backgroundColor = backgroundColor;
    }
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // We only need to know when a message starts getting decrypted, when it is completely processed
    [[Musubi sharedInstance].transport.connMngr addObserver:self forKeyPath:@"connectionState" options:0 context:nil];
    [[Musubi sharedInstance] addObserver:self forKeyPath:@"transport" options:0 context:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageEncodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageDecodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageDecodeFinished object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationUpdatedFeed object:nil];

}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self->previousStyleSheet = [TTStyleSheet globalStyleSheet];
    //[TTStyleSheet setGlobalStyleSheet:[[FeedListStyleSheet alloc] init]];
    
    NSError *error;
    if (![[GANTracker sharedTracker] trackPageview:kAnalyticsPageFeedList withError:&error]) {
        NSLog(@"error in trackPageview");
    }    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [incomingLabel removeFromSuperview];
    [self.view addSubview:incomingLabel];
    [self updatePending];
    
    // Color
    self.navigationController.navigationBar.tintColor = [((id)[TTStyleSheet globalStyleSheet]) navigationBarTintColor];
    
    AccountManager* accMgr = [[AccountManager alloc] initWithStore:[Musubi sharedInstance].mainStore];    

    // Require EULA
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* eulaAccepted = (NSNumber*)[defaults objectForKey:kMusubiSettingsEulaAccepted];
    if ([eulaAccepted intValue] < kEulaRequiredVersion) {
        [self performSegueWithIdentifier:@"eula" sender:self];
    } else if ([accMgr claimedAccounts].count == 0) {
        // Require an account
        [self performSegueWithIdentifier:@"Welcome" sender:self];
    } else {
        IdentityManager* idMgr = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];    
        BOOL hasIdentWithName = NO;
        for (MIdentity* ident in idMgr.ownedIdentities) {
            if (ident.musubiName) {
                hasIdentWithName = YES;
                break;
            }
        }
        
        if (!hasIdentWithName) {
            // Require an identity
            [self performSegueWithIdentifier:@"FirstIdentity" sender:self];
        } else if (((FeedListDataSource*)self.dataSource).items.count == 0) {
            self.noFeedsView.hidden = NO;
        } else {
            _noFeedsView.hidden = YES;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    [TTStyleSheet setGlobalStyleSheet:self->previousStyleSheet];
//    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationConnectionStateChanged object:nil];    
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationMessageEncodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationMessageDecodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationMessageDecodeFinished object:nil];
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationUpdatedFeed object:nil];
}

- (UIView*) noFeedsView {
    if (!_noFeedsView) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

            _noFeedsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
            _noFeedsView.backgroundColor = [((id)[TTStyleSheet globalStyleSheet]) tablePlainBackgroundColor];
            
    /*        UIImageView* cloud = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloud.png"]];
            cloud.frame = CGRectMake(50, 30, 220, 150);
            cloud.contentMode = UIViewContentModeScaleAspectFit;
            [_noFeedsView addSubview:cloud];*/
            
            UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 120, 220, 30)];
            headerLabel.font = [UIFont boldSystemFontOfSize:16.0];
            headerLabel.textAlignment = UITextAlignmentCenter;
            headerLabel.text = @"No conversations yet :(";
            headerLabel.backgroundColor = [UIColor clearColor];
            [_noFeedsView addSubview:headerLabel];
            
            UITextView* infoLabel = [[UITextView alloc] initWithFrame:CGRectMake(50, 170, 220, 60)];
            infoLabel.font = [UIFont systemFontOfSize: 14];
            infoLabel.textAlignment = UITextAlignmentCenter;
            infoLabel.text = @"Let's pick a few friends to start a chat with!";
            infoLabel.backgroundColor = [UIColor clearColor];
            infoLabel.editable = NO;
            infoLabel.userInteractionEnabled = NO;
            [infoLabel sizeToFit];
            [_noFeedsView addSubview:infoLabel];
            
            TTButton* startButton = [[TTButton alloc] initWithFrame:CGRectMake(60, 320, 200, 50)];
            [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
            [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            [startButton setTitle:@"Start a chat" forState:UIControlStateNormal];
            [_noFeedsView addSubview:startButton];
            
            [startButton addTarget:self action:@selector(showFriendPicker) forControlEvents:UIControlEventTouchUpInside];
            
            [self.view addSubview:_noFeedsView];

        } else {
            // iPad view setup
            _noFeedsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
            _noFeedsView.backgroundColor = [((id)[TTStyleSheet globalStyleSheet]) tablePlainBackgroundColor];
            
            /*        UIImageView* cloud = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloud.png"]];
             cloud.frame = CGRectMake(50, 30, 220, 150);
             cloud.contentMode = UIViewContentModeScaleAspectFit;
             [_noFeedsView addSubview:cloud];*/
            
            UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-(400/2), self.view.frame.size.height/3, 400, 30)];
            headerLabel.font = [UIFont boldSystemFontOfSize:30.0];
            headerLabel.textAlignment = UITextAlignmentCenter;
            headerLabel.text = @"No conversations yet :(";
            headerLabel.backgroundColor = [UIColor clearColor];
            [_noFeedsView addSubview:headerLabel];
            
            UITextView* infoLabel = [[UITextView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-(440/2), self.view.frame.size.height/3+110, 440, 60)];
            infoLabel.font = [UIFont systemFontOfSize: 22];
            infoLabel.textAlignment = UITextAlignmentCenter;
            infoLabel.text = @"Let's pick a few friends to start a chat with!";
            infoLabel.backgroundColor = [UIColor clearColor];
            infoLabel.editable = NO;
            infoLabel.userInteractionEnabled = NO;
            [infoLabel sizeToFit];
            [_noFeedsView addSubview:infoLabel];
            
            TTButton* startButton = [[TTButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-(250/2), self.view.frame.size.height/3+180, 250, 75)];
            [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
            [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            [startButton setTitle:@"Start a chat" forState:UIControlStateNormal];
            [startButton setFont: [UIFont systemFontOfSize: 22]];
            [_noFeedsView addSubview:startButton];
            
            [startButton addTarget:self action:@selector(showFriendPicker) forControlEvents:UIControlEventTouchUpInside];
            
            [self.view addSubview:_noFeedsView];
        }
    }
    
    return _noFeedsView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)createModel {
    self.dataSource = [[FeedListDataSource alloc] init];
}

- (id<UITableViewDelegate>)createDelegate {
    return [[TTTableViewVarHeightDelegate alloc] initWithController:self];
}

- (void) feedUpdated: (NSNotification*) notification {    
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(feedUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }

    if(nextRedraw) {
        return;
    }
    if(lastRedraw) {
        NSDate* now = [NSDate date];
        if([lastRedraw timeIntervalSinceDate:now] < -1) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 11 * NSEC_PER_SEC / 10);
            nextRedraw = [lastRedraw dateByAddingTimeInterval:1];
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                nextRedraw = nil;
                lastRedraw = nil;
                [self feedUpdated:notification];
            });
            return;
        }
    }
    FeedListDataSource* feeds = self.dataSource;
    NSManagedObjectID* oid = notification.object;
    [feeds invalidateObjectId:oid];
    lastRedraw = [NSDate date];
    nextRedraw = nil;
    [self reload];   
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"transport"]) {
        [[Musubi sharedInstance].transport.connMngr addObserver:self forKeyPath:@"connectionState" options:0 context:nil];
    } else {
        [self updatePending];
    }
}


// TODO: This needs to be in some other class, but let's keep it simple for now
- (void)updatePending {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updatePending) withObject:nil waitUntilDone:NO];
        return;
    }
    /*
    if(nextPendingRedraw) {
        return;
    }
    if(lastPendingRedraw) {
        NSDate* now = [NSDate date];
        if([lastPendingRedraw timeIntervalSinceDate:now] < -.25) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 11 * NSEC_PER_SEC / 10);
            nextPendingRedraw = [lastPendingRedraw dateByAddingTimeInterval:.25];
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                nextPendingRedraw = nil;
                lastPendingRedraw = nil;
                [self updatePending];
            });
            return;
        }
    }
    lastPendingRedraw = [NSDate date];
    nextPendingRedraw = nil;
*/
    
    NSString* newText = nil;
    
    AMQPTransport* transport = [Musubi sharedInstance].transport;
    NSString* connectionState = transport ? transport.connMngr.connectionState : @"Starting up...";
    
    if(connectionState) {
        newText = connectionState;
    } else {
        PersistentModelStore* store = [Musubi sharedInstance].mainStore;
        int pending = [Musubi sharedInstance].transport.sender.pending.count;
        
        if (pending > 0) {
            newText = [NSString stringWithFormat: @"Sending %@outgoing message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
        } else {
            pending = [Musubi sharedInstance].decodeService.pending.count;
            if (pending > 0) {
                newText = [NSString stringWithFormat: @"Receiving %@incoming message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
            }
        }
    }
    
    if (newText.length > 0) {
        incomingLabel.hidden = NO;
        [incomingLabel setText: [NSString stringWithFormat:@"  %@", newText]];
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        
        if (incomingLabel.superview == self.view) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [incomingLabel setFrame:CGRectMake(0, 386, 320, 30)];
            } else {
                [incomingLabel setFrame:CGRectMake(0, screenHeight-94, screenWidth, 30)];
            }
        } else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [incomingLabel setFrame:CGRectMake(0, 0, 320, 30)];
            } else {
                [incomingLabel setFrame:CGRectMake(0, 0, screenWidth, 30)];

            }
        }
    } else {
        incomingLabel.hidden = YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowFeed"]) {
        FeedViewController *vc = [segue destinationViewController];
        FeedListItem* item = sender;
        vc.clipboardObj = self.clipboardObj;
        self.clipboardObj = nil;
        vc.newerThan = item.end;
        vc.startingAt = item.start;
        [vc setFeed: item.feed];
        [vc.view addSubview:incomingLabel];
        [vc setDelegate:self];
        [self updatePending];
    } else if ([[segue identifier] isEqualToString:@"CreateNewFeed"]) {
        FriendPickerViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
    } else if ([[segue identifier] isEqualToString:@"FirstIdentity"]) {
        FirstIdentityViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
    }
}

- (void)identityCreated {
    [self showFriendPicker];
}

- (void)newConversation:(id)sender
{
    //TODO: UIActionSheet
    
    UIActionSheet* newConversationPicker = [[UIActionSheet alloc] initWithTitle:@"New conversation" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Create from contacts", @"Join nearby group", nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        
        [newConversationPicker showInView:self.view];
    } else {
        CGRect pictureFrame = CGRectMake(self.view.frame.size.width-40, 0, 1, 1);
        [newConversationPicker showFromRect:pictureFrame inView:self.view animated:YES];
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    switch (buttonIndex) {
        case 0: // create from contact list
        {
            [self showFriendPicker];
            break;
        }
        case 1: // find nearby groups
        {   
            NearbyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NearbyFeeds"];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

- (void) showFriendPicker {
    FriendPickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FriendPicker"];
    [vc setDelegate:self];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    [super didSelectObject:object atIndexPath:indexPath];
    
    FeedListItem* item = [[((FeedListDataSource*)self.dataSource).items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ShowFeed" sender:item];
}

- (void)friendsForNewConversationSelected:(NSArray *)selection {
    [self friendsSelected:selection];
}

- (void) friendsSelected: (NSArray*) selection {
    
    NSMutableArray* unclaimedSelection = [[NSMutableArray alloc] init];
    
    PersistentModelStore* store = [Musubi sharedInstance].mainStore;
    
    AppManager* am = [[AppManager alloc] initWithStore:store];
    MApp* app = [am ensureSuperApp];
    
    FeedManager* fm = [[FeedManager alloc] initWithStore: store];
    MFeed* f = [fm createExpandingFeedWithParticipants:selection];
    
    self.ownedId = [fm ownedIdentityForFeed:f];
    
    // Prompt to invite users if necessary
    for (MIdentity* mId in selection) {
        if (mId.claimed == NO && mId.type == 0) {
            [unclaimedSelection addObject:mId];
        }
    }
    
    if ([unclaimedSelection count] > 0 && [MFMailComposeViewController canSendMail]) {
        self.unclaimed = unclaimedSelection;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invite Friends?" 
                                                        message:@"Some of the friends in this feed aren't using Musubi yet. Would you like to send an invitation email?" 
                                                       delegate:self 
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes",nil];
        [alert show];  
    }
    
    Obj* invitationObj = [[IntroductionObj alloc] initWithIdentities:selection];
    [FeedViewController sendObj: invitationObj toFeed:f fromApp:app usingStore: store];
    
    [self.navigationController popViewControllerAnimated:NO];
    [self performSegueWithIdentifier:@"ShowFeed" sender:[[FeedListItem alloc] initWithFeed:f after:nil before:nil]];
}

#pragma UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSError* error;
    if (buttonIndex == 0) {
        if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionInvite label:kAnalyticsLabelNo value:nil withError:&error]) {
            // error
        }
    } else if (buttonIndex == 1 && self.ownedId != nil) {
        if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryApp action:kAnalyticsActionInvite label:kAnalyticsLabelYes value:nil withError:&error]) {
            // error
        }

        NSString* nameForURL = [self.ownedId.name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* principalForURL = [self.ownedId.principal stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* typeForURL = [NSString stringWithFormat:@"%d", self.ownedId.type];
        
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        
        controller.mailComposeDelegate = self;
        
        NSMutableArray* recipients = [[NSMutableArray alloc] init];
        
        for (MIdentity* mId in self.unclaimed) {
            [recipients addObject:[NSString stringWithFormat:@"%@ <%@>", mId.name, mId.principal]]; 
        }
        
        [controller setSubject:@"Please join my conversation in Musubi"];

        [controller setMessageBody:[NSString stringWithFormat:@"I'd like to chat with you securely via <a href='http://musubi.us/intro?n=%@&t=%@&p=%@'>Musubi</a>.", nameForURL, typeForURL, principalForURL] isHTML:YES];
        
        [controller setToRecipients:recipients];
        
        if (controller) [self presentModalViewController:controller animated:YES];
    }
    
    self.unclaimed = nil;
    self.ownedId = nil;
}

- (void) setClipboardObj:(Obj *)obj {
    _clipboardObj = obj;
}

#pragma MFMailComposeViewController Delegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultSent) {
        NSLog(@"Invitation email sent.");
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
 
