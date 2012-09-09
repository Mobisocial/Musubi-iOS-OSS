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

#import "FeedModel.h"
#import "ObjManager.h"
#import "MObj.h"
#import "Musubi.h"
#import "IndexedTTTableView.h"

@implementation FeedModel

@synthesize results = _results, feed = _feed, objManager = _objManager;

- (id)initWithFeed:(MFeed *)feed  messagesNewerThan:(NSDate*)newerThan {
    self = [super init];
    if (!self)
        return nil;
    
    _objManager = [[ObjManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
    _feed = feed;
    _requireSince = newerThan;
    return self;
}

- (BOOL)isLoaded {
    return _loaded;
}

- (BOOL)isLoading {
    return _loading;
}

- (BOOL)isLoadingMore {
    return _loading && _earliestTimestampFetched != nil;
}

- (BOOL) hasMore {
    return _hasMore;
}

- (void) reset {
    _loaded = NO;
    _loading = NO;
    _hasMore = NO;
    _latestModifiedFetched = nil;
    _earliestTimestampFetched = nil;
    _newResults = [[NSMutableArray alloc] init];
}

- (void) loadObj:(NSManagedObjectID*)objId {
    _loading = YES;
    [self didStartLoad];
    
    MObj* obj = (MObj*)[_objManager queryFirst:[NSPredicate predicateWithFormat:@"(self == %@)", objId]];
    NSLog(@"Querying for %@. Res: %@", objId, obj);
    if (obj)
        [_newResults addObject:obj];
    
    _loaded = YES;
    _loading = NO;    
    [self didFinishLoad];
}

- (void) setTableView:(UITableView *)tableView {
    _tableView = tableView;
}


- (void) load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
    if (!more) {
        [self reset];
    }
    
    _loading = YES;    
    [self didStartLoad];
    BOOL firstLoad = _earliestTimestampFetched == nil;
    int batchSize = firstLoad ? 15 : 50;
    
    BOOL regular_query = YES;
    if(_requireSince) {
        NSArray* res = [_objManager renderableObjsInFeed:_feed after:_requireSince limit:0];
        if(res && res.count > batchSize) {
            [_newResults addObjectsFromArray:res];
            _hasMore = YES;
            _requireSince = nil;
            regular_query = NO;
        }
    } 
    
    if(regular_query) {
        
        if (_earliestTimestampFetched)
            [_newResults addObjectsFromArray:[_objManager renderableObjsInFeed:_feed before:_earliestTimestampFetched limit:batchSize]];
        else
            [_newResults addObjectsFromArray:[_objManager renderableObjsInFeed:_feed limit:batchSize]];
        
        _hasMore = _newResults.count == batchSize;
        

    }    
    _earliestTimestampFetched = ((MObj*)[_newResults lastObject]).timestamp;
    if (firstLoad) {
        if(_newResults.count) {
            _latestModifiedFetched = ((MObj*)[_newResults objectAtIndex:0]).lastModified;
        } else {
            _latestModifiedFetched = [NSDate date];
        }
    }
    _loaded = YES;
    _loading = NO;  
    [(IndexedTTTableView*)_tableView setIndexPathRow:_newResults.count+1];
    [self didFinishLoad];}

- (void) loadNew {
    if (_latestModifiedFetched) {
        return [self load:TTURLRequestCachePolicyDefault more:NO];
    }
    
    _loading = YES;    
    [self didStartLoad];
    
    [_newResults addObjectsFromArray:[_objManager renderableObjsInFeed:_feed after:_latestModifiedFetched limit:25]];
    _latestModifiedFetched = ((MObj*)[_results objectAtIndex:0]).lastModified;
    
    _loaded = YES;
    _loading = NO;    
    [self didFinishLoad];
}

- (NSArray *)consumeNewResults {
    NSArray* res = _newResults;
    _newResults = [[NSMutableArray alloc] init];
    return res;
}


@end
