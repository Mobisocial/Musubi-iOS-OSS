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

#import <UIKit/UIKit.h>
#import "NamePictureCell.h"
#import "UIImage+Resize.h"
#import "AccountAuthManager.h"
#import "Three20/Three20.h"
#import <DropboxSDK/DropboxSDK.h>

#define kDBOperationNotStarted -1
#define kDBOperationCompleted -2
#define kDBOperationFailed -3

@interface SettingsViewController : UIViewController<UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,AccountAuthManagerDelegate,DBRestClientDelegate,TTTextBarDelegate,UIActionSheetDelegate,UIPopoverControllerDelegate> {
    AccountAuthManager* authMgr;
    NSDictionary* accountTypes;
    
    DBRestClient *dbRestClient;
    int dbUploadProgress;
    int dbDownloadProgress;
    NSString* dbRestoreFile;
    
    UIAlertView* loadingDialog;
    UIPopoverController* _popover;
}

@property (nonatomic) AccountAuthManager* authMgr;
@property (nonatomic) NSDictionary* accountTypes;
@property (nonatomic) NSMutableDictionary* accountPrincipals;
@property (nonatomic) IBOutlet UITableView* tableView;

- (IBAction) pictureClicked: (id)sender;

@end
