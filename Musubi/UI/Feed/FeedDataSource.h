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

#import "Three20/Three20.h"

@class MFeed, MObj, ObjManager;

@interface FeedDataSource : TTListDataSource {
    ObjManager* _objManager;
    NSDate* _startingAt;
    int32_t _numUnread;
    int _earliestUnreadMessageRow;
    BOOL _didLoadMore;
    BOOL _firstLoad;
}

- (id) initWithFeed: (MFeed*) feed messagesNewerThan:(NSDate*)newerThan unreadCount:(int32_t) numUnread;
- (void) loadItemsForObjs: (NSArray*) objs inTableView: (UITableView*) tableView;
- (NSIndexPath*) indexPathForObj: (MObj*) obj;
@end
