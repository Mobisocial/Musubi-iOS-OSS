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

#import "FeedListStyleSheet.h"

@implementation FeedListStyleSheet

///////////////////////////////////////////////////////////////////////////////////////////////////
// styles

///////////////////////////////////////////////////////////////////////////////////////////////////
// public colors

- (UIColor*)navigationBarTintColor {
    //return [UIColor colorWithRed:125.0/255.0 green:41.0/255.0 blue:165.0/255.0 alpha:1]; // Purple
    //return [UIColor colorWithRed:5.0/255.0 green:115.0/255.0 blue:155.0/255.0 alpha:1]; // Cyan
        return [UIColor colorWithRed:255.0/255.0 green:100.0/255.0 blue:0.0/255.0 alpha:1]; // Orange
    //    return [UIColor colorWithRed:10.0/255.0 green:115.0/255.0 blue:255.0/255.0 alpha:1]; // Blue
}

- (UIColor*)myFirstColor {
    return RGBCOLOR(80, 110, 140);
}

- (UIColor*)mySecondColor {
    return [UIColor grayColor];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public fonts

- (UIFont*)myFirstFont {
    return [UIFont boldSystemFontOfSize:15];
}

- (UIFont*)mySecondFont {
    return [UIFont systemFontOfSize:14];
}

@end
