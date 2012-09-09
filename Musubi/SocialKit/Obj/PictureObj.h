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

#import "Obj.h"

#define kObjTypePicture @"picture"

#define kFieldCallback @"callback"
#define kMimeField @"mimeType"
#define kTextField @"text"

@interface PictureObj : Obj<RenderableObj> {
    UIImage* _image;
    NSString* _text;
}

@property (nonatomic) UIImage* image;
@property (nonatomic) NSString* text;

- (id) initWithImage: (UIImage*) img;
- (id) initWithImage: (UIImage*) img andText: (NSString*) text;
- (id) initWithImage:(UIImage *)img andText: (NSString*) text andCallback: (NSString*) callback;
- (id) initWithRaw: (NSData*)raw;
- (id) initWithRaw:(NSData *)raw andData: (NSDictionary*) data;

@end
