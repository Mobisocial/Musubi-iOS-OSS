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

#import "FeedSettingsViewController.h"
#import "FriendPickerViewController.h"
#import "FeedNameCell.h"
#import "FeedManager.h"
#import "MFeed.h"
#import "Musubi.h"
#import "FeedNameObj.h"
#import "AppManager.h"
#import "ObjHelper.h"
#import "GpsBroadcaster.h"
#import "NearbyFeed.h"
#import "DejalActivityView.h"
#import "FeedViewController.h"
#import "NamePictureCell.h"
#import "MusubiStyleSheet.h"

@interface FeedSettingsViewController ()

@end

@implementation FeedSettingsViewController {
    UITextField* broadcastTextField;
    NSMutableArray* pending;
}

@synthesize feed = _feed;
@synthesize feedManager = _feedManager;
@synthesize delegate = _delegate;
@synthesize thumb = _thumb;


#define kFeedNameTag 0
#define kBroadcastPassword 1

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _feedManager = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)loadView {
    [super loadView];

    self.view.backgroundColor = [MusubiStyleSheet feedTexturedBackgroundColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pending = [NSMutableArray array];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)pictureClicked:(id)sender {    
    /*UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [picker setDelegate:self];
    
    [self presentModalViewController:picker animated:YES];*/
    
    UIActionSheet* commandPicker = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Picture From Album", nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [commandPicker showInView:self.view];
    } else {
        
        NamePictureCell* cell = (NamePictureCell*) [self.tableView dequeueReusableCellWithIdentifier:@"NamePictureCell"];
        
        CGRect pictureFrame = CGRectMake(28, 50, 100, 100);
        [commandPicker showFromRect:pictureFrame inView:self.view animated:YES];
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
                    
                    NamePictureCell* cell = (NamePictureCell*) [self.tableView dequeueReusableCellWithIdentifier:@"NamePictureCell"];
                    CGRect pictureFrame = CGRectMake(28, 50, 100, 100);

                    [_popover presentPopoverFromRect:pictureFrame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                    
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't support the photo library" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            break;
        }
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) {
        case 0:
            return @"Conversation Title";
        case 1:
            return @"Actions"; 
        case 2:
            return @"Nearby";
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            return 90;
        }
        default: {
            return 44;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 1;
        case 2:
            return 2;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            static NSString *cellIdentifier = @"FeedNameCell";
            FeedNameCell *cell = (FeedNameCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            /*PersistentModelStore* store = [[Musubi sharedInstance] newStore];
             IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
             NSArray* mine = [idm ownedIdentities];
             if(mine.count > 0) {
             MIdentity* me = [mine objectAtIndex:0];
             if(me.musubiThumbnail) {
             cell.picture.image = [UIImage imageWithData:me.musubiThumbnail];
             }
             cell.nameTextField.text = me.musubiName;
             }*/
            
            
            cell.name.text = [_feedManager identityStringForFeed: _feed];
            /*
            cell.name.borderStyle = UITextBorderStyleNone;
            cell.name.textColor = [UIColor blackColor];
            cell.name.font = [UIFont systemFontOfSize:14];
            cell.name.placeholder = @"Conversation Title";
            cell.name.text = [_feedManager identityStringForFeed: _feed];
            cell.name.backgroundColor = [UIColor clearColor];
            cell.name.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.name.keyboardType = UIKeyboardTypeDefault;
            cell.name.returnKeyType = UIReturnKeyDone;*/
            cell.name.tag = kFeedNameTag;
            
            if (self.thumb != nil) {
                cell.picture.image = self.thumb;
                self.thumb = nil;
            } else if (_feed.thumbnail != nil) {
                cell.picture.image = [UIImage imageWithData:_feed.thumbnail];
            }
            
            
            return cell;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    static NSString *cellIdentifier = @"MembersCell";
                    
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleValue2 
                                reuseIdentifier:cellIdentifier];
                    }
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    cell.detailTextLabel.text = @"Members";
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    //[cell.contentView addSubview:textField];
                    
                    return cell;
                }
            }
        }
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    static NSString *cellIdentifier = @"BroadcastCell";                    
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleValue2 
                                reuseIdentifier:cellIdentifier];
                    }
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    cell.detailTextLabel.text = @"Broadcast";
                    
                    broadcastSwitch = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                    [broadcastSwitch setTitle:@"For 1 Hour" forState:UIControlStateNormal];
                    [broadcastSwitch setFrame:CGRectMake(0, 0, 100, 35)];
                    [broadcastSwitch addTarget: self action: @selector(flip:) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = broadcastSwitch;
                    
                    return cell;
                }
                case 1: {
                    
                    static NSString *cellIdentifier = @"BroadcastPasswordCell";
                    //FeedNameCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleValue2 
                                reuseIdentifier:cellIdentifier];
                    }
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    cell.detailTextLabel.text = @"Password";
                    broadcastTextField = [[UITextField alloc] initWithFrame:CGRectMake(90,
                                                                              tableView.rowHeight / 2 - 10, 200, 20)];
                    broadcastTextField.borderStyle = UITextBorderStyleNone;
                    broadcastTextField.textColor = [UIColor blackColor];
                    broadcastTextField.font = [UIFont systemFontOfSize:14];
                    broadcastTextField.placeholder = @"Leave empty for public sharing";
                    broadcastTextField.backgroundColor = [UIColor clearColor];
                    broadcastTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                    broadcastTextField.keyboardType = UIKeyboardTypeDefault;
                    broadcastTextField.returnKeyType = UIReturnKeyDone;
                    broadcastTextField.tag = kBroadcastPassword;
                    broadcastTextField.delegate = self;
                    
                    [cell.contentView addSubview:broadcastTextField];
                    
                    return cell;
                }
            }
        }
    }
    
    return nil;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddPeopleSegue"]) {
        FriendPickerViewController *vc = segue.destinationViewController;
        FeedManager* fm = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        vc.pinnedIdentities = [NSSet setWithArray:[fm identitiesInFeed:_feed]];
        vc.delegate = _delegate;
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.section) {
        case 0: {
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self performSegueWithIdentifier:@"AddPeopleSegue" sender:_feed];
                    break;
                }
            }
        }
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    break;
                }
            }
        }
    }
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case kFeedNameTag: {
            NSString* name = textField.text;
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if(!name || !name.length || [name isEqualToString:[_feedManager identityStringForFeed: _feed]])
                return;
            
            FeedNameObj* name_change = [[FeedNameObj alloc] initWithName:name andThumbnail:nil];
            
            AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
            MApp* app = [am ensureSuperApp];
            
            [FeedViewController sendObj:name_change toFeed:_feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
            
            [_delegate changedName:name];
            
            // Immediately update the feed title in the previous view controller
            NSArray* vcs = self.navigationController.viewControllers;
            UIViewController* prev = [vcs objectAtIndex:[vcs count]-2];
            prev.navigationItem.title = name;

            break;
        }
        case kBroadcastPassword: {
            break;
        }
    }
}

