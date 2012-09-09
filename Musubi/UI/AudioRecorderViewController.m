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

#import "AudioRecorderViewController.h"
#import <Foundation/Foundation.h>

#define FORMAT_ILBC = 0x696C6263;
#define FORMAT_PCM  = 0x6C70636D; 		

@interface AudioRecorderViewController ()

@end

@implementation AudioRecorderViewController

@synthesize filePath, activityView, recorder, player, submitButton, resetButton, delegate, audioDuration, audioDurationTextView;

#pragma mark - Preparation
- (void)loadView 
{

    int AVRECORDER_VIEW_FRAME_HEIGHT, AVRECORDER_VIEW_FRAME_WIDTH, AVRECORDER_TABBAR_HEIGHT;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        AVRECORDER_VIEW_FRAME_HEIGHT = 420;
        AVRECORDER_VIEW_FRAME_WIDTH = 320;
        AVRECORDER_TABBAR_HEIGHT = 50;
    } else {
        AVRECORDER_VIEW_FRAME_HEIGHT = screenHeight;
        AVRECORDER_VIEW_FRAME_WIDTH = screenWidth;
        AVRECORDER_TABBAR_HEIGHT = 50;
    }
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, AVRECORDER_VIEW_FRAME_WIDTH, AVRECORDER_VIEW_FRAME_HEIGHT)];
    self.view.opaque = NO;
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    self.view.layer.opaque = NO;
    
    self.audioDurationTextView = [[UILabel alloc] init];
    [self.audioDurationTextView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0 alpha:0]];
    [self.audioDurationTextView setTextColor:[UIColor whiteColor]];
    [self.audioDurationTextView setFont:[UIFont fontWithName:@"Helvetica" size:60]];
    [self.audioDurationTextView setTextAlignment:UITextAlignmentCenter];
    [self.audioDurationTextView setFrame:CGRectMake(0, 0, 200, 75)];
    [self.audioDurationTextView setCenter:CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH/2, AVRECORDER_VIEW_FRAME_HEIGHT/2-70)];
    [self.audioDurationTextView setText:[NSString stringWithFormat:@"00:%i", (ARVC_MAX_AUDIO_DURATION)]];
    [self.view addSubview:self.audioDurationTextView];
    
    self.submitButton = [[TTButton alloc] init];
    self.submitButton.bounds = CGRectMake(0, 0, 110, 70);
    self.submitButton.center = CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH/2 + 65, AVRECORDER_VIEW_FRAME_HEIGHT/2 + 30);
    [self.submitButton setStyle: [self submitButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
    [self.submitButton setStyle: [self submitButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [self.submitButton addTarget:self action:@selector(submitPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];
    
    self.resetButton = [[TTButton alloc] init];
    self.resetButton.bounds = CGRectMake(0, 0, 110, 70);
    self.resetButton.center = CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH/2 - 80, AVRECORDER_VIEW_FRAME_HEIGHT/2 + 30);
    [self.resetButton setStyle: [self resetButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
    [self.resetButton setStyle: [self resetButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [self.resetButton addTarget:self action:@selector(resetPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.resetButton];
    
    // ACTIVITY
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.activityView setCenter:CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH/2, AVRECORDER_VIEW_FRAME_HEIGHT/2 - 120)];
    [self.view addSubview:self.activityView];
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.audioDuration = 0;
    [self updateAudioDurationLabel];
    
    [self.submitButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.resetButton setTitle:@"Cancel" forState:UIControlStateNormal];
    
    [self startRecording];
}

- (TTStyle*)submitButtonStyle:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(160,160,160,0) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(0, 255, 0)
                                               color2:RGBCOLOR(0, 170, 0) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(190, 255, 190) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:20] color:RGBCOLOR(255, 255, 255)
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(160,160,160,0.9) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(0, 225, 0)
                                               color2:RGBCOLOR(0, 200, 0) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(190, 255, 190) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:20] color:RGBCOLOR(255, 255, 255)
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else {
        return nil;
    }
}

- (TTStyle*)resetButtonStyle:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(160,160,160,0) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(255, 0, 0)
                                               color2:RGBCOLOR(170, 0, 0) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(255, 190, 190) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:20] color:RGBCOLOR(255, 255, 255)
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(160,160,160,0.9) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(225, 0, 0)
                                               color2:RGBCOLOR(200, 0, 0) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(255, 190, 190) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:20] color:RGBCOLOR(255, 255, 255)
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else {
        return nil;
    }
}

/*
 * Automatically sets the time remaining based on the difference between current duration and max audio duration
 */
- (void)updateAudioDurationLabel
{
    int remainingSeconds = ARVC_MAX_AUDIO_DURATION - self.audioDuration;
    if (remainingSeconds < 0) {
        remainingSeconds = 0;
    }
    NSString *remainingSecondsString = [NSString stringWithFormat:@"%i", remainingSeconds];
    if (remainingSecondsString.length == 1) {
        remainingSecondsString = [@"0" stringByAppendingString:remainingSecondsString];
    }
    [self.audioDurationTextView setText:[@"00:" stringByAppendingString:remainingSecondsString]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //self.filePath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.caf"]];
    self.filePath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.lbc"]];

    // Setup AudioSession
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    [avSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
  	[avSession setActive:YES error: NULL];    
}

#pragma mark - Timer
- (void)checkRecordingTime
{
    if ([self.recorder isRecording]) {
        self.audioDuration++;
        [self updateAudioDurationLabel];
        if (self.audioDuration >= ARVC_MAX_AUDIO_DURATION) {
            [self.recorder stop];
        }
        else {
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(checkRecordingTime)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
}


#pragma mark - Button Actions

- (void) resetPressed {
    if (self.recorder.isRecording) {
        [self stopRecording];
        self.audioDuration = 0;
        [self updateAudioDurationLabel];
        
        [self.resetButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.submitButton setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        [self.view removeFromSuperview];
    }  
}

- (void) submitPressed {
    if (!self.recorder.isRecording) {
        [self startRecording];
    } else {
        [self stopRecording];
        
        [self.delegate userChoseAudioData:self.filePath withDuration:self.audioDuration];        
    }
}

- (void) stopRecording {
    [self.recorder stop];
    [self.activityView stopAnimating];
}

- (void) startRecording {
    [self.submitButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [self.activityView startAnimating];
    
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:8000] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatiLBC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityLow] forKey:AVEncoderAudioQualityKey];
    [recordSetting setValue:[NSNumber numberWithInt:96] forKey:AVEncoderBitRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVEncoderBitDepthHintKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityLow] forKey:AVSampleRateConverterAudioQualityKey];
    
    /*[recordSetting setValue:[NSNumber numberWithInt: 16] forKey:AVLinearPCMBitDepthKey]; 
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey]; 
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];*/
    
    // Remove old file
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if ([filemanager fileExistsAtPath:[self.filePath absoluteString]]) {
        [filemanager removeItemAtURL:self.filePath error:NULL];
    }
    
    // Record
    NSError *error = [NSError alloc];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:self.filePath settings:recordSetting error:&error];
    NSLog(@"%@",self.filePath);
    [recorder setDelegate:self];
    [recorder prepareToRecord];
    [recorder record];
    // Begin timing -- Begin at 1
    self.audioDuration = 1;
    [self updateAudioDurationLabel];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(checkRecordingTime)
                                   userInfo:nil
                                    repeats:NO];
}
#pragma mark - Lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
