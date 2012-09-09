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

#import "WelcomeViewController.h"
#import "MAccount.h"
#import "Musubi.h"
#import "Three20/Three20.h"
#import "VerifyViewController.h"
#import "MusubiAnalytics.h"

@implementation WelcomeViewController

@synthesize authMgr = _authMgr, facebookButton = _facebookButton, googleButton = _googleButton, statusLabel = _statusLabel, emailField = _emailField, tapRecognizer = _tapRecognizer;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setAuthMgr:[[AccountAuthManager alloc] initWithDelegate:self]];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _facebookButton.hidden = NO;
    _googleButton.hidden = NO;
    _statusLabel.text = @"...or use your existing accounts";
    
    // Color
    self.navigationController.navigationBar.tintColor = [((id)[TTStyleSheet globalStyleSheet]) navigationBarTintColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updateImporting:) name:kMusubiNotificationIdentityImported object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updateImporting:) name:kMusubiNotificationIdentityImportFinished object:nil];
    
    self.emailField.delegate = self;
}

- (void)viewDidLoad {
    // Hide the keyboard if user clicks out of it
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];

    [nc addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];

    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                            action:@selector(didTapAnywhere:)];
}

-(void) keyboardWillShow:(NSNotification *) note {
    [self.view addGestureRecognizer:self.tapRecognizer];
}

-(void) keyboardWillHide:(NSNotification *) note
{
    [self.view removeGestureRecognizer:self.tapRecognizer];
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {    
    [self.emailField resignFirstResponder];
}

/*
 * End hide keyboard
 */


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationIdentityImported object:nil];
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationIdentityImportFinished object:nil];
}

- (UINavigationItem *)navigationItem {
    UINavigationItem* item = [super navigationItem];
    item.hidesBackButton = YES;
    return item;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)authNetwork:(id)sender {
    NSString* type = sender == self.facebookButton ? kAccountTypeFacebook : kAccountTypeGoogle;

    NSError *error;
    if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryOnboarding action:kAnalyticsActionConnectingAccount label:type value:-1 withError:&error]) {
        // error
    }
        
    _facebookButton.hidden = YES;
    _googleButton.hidden = YES;
    _statusLabel.text = @"Connecting...";

    [_authMgr performSelectorInBackground:@selector(connect:) withObject:type];
}

#pragma mark - AccountAuthManager delegate

- (void)accountWithType:(NSString *)type isConnected:(BOOL)connected {
    if (connected) {
        NSError *error;
        if (![[GANTracker sharedTracker] trackEvent:kAnalyticsCategoryOnboarding action:kAnalyticsActionConnectedAccount label:type value:-1 withError:&error]) {
            // error
        }

        _facebookButton.hidden = YES;
        _googleButton.hidden = YES;
        _statusLabel.text = @"Importing contacts...";
    }
}

- (void) updateImporting: (NSNotification*) notification {
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(updateImporting:) withObject:notification waitUntilDone:NO];
        return;
    }    
    
    // don't block
    [self.navigationController popViewControllerAnimated:NO];
    
    /*
    
    BOOL importDone = NO;
    
    if ([notification.object objectForKey:@"index"]) {
        NSNumber* index = [notification.object objectForKey:@"index"];
        NSNumber* total = [notification.object objectForKey:@"total"];
        
        int remaining = total.intValue - index.intValue - 1;
        
        if (remaining > 0) {
            [_statusLabel setText:[NSString stringWithFormat: @"Importing %d contacts...", remaining]];
        } else {
            importDone = YES;
        }
    } else {
        importDone = YES;
    }
    
    if (importDone) {
        [self.navigationController popViewControllerAnimated:YES];
    }*/
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.emailField.text rangeOfString:@"@"].location != NSNotFound) {
        [_authMgr connect:kAccountTypeEmail withPrincipal:_emailField.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


@end
