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
#import <CoreData/CoreData.h>

@class MObj;

#define kFeedTypeUnknown 0
#define kFeedTypeFixed 1
#define kFeedTypeExpanding 2
#define kFeedTypeAsymmetric 3
#define kFeedTypeOneTimeUse 4

#define kFeedNameLocalWhitelist @"local_whitelist"
#define kFeedNameProvisionalWhitelist @"provisional_whitelist"
#define kFeedNameGlobalWhitelist @"global_whitelist"

@interface MFeed : NSManagedObject

@property (nonatomic) BOOL accepted;
@property (nonatomic, retain) NSData * capability;
@property (nonatomic) int16_t knownId;
@property (nonatomic) int64_t latestRenderableObjTime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int32_t numUnread;
@property (nonatomic) int64_t shortCapability;
@property (nonatomic) int16_t type;
@property (nonatomic, retain) MObj *latestRenderableObj;
@property (nonatomic, retain) NSData* thumbnail;

@end
