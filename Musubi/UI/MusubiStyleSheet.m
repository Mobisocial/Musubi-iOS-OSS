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

#import "MusubiStyleSheet.h"

@implementation MusubiStyleSheet

- (UIColor*)navigationBarTintColor {
    return [UIColor colorWithRed:173.0/255.0 green:92.0/255.0 blue:71.0/255.0 alpha:1];
    //return [UIColor colorWithRed:125.0/255.0 green:41.0/255.0 blue:165.0/255.0 alpha:1]; // Purple
    //return [UIColor colorWithRed:5.0/255.0 green:115.0/255.0 blue:155.0/255.0 alpha:1]; // Cyan
//    return [UIColor colorWithRed:255.0/255.0 green:100.0/255.0 blue:0.0/255.0 alpha:1]; // Orange
//    return [UIColor colorWithRed:10.0/255.0 green:115.0/255.0 blue:255.0/255.0 alpha:1]; // Blue
}

- (UIColor *)tablePlainBackgroundColor {
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.jpg"]];
//    return [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1];
}

+ (UIColor *)feedTexturedBackgroundColor {
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"newBackground.png"]];
}

- (UIColor *)tablePlainCellSeparatorColor {
    return [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1];
}

- (UIColor *)tableHeaderTintColor {
    return [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1];
}

- (UIColor *)tableHeaderTextColor {
//    return [UIColor colorWithRed:30.0/255.0 green:120.0/255.0 blue:200.0/255.0 alpha:1];
    return [UIColor colorWithRed:110.0/255.0 green:110.0/255.0 blue:110.0/255.0 alpha:1];
}

- (UITableViewCellSelectionStyle)tableSelectionStyle {
    return UITableViewCellSelectionStyleGray;
}

- (UIColor *)tableHeaderShadowColor {
    return [UIColor whiteColor];
}

- (UIColor *)linkTextColor {
    return [UIColor colorWithRed:10.0/255.0 green:115.0/255.0 blue:255.0/255.0 alpha:1];
}

+ (TTStyle *)transparentRoundedButton:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:17] next:
         [TTSolidBorderStyle styleWithColor:RGBCOLOR(0,0,0) width:.5 next:
          [TTSolidFillStyle styleWithColor:RGBACOLOR(255,255,255,.3) next:
           [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 10, 10, 10) next:
            [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:16] color:RGBCOLOR(0, 0, 0) next:nil]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:17] next:
         [TTSolidBorderStyle styleWithColor:RGBCOLOR(0,0,0) width:.5 next:
          [TTSolidFillStyle styleWithColor:RGBACOLOR(255,255,255,.7) next:
           [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 10, 10, 10) next:
            [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:16] color:RGBCOLOR(0, 0, 0) next:nil]]]]];
    } else {
        return nil;
    }
}

+ (TTStyle*)embossedButton:(UIControlState)state {
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:4] next:
         [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0) blur:1 offset:CGSizeMake(0, 1) next:
          [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
           [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
            [TTTextStyle styleWithFont:nil color:TTSTYLEVAR(timestampTextColor)
                           shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                          shadowOffset:CGSizeMake(0, -1) next:nil]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:4] next:
         [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0.9) blur:1 offset:CGSizeMake(0, 1) next:
          [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
           [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
            [TTTextStyle styleWithFont:nil color:TTSTYLEVAR(timestampTextColor)
                           shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                          shadowOffset:CGSizeMake(0, -1) next:nil]]]]];
    } else {
        return nil;
    }
}

+ (TTStyle*)roundedButtonStyle:(UIControlState)state {
    UIFont* font = [UIFont boldSystemFontOfSize:14];
    
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(255, 255, 255)
                                               color2:RGBCOLOR(216, 221, 231) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:font color:TTSTYLEVAR(linkTextColor)
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
              [TTTextStyle styleWithFont:font color:[UIColor whiteColor]
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else {
        return nil;
    }
}

+ (TTStyle*) textViewBorder {
    return [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:4] next:
     [TTSolidFillStyle styleWithColor:[UIColor whiteColor] next:
      [TTInnerShadowStyle styleWithColor:RGBACOLOR(0,0,0,0.5) blur:3 offset:CGSizeMake(1, 1) next:
       [TTSolidBorderStyle styleWithColor:RGBCOLOR(158, 163, 172) width:1 next:nil]]]];
}
+ (TTStyle*) bottomPanelStyle {
    return [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, -1, -1, -1) next:
            [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(240,240,240) color2:RGBCOLOR(210,210,210) next:
             [TTSolidBorderStyle styleWithColor:RGBCOLOR(170,170,170) width:1 next:nil]]];
}


@end
