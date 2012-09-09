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
#import <CoreData/CoreData.h>

@class MFeed, MObj, ObjManager;

@interface FeedModel : TTModel {
    MFeed* _feed;
    ObjManager* _objManager;
    NSMutableArray* _newResults;
    
    UITableView* _tableView;
    
    NSDate* _earliestTimestampFetched;
    NSDate* _latestModifiedFetched;

    NSDate* _requireSince;

    BOOL _loaded;
    BOOL _loading;
    BOOL _hasMore;
}

@property (nonatomic, readonly) NSArray *results;
@property (nonatomic, readonly) BOOL hasMore;
@property (nonatomic, readonly) MFeed* feed;
@property (nonatomic, readonly) ObjManager* objManager;

- (id) initWithFeed: (MFeed*) feed messagesNewerThan:(NSDate*)newerThan;
- (void) loadNew;
- (void) loadObj:(NSManagedObjectID*)objId;
- (void) setTableView:(UITableView *)tableView;
- (void) setIndexPathRow:(int) indexPathRow;
- (NSArray*) consumeNewResults;

@end
