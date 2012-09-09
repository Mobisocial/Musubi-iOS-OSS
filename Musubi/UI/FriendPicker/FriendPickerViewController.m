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

#import "FriendPickerViewController.h"
#import "FriendListDataSource.h"
#import "Three20UI/UIViewAdditions.h"
#import "FriendListItem.h"
#import "FriendListModel.h"
#import "Musubi.h"
#import "AccountManager.h"
#import "IBEncryptionScheme.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "Authorities.h"
#import "PersistentModelStore.h"

@interface FriendPickerViewController ()

@end

@implementation FriendPickerViewController

@synthesize delegate = _delegate, pinnedIdentities = _pinnedIdentities;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // TTTableViewController doesn't implement initWithCoder: so do the required init here
        _lastInterfaceOrientation = self.interfaceOrientation;
        _tableViewStyle = UITableViewStylePlain;
        _clearsSelectionOnViewWillAppear = YES;
        _flags.isViewInvalid = YES;
        _remainingImports = [NSMutableDictionary dictionaryWithCapacity:2];
        self.autoresizesForKeyboard = YES;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIScrollView* recipientView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 36)];
    [recipientView setUserInteractionEnabled:YES];
    [recipientView setMultipleTouchEnabled:YES];
    recipientView.layer.borderWidth = 1;
    recipientView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    UILabel* toLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 25, recipientView.frame.size.height)];
    toLabel.text = @"To:";
    toLabel.textColor = [UIColor grayColor];
    
    [recipientView addSubview:toLabel];
    [recipientView addSubview:self.pickerTextField];
    [self.pickerTextField setFrame:CGRectMake(35, 0, recipientView.frame.size.width, recipientView.frame.size.height)];
    
    [self.pickerTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    self.tableView.top += recipientView.height;
    self.tableView.height -= recipientView.height;
    
    [self.view addSubview:recipientView];
    
    _importingLabel = [[UILabel alloc] init];
    _importingLabel.font = [UIFont systemFontOfSize: 13.0];
    _importingLabel.text = @"";
    _importingLabel.backgroundColor = [UIColor colorWithRed:78.0/256.0 green:137.0/256.0 blue:236.0/256.0 alpha:1];
    _importingLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:_importingLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    AccountManager* accMgr = [[AccountManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    if ([accMgr claimedAccounts].count == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"No accounts" message:@"Please connect to another service on the settings page first to use Musubi" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self.pickerTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Color
    self.navigationController.navigationBar.tintColor = [((id)[TTStyleSheet globalStyleSheet]) navigationBarTintColor];

    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updateImporting:) name:kMusubiNotificationIdentityImported object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationIdentityImported object:nil];
}

- (void) updateImporting: (NSNotification*) notification {
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(updateImporting:) withObject:notification waitUntilDone:NO];
        return;
    }    
    
    if ([notification.object objectForKey:@"index"]) {
        NSNumber* index = [notification.object objectForKey:@"index"];
        NSNumber* total = [notification.object objectForKey:@"total"];
        
        [_remainingImports setObject:[NSNumber numberWithInt:total.intValue - index.intValue - 1] forKey:[notification.object objectForKey:@"type"]];
        
        int remaining = 0;
        for (NSNumber* rem in _remainingImports.allValues) {
            remaining += rem.intValue;
        }
        
        if (remaining > 0) {
            [_importingLabel setText:[NSString stringWithFormat: @"  Importing %d contacts...", remaining]];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [_importingLabel setFrame:CGRectMake(0, 386, 320, 30)];
            } else {
                [_importingLabel setFrame:CGRectMake(0, self.view.height-30, self.view.width, 30)];

            }
        } else {
            _importingLabel.text = @"";
            [_importingLabel setFrame:CGRectZero];    
        }
        
        if (remaining % 20 == 0) {
            [self search: _pickerTextField.text];
        }
    }
}

- (void)createModel {
    self.dataSource = [[FriendListDataSource alloc] init];
    ((FriendListDataSource*)self.dataSource).pinnedIdentities = _pinnedIdentities;
    ((FriendListDataSource*)self.dataSource).pickerTextField = _pickerTextField;
}

- (id<UITableViewDelegate>)createDelegate {
    return [[FriendPickerTableViewDelegate alloc] initWithController:self];
}

