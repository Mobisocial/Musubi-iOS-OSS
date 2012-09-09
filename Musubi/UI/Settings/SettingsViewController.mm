//
//  SettingsViewController.m
//  musubi
//
//  Created by Willem Bult on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "FacebookAuth.h"
#import "MAccount.h"
#import "Musubi.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "PersistentModelStore.h"
#import "AppDelegate.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "ProfileObj.h"
#import "QREncoderViewController.h"
#import "NSStringAdditions.h"
#import "IdentityUtils.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"

@implementation SettingsViewController

@synthesize authMgr, accountTypes;
@synthesize accountPrincipals = _accountPrincipals;
@synthesize tableView = _tableView;

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setAuthMgr:[[AccountAuthManager alloc] initWithDelegate:self]];
    [self setAccountTypes: [NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", kAccountTypeFacebook, @"Google", kAccountTypeGoogle, @"Email", kAccountTypeEmail, nil]];

    _accountPrincipals = [NSMutableDictionary dictionaryWithCapacity:accountTypes.count];
    
    dbUploadProgress = kDBOperationNotStarted;
    dbDownloadProgress = kDBOperationNotStarted;
    

    UITapGestureRecognizer* gestureRc = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard)];
    gestureRc.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRc];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self setAuthMgr: nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[self dbRestClient] loadMetadata:@"/"];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
    
    for (NSString* type in accountTypes.allKeys) {
        NSArray* principals = [authMgr principalsForAccount:type];
        if (principals.count > 0) {
            [_accountPrincipals setObject:[principals objectAtIndex:0] forKey:type];
        }
        
        [authMgr performSelectorInBackground:@selector(checkStatus:) withObject:type];
        [authMgr checkStatus: type];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)pictureClicked:(id)sender {
    
    
    UIActionSheet* commandPicker = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Picture From Album", nil];
        
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [commandPicker showInView:self.view];
    } else {
        
        /*UIView* test = [[UIView alloc] init];
         test.frame = commandPicker.frame;
         
         _popover=[[UIPopoverController alloc] initWithContentViewController:test];
         _popover.delegate=self;
         
         [_popover presentPopoverFromRect:CGRectMake(centerWidth-(pictureSize/2), 100, pictureSize, pictureSize) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
         [commandPicker showInView:test];*/
        NamePictureCell* cell = (NamePictureCell*) [self.tableView dequeueReusableCellWithIdentifier:@"NamePictureCell"];
        CGRect pictureFrame = CGRectMake(cell.picture.frame.size.width/2+18, cell.picture.frame.size.height-8, cell.picture.frame.size.width, cell.picture.frame.size.height);

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
                    CGRect pictureFrame = CGRectMake(cell.picture.frame.size.width/2+18, cell.picture.frame.size.height-8, cell.picture.frame.size.width, cell.picture.frame.size.height);
                    [_popover presentPopoverFromRect:pictureFrame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                    
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

- (void) closeKeyboard {
    [self.tableView endEditing:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return accountTypes.count;
        case 2:
            return [[DBSession sharedSession] isLinked] ? 3 : 2;
            //return 3;
        case 3:
            return 1;
        case 4:
            return 1;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) {
        case 0:
            return @"Profile";
        case 1:
            return @"Accounts";
        case 2:
            return @"Dropbox Backup";
        case 3:
            return @"QR Code";
        case 4:
            return @"About";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            NamePictureCell* cell = (NamePictureCell*) [tableView dequeueReusableCellWithIdentifier:@"NamePictureCell"];
            PersistentModelStore* store = [[Musubi sharedInstance] newStore];
            IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
            NSArray* mine = [idm ownedIdentities];
            if(mine.count > 0) {
                MIdentity* me = [mine objectAtIndex:0];
                if(me.musubiThumbnail) {
                    cell.picture.image = [UIImage imageWithData:me.musubiThumbnail];
                }
                cell.nameTextField.text = me.musubiName;
            }
            return cell;
        }
        case 1: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            NSString* accountType = [accountTypes.allKeys objectAtIndex:indexPath.row];
            NSString* account = [accountTypes objectForKey:accountType];
            [[cell textLabel] setText: account];
            [[cell detailTextLabel] setText: [authMgr isConnected:accountType] ? [[authMgr principalsForAccount:accountType] objectAtIndex:0] : @"Click to connect"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            return cell;
        }
        case 2: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell setAccessoryType:UITableViewCellAccessoryNone];

            switch (indexPath.row) {
                case 0: {
                    [[cell textLabel] setText: @"Save"];
                    
                    if (dbUploadProgress == kDBOperationCompleted) {
                        [[cell detailTextLabel] setText: @"Done"];
                    } else if (dbUploadProgress == kDBOperationFailed) {
                        [[cell detailTextLabel] setText: @"Failed"];                
                    } else if (dbUploadProgress >= 0) {
                        [[cell detailTextLabel] setText: [NSString stringWithFormat:@"%d%%", dbUploadProgress]];                
                    } else {
                        [[cell detailTextLabel] setText: [[DBSession sharedSession] isLinked] ? @"Click to save" : @"Click to connect"];
                    }

                    break;
                }
                case 1: {
                    [[cell textLabel] setText: @"Restore"];
                    
                    if (dbDownloadProgress == kDBOperationCompleted) {
                        [[cell detailTextLabel] setText: @"Done"];
                    } else if (dbDownloadProgress == kDBOperationFailed) {
                        [[cell detailTextLabel] setText: @"Failed"];                
                    } else if (dbDownloadProgress >= 0) {
                        [[cell detailTextLabel] setText: [NSString stringWithFormat:@"%d%%", dbDownloadProgress]];                
                    } else if (dbRestoreFile != nil) {
                        [[cell detailTextLabel] setText: @"Click to restore"];                            
                    } else {
                        [[cell detailTextLabel] setText: [[DBSession sharedSession] isLinked] ? @"No backup found" : @"Click to connect"];                        
                    }
                        
                    break;
                }
                case 2: {
                    [[cell textLabel] setText: @"Unlink Dropbox"];
                    [[cell detailTextLabel] setText: [[DBSession sharedSession] isLinked] ? @"Click to unlink" : @"Not linked"]; 
                    
                }
            }
            
            return cell;
        }
        case 3: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            [[cell textLabel] setText: @"My QR Code"];
            [[cell detailTextLabel] setText: @""];
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            return cell;
        }
        case 4: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
            }
            
            [[cell textLabel] setText: @"Eula & Privacy Policy"];
            [[cell detailTextLabel] setText: @""];
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            return cell;
        }
    }
    return nil;
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