- (IBAction) flip: (id) sender {
    NSString* password = broadcastTextField.text;
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Identifying Location" width:200];
    NearbyFeed* nearby_feed = [[NearbyFeed alloc] initWithFeedId:self.feed.objectID andStore:[Musubi sharedInstance].mainStore];
    
    GpsBroadcaster* broadcaster = [[GpsBroadcaster alloc] init];
    [pending addObject:broadcaster];
    [broadcaster broadcastNearby:nearby_feed withPassword:password onSuccess:^{
        [pending removeObject:broadcaster];
        [DejalBezelActivityView removeViewAnimated:YES];
    } onFail:^(NSError *error) {
        [pending removeObject:broadcaster];
        [DejalBezelActivityView removeViewAnimated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nearby" 
                                                        message:[NSString stringWithFormat:@"Unable to share conversation nearby, %@", error] 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show]; 
    }];
    
}

#pragma mark - Friend picker delegate

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    if(!image)
        return;
    
    self.thumb = [image centerFitAndResizeTo:CGSizeMake(256, 256)];
    NSData* thumbnail = UIImageJPEGRepresentation(self.thumb, 0.90);
    
    NSString* name = _feed.name;
    
    FeedNameObj* name_change = [[FeedNameObj alloc] initWithName:name andThumbnail:thumbnail];
    
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    
    [ObjHelper sendObj:name_change toFeed:_feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
    
    [_delegate changedName:name];
    
    
    [[self tableView] reloadData];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[self modalViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [_popover dismissPopoverAnimated:YES];
        [[self modalViewController] dismissModalViewControllerAnimated:YES];
    }
}


@end
