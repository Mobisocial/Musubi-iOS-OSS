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

#import "StatusObj.h"

static NSString* kTextField = @"text";

@implementation StatusObj

@synthesize text = _text;

- (id)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        [self setType: kObjTypeStatus];
        [self setText: text];
        [self setData: [NSDictionary dictionaryWithObjectsAndKeys:text, kTextField, nil]];        
    }
    
    return self;
}

- (id)initWithData:(NSDictionary *)data {
    return [self initWithText: [data objectForKey:kTextField]];
}

@end