- (DBRestClient *)dbRestClient {
    if (!dbRestClient && [[DBSession sharedSession] isLinked]) {
        dbRestClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        dbRestClient.delegate = self;
    }
    return dbRestClient;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
    switch (indexPath.section) {
        case 0:{
            break;
        }
        case 1: {
            NSString* accountType = [accountTypes.allKeys objectAtIndex:indexPath.row];
            if (![authMgr isConnected: accountType]) {
//                [self performSelectorInBackground:@selector(connectAccountWithType:) withObject:accountType];
                [self connectAccountWithType:accountType];
            } else {
                if ([accountType isEqualToString:kAccountTypeEmail]) {
                    [authMgr disconnect:accountType withPrincipal:[_accountPrincipals objectForKey:accountType]];
                } else {
                    // This is a band-aid fix for a larger problem. The _accountPrincipals
                    // array doesn't contain the Facebook UID as the principal -- instead,
                    // it contains the Facebook username. This is wrong, and the result is
                    // that the Facebook account isn't disconnected properly. Therefore, we
                    // are passing in "nil" as the principal to force the account to be
                    // disconnected.
                    [authMgr disconnect:accountType withPrincipal:nil];
                }
            }
            
            break;
        }
        case 2: {
            if (![[DBSession sharedSession] isLinked]) {
                [[DBSession sharedSession] link];
                //[self.tableView reloadData];
            } else {
                switch (indexPath.row) {
                    case 0: {
                        if (dbUploadProgress == kDBOperationNotStarted || dbUploadProgress == kDBOperationFailed) {
                            NSURL* path = [PersistentModelStoreFactory pathForStoreWithName:@"Store"];
                            [self updateDBUploadProgress:0];
                            
                            [[self dbRestClient] uploadFile:@"Backup.musubiRestore" toPath:@"/"
                                              withParentRev:nil fromPath:[path path]];
                        }
                        
                        break;
                    }
                    case 1: {
                        if (dbDownloadProgress == kDBOperationNotStarted || dbDownloadProgress == kDBOperationFailed) {
                            
                            [self updateDBDownloadProgress:0];
                            
                            NSURL* path = [PersistentModelStoreFactory pathForStoreWithName:@"Store_Restore"];
                            [[self dbRestClient] loadFile:dbRestoreFile intoPath:path.path];
                        }
                        break;
                    }
                    case 2: {
                        [[DBSession sharedSession] unlinkAll];
                        dbUploadProgress = -1;
                        
                        [self.tableView reloadData];

                        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2]];
                        [[cell detailTextLabel] setText: @"Not Linked"];

                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
                        

                    }
                }
            }
                        
            break;
        }
        case 3: {
            [self performSegueWithIdentifier:@"ShowQRCode" sender:self];
            break;
        }
        case 4: {
            [self performSegueWithIdentifier:@"eula" sender:self];
            break;
        }
     }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (void) connectAccountWithType: (NSString*) type {
    if ([type isEqualToString:kAccountTypeEmail]) {

        TTTextBarController* emailBarController = [[TTTextBarController alloc] init];
        emailBarController.delegate = self;
        [emailBarController.postButton setTitle:@"Connect" forState:UIControlStateNormal];
        emailBarController.textEditor.placeholder = @"Your email address";        
        [emailBarController showInView:self.view animated:YES];

    } else {
        [authMgr performSelectorInBackground:@selector(connect:) withObject:type];
    }
}

