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

@class FeedManager, ObjManager;

@interface DateRange : NSObject
- (DateRange*)initWithStart:(NSDate*)after andEnd:(NSDate*)before;
@property (nonatomic, strong) NSDate* start;
@property (nonatomic, strong) NSDate* end;
@end;

@interface FeedListDataSource : TTSectionedDataSource {
    FeedManager* _feedManager;
    ObjManager* _objManager;
}

@property (nonatomic, strong) NSMutableArray* dateRanges;
-(void)invalidateObjectId:(NSManagedObjectID*)oid;
@end
