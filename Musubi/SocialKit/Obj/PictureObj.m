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

#import "PictureObj.h"
#import "UIImage+Resize.h"

@implementation PictureObj

@synthesize image = _image;
@synthesize text = _text;

- (id)initWithImage:(UIImage *)img andText:(NSString *)text andCallback: (NSString*) callback{
    self = [super init];
    if (self) {
        int width = MIN(img.size.width, 480);
        CGSize size = CGSizeMake(width, width / img.size.width * img.size.height);
        
        [self setType: kObjTypePicture];
        [self setImage: [img resizedImage:size interpolationQuality:kCGInterpolationHigh]];
        [self setText: text];
        [self setRaw: UIImageJPEGRepresentation(_image, .9)];
        
        [self setData: [NSDictionary dictionaryWithObjectsAndKeys:text, kTextField, callback, kFieldCallback, nil]];
    }
    
    return self;
}
- (id)initWithImage:(UIImage *)img andText:(NSString *)text {
    return [self initWithImage:img andText:text andCallback:nil];
}
- (id)initWithImage:(UIImage *)img {
    return [self initWithImage:img andText:nil];
}

- (id)initWithRaw:(NSData *)raw andData: (NSDictionary*) data {
    return [self initWithImage: [UIImage imageWithData:raw] andText:[data objectForKey:kTextField]];
}

- (id)initWithRaw:(NSData *)raw {
    return [self initWithImage: [UIImage imageWithData:raw]];
}


@end
