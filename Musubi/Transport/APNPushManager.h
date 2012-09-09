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

@interface APNPushManager : NSObject
+ (void) resetLocalUnread:(NSString*)deviceToken count:(int)count background:(BOOL)background;
+ (void) clearRemoteUnread:(NSString*)deviceToken background:(BOOL)background;
+ (void) registerDevice:(NSString*)deviceToken identities:(NSArray*)idents localUnread:(int)count;
+ (int) tallyLocalUnread;
+ (void) resetLocalUnreadInBackgroundTask:(BOOL)background;
+ (void) resetBothUnreadInBackgroundTask;
@end
