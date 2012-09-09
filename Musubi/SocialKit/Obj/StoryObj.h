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
#define kObjTypeStory @"story"
#define kObjFieldStoryUrl @"url"
#define kObjFieldStoryOriginalUrl @"original_url"
#define kObjFieldStoryTitle @"title"
#define kObjFieldStoryText @"text"
#define kObjFieldStoryDescription @"description"

@interface StoryObj : Obj<RenderableObj>

- (id)initWithURL:(NSURL *)url text:(NSString*) text ;
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) NSString* story_url;
@property (nonatomic, strong) NSString* story_title;
@property (nonatomic, strong) NSString* story_description;
@property (nonatomic, strong) UIImage* story_thumbnail;

@end
