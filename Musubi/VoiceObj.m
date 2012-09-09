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

#import "VoiceObj.h"

@implementation VoiceObj

//@synthesize audio = _audio;

- (id)initWithAudio:(NSData *)rawAudio withData:(NSDictionary*)data
{
    self = [super init];
    if (!self)
        return nil;
        
    [self setType:kObjTypeVoice];
    [self setRaw:rawAudio];
    [self setData:data];

    return self;
}

- (id)initWithURL:(NSURL *)url withData:(NSDictionary*)data
{
    return [self initWithAudio:[NSData dataWithContentsOfURL:url] withData:data];
}

@end
