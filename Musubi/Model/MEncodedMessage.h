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

@class MDevice, MIdentity;

@interface MEncodedMessage : NSManagedObject

@property (nonatomic, retain) NSData * encoded;
@property (nonatomic, retain) NSData * messageHash;
@property (nonatomic) BOOL outbound;
@property (nonatomic) BOOL processed;
@property (nonatomic, retain) NSDate* processedTime;
@property (nonatomic) int64_t sequenceNumber;
@property (nonatomic) int64_t shortMessageHash;
@property (nonatomic, retain) MDevice *fromDevice;
@property (nonatomic, retain) MIdentity *fromIdentity;

@end
