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


#import <Foundation/Foundation.h>

@class MObj;

@interface PreparedObj : NSObject {
    int feedType;
    NSData* feedCapability;
    NSString* appId;
    uint64_t timestamp;
    NSString* type;
    NSString* jsonSrc;
    NSData* raw;
    NSNumber* intKey;
    NSString* stringKey;
}

@property (nonatomic, assign) int feedType;
@property (nonatomic) NSData* feedCapability;
@property (nonatomic) NSString* appId;
@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic) NSString* type;
@property (nonatomic) NSString* jsonSrc;
@property (nonatomic) NSData* raw;
@property (nonatomic) NSNumber* intKey;
@property (nonatomic) NSString* stringKey;

- (id) initWithFeedType: (int) ft feedCapability: (NSData*) fc appId: (NSString*) aId timestamp: (uint64_t) ts data: (MObj*) obj;

@end
