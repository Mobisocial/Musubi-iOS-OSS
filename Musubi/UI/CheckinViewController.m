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

#import "CheckinViewController.h"

#import "MusubiStyleSheet.h"
#import "Three20/Three20.h"
#import "Three20UI/UIViewAdditions.h"
#import "StatusTextView.h"
#import "LocationObj.h"
#import "AppManager.h"
#import "MApp.h"
#import "Musubi.h"
#import "FeedViewController.h"

@interface CheckinViewController ()

@end

@implementation CheckinViewController

@synthesize mapView = _mapView;
@synthesize feed = _feed;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(lookup == nil) {
        lookup = [[GpsLookup alloc] init];
    }
    [_mapView setScrollEnabled:YES];
    [_mapView setZoomEnabled:YES];
    [lookup lookupAndCall:^(CLLocation *location) {
        annotationPoint = [[MKPointAnnotation alloc] init];
        annotationPoint.coordinate = location.coordinate;
        
        [_mapView addAnnotation:annotationPoint];
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (location.coordinate, 50, 50);
        [_mapView setRegion:region animated:NO];
        
    } orFail:^(NSError *error) {
    }];
   
    _mapView.delegate = self; 
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapViewTapped:)];
    tapGestureRecognizer.delegate = self;
    [_mapView addGestureRecognizer:tapGestureRecognizer];
}



-(void)mapViewTapped:(UITapGestureRecognizer *) tgr {
    [self hideKeyboard];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];*/
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)loadView {
    [super loadView];
    self.title = @"Check-in";
    
    postView.backgroundColor = [UIColor clearColor];
    postView.style = [MusubiStyleSheet bottomPanelStyle];
    
    TTView* statusFieldBox = [[TTView alloc] initWithFrame:CGRectMake(6, 6, postView.frame.size.width - 77, 32)];
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
    [sendButton addTarget:self action:@selector(sendCheckin:) forControlEvents:UIControlEventTouchUpInside];
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)sendCheckin:(id)sender {
    
    LocationObj* location = [[LocationObj alloc] 
                             initWithText: [statusField text] 
                             andLat: [NSNumber numberWithDouble:annotationPoint.coordinate.latitude]
                             andLon: [NSNumber numberWithDouble:annotationPoint.coordinate.longitude]];
    
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    
    [self sendObj:location fromApp:app];
    
    [_delegate reloadFeed];
    [self.navigationController popViewControllerAnimated:YES];
}

- (MObj*) sendObj:(Obj *)obj fromApp: (MApp*) app {
    return [FeedViewController sendObj:obj toFeed: _feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat desiredHeight = [[NSString stringWithFormat: @"%@\n", textView.text] sizeWithFont:textView.font constrainedToSize:CGSizeMake(textView.width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap].height + 13; // 13 is the border + margin, etc.
    
    CGFloat diff = desiredHeight - textView.height;
    
    if (diff != 0 && _mapView.height - diff > 80) {
        _mapView.height -= diff;
        postView.frame = CGRectMake(0, _mapView.height, postView.width, postView.height + diff);
        textView.height += diff;
        textView.superview.height += diff;
        
        
        sendButton.frame = CGRectMake(sendButton.frame.origin.x, postView.height - sendButton.height - 2, sendButton.width, sendButton.height);
        
    }
}

/// ACTIONS

- (void) keyboardWillShow:(NSNotification*)notification {
    
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIWindow *window = [[[UIApplication sharedApplication] windows]objectAtIndex:0];
    UIView *mainSubviewOfWindow = window.rootViewController.view;
    CGRect keyboardFrameConverted = [mainSubviewOfWindow convertRect:keyboardFrame fromView:window];
    
    NSDictionary *userInfo = [notification userInfo];
    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    [_mapView setFrame: CGRectMake(0, 0, _mapView.frame.size.width, self.view.frame.size.height - postView.frame.size.height - keyboardFrameConverted.size.height + 1)]; // +1 to hide bottom border
    [postView setFrame:CGRectMake(0, _mapView.frame.size.height - 1, postView.frame.size.width, postView.frame.size.height)]; // -1 to hide bottom border
    
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
    
    [postView setFrame:CGRectMake(0, self.view.frame.size.height - postView.frame.size.height, postView.frame.size.width, postView.frame.size.height)];
    [_mapView setFrame: CGRectMake(0, 0, _mapView.frame.size.width, postView.frame.origin.y + 1)]; // +1 to hide bottom border
    
    [UIView commitAnimations]; 
    
}

- (void) hideKeyboard {
    
    [statusField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self hideKeyboard];
    [statusField setText:@""];
    [self textViewDidChange:statusField];
}


#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    NSLog(@"making annotation view");
    MKAnnotationView *annotationView = [mv dequeueReusableAnnotationViewWithIdentifier:@"PinAnnotationView"];
    
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"PinAnnotationView"];
        annotationView.draggable = YES;
    }
    
    return annotationView;
}

@end
