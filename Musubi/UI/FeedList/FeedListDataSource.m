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

#import "FeedListDataSource.h"
#import "MFeed.h"
#import "FeedManager.h"
#import "FeedListModel.h"
#import "FeedListItem.h"
#import "FeedListItemCell.h"
#import "Musubi.h"
#import "NSDate+LocalTime.h"
#import "ObjManager.h"

@implementation DateRange
@synthesize start, end;
- (DateRange*)initWithStart:(NSDate*)after andEnd:(NSDate*)before
{
    self = [super init];
    if(!self)
        return nil;
    start = after;
    end = before;
    return self;
}
@end


@implementation FeedListDataSource {
    FeedListItem* itemToDelete;
    UITableView* tableViewToUpdate;
    NSMutableDictionary* feedCache;
}

@synthesize dateRanges;

- (id) init {
    self = [super init];
    if (self) {
        self.model = [[FeedListModel alloc] init];
        _feedManager = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        _objManager = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        dateRanges = [NSMutableArray array];
        feedCache = [NSMutableDictionary dictionary];
    }
    return self;
}

-(void)invalidateObjectId:(NSManagedObject*)oid
{
    [feedCache removeObjectForKey:oid];
}

- (void)tableViewDidLoadModel:(UITableView *)tableView {
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components = [gregorian components:unitFlags fromDate:today];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    NSMutableArray* lastDateRanges = dateRanges;

    NSMutableArray* sections = [NSMutableArray array];
    NSMutableArray* section_items = [NSMutableArray arrayWithCapacity:self.sections.count];
    NSMutableArray* ends = [NSMutableArray arrayWithCapacity:self.sections.count];
    
    NSDate *todayMidnight = [gregorian dateFromComponents:components];
    NSDate *other;

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"EEEE";
    
    [sections addObject:@"Today"];
    [ends addObject:todayMidnight];

    [sections addObject:@"Yesterday"];
    components = [[NSDateComponents alloc] init];
    components.minute = -1;
    components.day = -1;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:[df stringFromDate:other]];
    [ends addObject:other];
    components.day = -2;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:[df stringFromDate:other]];
    [ends addObject:other];
    components.day = -3;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:[df stringFromDate:other]];
    [ends addObject:other];
    components.day = -4;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:[df stringFromDate:other]];
    [ends addObject:other];
    components.day = -5;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:[df stringFromDate:other]];
    [ends addObject:other];
    components.day = -6;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:@"A Week Ago"];
    [ends addObject:other];
    components.day = -7;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:@"Two Weeks Ago"];
    [ends addObject:other];
    components.day = -14;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:@"A Month Ago"];
    [ends addObject:other];
    components = [[NSDateComponents alloc] init];
    components.day = -30;
    other = [gregorian dateByAddingComponents:components toDate:todayMidnight options:0];
    [sections addObject:@"All Time"];
    [ends addObject:other];

    NSDate* start = nil;
    for(NSDate* end in ends) {
        [section_items addObject:[self filterFeeds:((FeedListModel*)self.model).results withActivityAfter:start until:end]];
        [dateRanges addObject:[[DateRange alloc] initWithStart:start andEnd:end]];
        start = end;
    }
    [section_items addObject:[self filterFeeds:((FeedListModel*)self.model).results withActivityAfter:start until:nil]];
    [dateRanges addObject:[[DateRange alloc] initWithStart:start andEnd:nil]];

    for(int i = sections.count - 1; i >= 0; --i) {
        if(![[section_items objectAtIndex:i] count]) {
            [sections removeObjectAtIndex:i];
            [dateRanges removeObjectAtIndex:i];
            [section_items removeObjectAtIndex:i];
        }
    }
    
    self.sections = sections;
    self.items = section_items;
}

- (NSMutableArray*) filterFeeds:(NSMutableArray*)newItems withActivityAfter:(NSDate*)start until:(NSDate*)end
{
    NSMutableArray* hits = [NSMutableArray arrayWithCapacity:newItems.count];
    for(MFeed* feed in newItems) {
        if(!start && feed.latestRenderableObjTime > end.timeIntervalSince1970) {
            
        } else if(!end && feed.latestRenderableObjTime < start.timeIntervalSince1970) {
            
        } else if(feed.latestRenderableObjTime > end.timeIntervalSince1970 && feed.latestRenderableObjTime < start.timeIntervalSince1970) {
            
        } else {
            continue;
        }
        FeedListItem* item = [feedCache objectForKey:feed.objectID];
        if(!item)
            item = [[FeedListItem alloc] initWithFeed:feed after:start before:end];
        [feedCache setObject:item forKey:feed.objectID];
        if (item) {
            [hits addObject: item];
        }
    }
    return hits;
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    return [FeedListItemCell class];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITableView * tableView = tableViewToUpdate;
    tableViewToUpdate = nil;
    FeedListItem* original_item = itemToDelete;
    itemToDelete = nil;
    if(buttonIndex != 1)
        return;
    MFeed* feed = original_item.feed;
    
    [tableView beginUpdates];
    for(int i = self.items.count - 1; i >= 0; --i) {
        NSMutableArray* section_items = [self.items objectAtIndex:i];
        for(int j = section_items.count - 1; j >= 0; --j) {
            FeedListItem* item = [section_items objectAtIndex:j];
            if([item.feed.objectID isEqual:feed.objectID]) {
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:j inSection:i]] withRowAnimation:UITableViewRowAnimationFade];
                [section_items removeObjectAtIndex:j];
            }
        }
        if(!section_items.count) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            [self.items removeObjectAtIndex:i];
            [self.sections removeObjectAtIndex:i];
            [self.dateRanges removeObjectAtIndex:i];
        }
    }
    [_feedManager deleteFeedAndMembersAndObjs:feed];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) { 
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Delete Conversation" message:@"All messages and pictures to this group will be deleted.  Are you sure?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
    
        itemToDelete = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        tableViewToUpdate = tableView;
        [alert show];
    } 
}


@end