- (TTPickerTextField*) pickerTextField {
    if (_pickerTextField == nil) {
        _pickerTextField = [[TTPickerTextField alloc] init];
        _pickerTextField.delegate = self;
        _pickerTextField.dataSource = self;
        _pickerTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _pickerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _pickerTextField.rightViewMode = UITextFieldViewModeAlways;
        _pickerTextField.returnKeyType = UIReturnKeyDefault;
        _pickerTextField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _pickerTextField.keyboardType = UIKeyboardTypeEmailAddress;
        _pickerTextField.font = [UIFont systemFontOfSize:14.0];
        _pickerTextField.text = @"";
        [_pickerTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
    }
    
    return _pickerTextField;
}

- (void)search:(NSString *)text {
    [self.dataSource search:text];
    [self.tableView reloadData];
}

- (void)textField:(TTPickerTextField *)textField didAddCellAtIndex:(NSInteger)index {
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    FriendListItem* item = [textField.cells objectAtIndex: index];
    [ds toggleSelectionForItem:item];
    
    NSIndexPath* path = [ds indexPathForItem:item];
    if (path != nil)
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    
    if (textField.lineCount > 1) {
        [textField setFrame:CGRectMake(35, 0, 320, 30 * textField.lineCount + 6)];
        
        [textField.superview setFrame:CGRectMake(0, 0, 320, 70)];
        [self.tableView setFrame:CGRectMake(0, 70, 320, 362)];
        
        int newY = 30 * (textField.lineCount - 2);
        [((UIScrollView*)textField.superview) setContentOffset:CGPointMake(0, newY) animated:NO];
    }
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    
    return [emailTest evaluateWithObject:candidate];
}

- (void)textFieldDidChange:(TTPickerTextField*)picker {
    
    BOOL identityAdded = NO;
    BOOL profileDataChanged = NO;
    FriendListItem* newListItem = nil;
    
    IdentityManager* im = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];

    // Trim leading whitespace
    NSString* newIdentityName = [picker.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Ensure the entered email address is valid
    if ([self validateEmail:newIdentityName]) {
        
        IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:newIdentityName temporalFrame:0];
        MIdentity* mId = [im ensureIdentity:ident withName:newIdentityName identityAdded:&identityAdded profileDataChanged:&profileDataChanged];
        FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;

        NSMutableArray* selectedPrincipals = [[NSMutableArray alloc] init];
        NSArray* pinned = nil;
        
        // Save the pinned identities, if there are any
        if (ds.pinnedIdentities.count > 0) {
            pinned = ds.pinnedIdentities;
        }
        
        // Save the currently selected principals
        for (MIdentity* identity in ds.selectedIdentities) {
            [selectedPrincipals addObject:identity.principal];
        }
        
        // Add the new principal
        [selectedPrincipals addObject:mId.principal];
        
        // Clear the cells from the picker text field
        [self.pickerTextField removeAllCells];

        // Reload the datasource from the database so that the new identity is shown in the table
        [self createModel];
        
        // Get a pointer to the newly allocated dataSource
        ds = (FriendListDataSource*)self.dataSource;
        
        // Re-add the pinned identities, if necessary
        if (pinned != nil) {
            ds.pinnedIdentities = pinned;
            [ds tableViewDidLoadModel:self.tableView];
        }
        
        // Add the previously selected principals + the new one
        for (NSString* principal in selectedPrincipals) {
            newListItem = [ds existingItemByPrincipal:principal];
            if (newListItem != nil) {
                [self.pickerTextField addCellWithObject:newListItem];
            }
            newListItem = nil;
        }
       
        [self.pickerTextField becomeFirstResponder]; 

    } else {
        // Invalid Email Specified
        // TODO: Reset the search criteria so that nothing is filtered out of the list
    }
    
}

- (void) textField: (UITextField*)tf didRemoveCellAtIndex: (int) idx {
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    FriendListItem* item = [ds.selection objectAtIndex: idx];
    [ds toggleSelectionForItem:item];
    
    NSIndexPath* path = [ds indexPathForItem:item];
    if (path != nil)
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString*) tableView:(UITableView*)tv labelForObject:(id) obj {
    return ((FriendListItem*) obj).musubiName;
}

- (void) didBeginDragging {
    [(FriendPickerViewController*)self hideKeyboard];
}

- (void) hideKeyboard {
    [_pickerTextField resignFirstResponder];
}

- (IBAction)friendsSelected:(id)sender {
    [self textFieldDidChange:self.pickerTextField];
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    
    if (ds.selectedIdentities.count == 0) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Empty chat" message:@"You didn't add any people to this chat. Are you sure you want to continue?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
        [alert show];
    }
    else {
        [_delegate friendsSelected:ds.selectedIdentities];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 1)
        return;
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    [_delegate friendsSelected:ds.selectedIdentities];
}

@end

@implementation FriendPickerTableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendListDataSource* ds = (FriendListDataSource*)self.controller.dataSource;
    FriendListItem* item = [ds itemAtIndexPath: indexPath];
    
    if (!item.pinned) {
        TTPickerTextField* picker = ((FriendPickerViewController*)self.controller).pickerTextField;
        
        if (!item.selected) {
            [picker addCellWithObject: item];
        } else {
            [picker removeCellWithObject: item];
        }
    }
}

@end