- (void)textBarDidBeginEditing:(TTTextBarController *)textBar {
    self.tableView.userInteractionEnabled = NO;
}

- (void)textBarDidEndEditing:(TTTextBarController *)textBar {
    self.tableView.userInteractionEnabled = YES;
}

- (BOOL)textBar:(TTTextBarController *)textBar willPostText:(NSString *)text {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    
    if ([emailTest evaluateWithObject:text]) {
        [authMgr connect:kAccountTypeEmail withPrincipal:text];
        return YES;
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"The email address you entered doesn't appear to be valid" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        
        textBar.textEditor.text = text;
    }
    
    return NO;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"ShowQRCode"]) {
        IdentityManager* idMgr = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        NSArray *ids = [idMgr ownedIdentities];
        if(ids.count > 0) {
            NSString *url = [NSString stringWithString:@"https://musubi.us/intro?"];
            for(MIdentity* identity in ids) {
                NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        [IdentityUtils internalSafeNameForIdentity:identity], @"n",
                                        [NSString stringWithFormat:@"%d", identity.type], @"t",
                                        identity.principal, @"p", nil];
                url  = [url stringByAddingQueryDictionary:params];
            }
                        
            [segue.destinationViewController performSelector:@selector(setDataToEncode:) withObject:url];
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No accounts" message:@"Please connect to another service on the settings page first to use Musubi" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    } else if ([[segue identifier] isEqualToString:@"eula"]) {
        [segue.destinationViewController performSelector:@selector(isAlreadyAccepted:) withObject:[NSNumber numberWithBool:YES]];
    }
}

- (void) updateDBDownloadProgress: (int) progress {
    dbDownloadProgress = progress;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];    
}

- (void) updateDBUploadProgress: (int) progress {
    dbUploadProgress = progress;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];    
}


#pragma mark - DBRestClient delegate

- (void)restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath {
    [self updateDBUploadProgress:(int) round(progress * 100)];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {

    [self updateDBUploadProgress:kDBOperationCompleted];
    
    // Reload the metadata so that we have the remote file path of this backup
    [[self dbRestClient] loadMetadata:@"/"];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [self updateDBUploadProgress:kDBOperationFailed];
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    if (metadata.isDirectory) {        
        NSString* backupFile = nil;
        NSDate* backupFileDate = nil;
        
        // Use the last matching file (newest)
        for (DBMetadata *file in metadata.contents) {
            
            if ([file.filename rangeOfString:@".musubiRestore"].location != NSNotFound) {
                if (backupFileDate == nil || backupFileDate.timeIntervalSince1970 < file.lastModifiedDate.timeIntervalSince1970) {
                    backupFile = file.path;
                    backupFileDate = file.lastModifiedDate;
                }
            }
        }

        dbRestoreFile = backupFile;
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    dbRestoreFile = nil;
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
    @try {
        [PersistentModelStoreFactory restoreStoreFromFile: [NSURL fileURLWithPath:localPath]];        
        [self updateDBDownloadProgress:kDBOperationCompleted];
        [((AppDelegate*)[UIApplication sharedApplication].delegate) restart];
        
    } @catch (NSError* err) {      
        NSLog(@"Error: %@", err);
        [self updateDBDownloadProgress:kDBOperationFailed];
    }
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    [self updateDBDownloadProgress:kDBOperationFailed];
}

- (void)restClient:(DBRestClient *)client loadProgress:(CGFloat)progress forFile:(NSString *)destPath {
    [self updateDBDownloadProgress:(int) round(progress * 100)];
}

#pragma mark - AccountAuthManager delegate

- (void)accountWithType:(NSString *)type isConnected:(BOOL)connected {
    int row = [accountTypes.allKeys indexOfObject:type];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
    
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
    IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
    NSArray* mine = [idm ownedIdentities];
    if(mine.count == 0) {
        NSLog(@"No identity, connect an account");
        return;
    }
    if(textField.text.length == 0) {
        MIdentity* me = [mine objectAtIndex:0];
        textField.text = me.musubiName;
        return;
    }
    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    for(MIdentity* me in mine) {
        me.musubiName = textField.text;
        me.receivedProfileVersion = now;
   }
    [store save];
    [ProfileObj sendAllProfilesWithStore:store];
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    if(!image)
        return;
    
    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
    IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
    NSArray* mine = [idm ownedIdentities];
    if(mine.count == 0) {
        NSLog(@"No identity, connect an account");
        return;
    }
    UIImage* resized = [image centerFitAndResizeTo:CGSizeMake(256, 256)];
    NSData* thumbnail = UIImageJPEGRepresentation(resized, 0.90);

    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    for(MIdentity* me in mine) {
        me.musubiThumbnail = thumbnail;
        me.receivedProfileVersion = now;
    }
    [store save];
    [ProfileObj sendAllProfilesWithStore:store];

    
    [[self tableView] reloadData];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[self modalViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [_popover dismissPopoverAnimated:YES];
        [[self modalViewController] dismissModalViewControllerAnimated:YES];
    }
    
}

@end

