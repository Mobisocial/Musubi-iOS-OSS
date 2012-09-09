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
#import <AVFoundation/AVFoundation.h>
#import "VoiceObj.h"
#import "Three20/Three20.h"

// The delegate must receive an audio data object and deal
// with it
@protocol AudioRecorderDelegate <NSObject>

- (void)userChoseAudioData:(NSURL *)file withDuration:(int)seconds;

@end

@interface AudioRecorderViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, AVAudioSessionDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;

// This is the temporary path of the audio file
@property (nonatomic, strong) NSURL *filePath;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, strong) TTButton *submitButton;
@property (nonatomic, strong) TTButton *resetButton;
@property (nonatomic, strong) UILabel *audioDurationTextView;
@property (nonatomic) int audioDuration;

@property (nonatomic, weak) id delegate;

@end
