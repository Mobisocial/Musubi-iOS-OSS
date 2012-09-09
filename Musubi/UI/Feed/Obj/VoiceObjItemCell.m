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

#import "VoiceObjItemCell.h"
#import <AudioToolbox/AudioToolbox.h>
#import "VoiceObj.h"

#define kVoiceObjText @"<Voice messages coming soon>"

@implementation VoiceObjItemCell

@synthesize playButton = _playButton, player, audioDuration, currentAudioDuration;

+ (void)prepareItem:(ManagedObjFeedItem *)item {
    item.computedData = item.managedObj.raw;
}

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    return 45;
}

- (NSString*)formattedSecondStringWithSeconds:(int)seconds
{
    NSString *secondsString = [NSString stringWithFormat:@"%i", seconds];
    if (secondsString.length == 1) {
        secondsString = [@"0" stringByAppendingString:secondsString];
    }
    return secondsString;
}

- (void)updateCurrentAudioDurationTextField
{
    int remainingSeconds = self.currentAudioDuration;
    if (remainingSeconds < 0) {
        remainingSeconds = 0;
    }
    NSString *remainingSecondsString = [self formattedSecondStringWithSeconds:remainingSeconds];
    [self.playButton setTitle:[@"00:" stringByAppendingString:remainingSecondsString] forState:UIControlStateNormal];
}

- (void)resetCurrentAudioDurationTextField
{
    NSString *totalSecondsString = [self formattedSecondStringWithSeconds:self.audioDuration];
    [self.playButton setTitle:[@"Play Voice Note 00:" stringByAppendingString:totalSecondsString] forState:UIControlStateNormal];

}

#pragma mark - Timer
- (void)checkRecordingTime
{
    if ([self.player isPlaying]) {
        self.currentAudioDuration--;
        [self updateCurrentAudioDurationTextField];
        if (self.currentAudioDuration >= 0) {
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(checkRecordingTime)
                                           userInfo:nil
                                            repeats:NO];

        }
        else {
            [self resetCurrentAudioDurationTextField];
        }
    }
    else {
        [self resetCurrentAudioDurationTextField];    
    }
}

- (TTStyle*)playButtonStyle:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(255, 255, 255)
                                               color2:RGBCOLOR(216, 221, 231) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:nil color:TTSTYLEVAR(linkTextColor)
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0.9) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(225, 225, 225)
                                               color2:RGBCOLOR(196, 201, 221) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:nil color:[UIColor whiteColor]
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else {
        return nil;
    }
}

- (TTButton *)playButton
{
    if (!_playButton) {
        _playButton = [[TTButton alloc] init];
        [_playButton setStyle:[self playButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
        [_playButton setStyle:[self playButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
        [_playButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self resetCurrentAudioDurationTextField];       
        [_playButton addTarget:self action:@selector(playPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_playButton];
    }
    
    return _playButton;
}

- (void)playPressed
{
    if ([self.player isPlaying] == NO) {
        [self.player prepareToPlay];

        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
        [self.player setVolume:0.5];
        [self.player play];
        self.currentAudioDuration = self.audioDuration;
        [self updateCurrentAudioDurationTextField];
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(checkRecordingTime)
                                       userInfo:nil
                                        repeats:NO];

    }
    else {
        [self.player stop];
    }
}

- (void)setObject:(ManagedObjFeedItem*)object {
    [super setObject:object];
    NSString* durationText = [object.parsedJson objectForKey:kObjFieldVoiceDuration];
    self.audioDuration = [durationText intValue];
    self.player = [[AVAudioPlayer alloc] initWithData:object.computedData error:NULL];
    self.player.delegate = self;
//    self.detailTextLabel.text = kVoiceObjText;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"Done playing");
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playButton.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y + 5, self.detailTextLabel.frame.size.width, 50);
}
@end
