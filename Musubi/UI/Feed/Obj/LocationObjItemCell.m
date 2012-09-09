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

#import "LocationObjItemCell.h"
#import "ManagedObjFeedItem.h"
#import "ObjHelper.h"
#import "LocationObj.h"
#import "UIViewAdditions.h"

@implementation LocationObjItemCell

+ (NSString*) textForItem: (ManagedObjFeedItem*) item {
    NSString* text = nil;
    text = [[item parsedJson] objectForKey: kTextField];
    return text;
}

+ (NSNumber*) latForItem: (ManagedObjFeedItem*) item {
    NSNumber* lat = nil;
    lat = [[item parsedJson] objectForKey: kLatField];
    return lat;
}

+ (NSNumber*) lonForItem: (ManagedObjFeedItem*) item {
    NSNumber* lon = nil;
    lon = [[item parsedJson] objectForKey: kLonField];
    return lon;
}

- (void)setObject:(ManagedObjFeedItem*)object {
    if (_item != object) {
        [super setObject:object];
        
        coord.latitude = [[LocationObjItemCell latForItem:(ManagedObjFeedItem*)object] floatValue];
        coord.longitude = [[LocationObjItemCell lonForItem:(ManagedObjFeedItem*)object] floatValue];
        
        text = [LocationObjItemCell textForItem:(ManagedObjFeedItem*)object];
        sender = object.sender;
        if(text.length == 0) {
            self.detailTextLabel.text = [NSString stringWithFormat: @"I just checked in somewhere."];
        }
        else {
            self.detailTextLabel.text = [NSString stringWithFormat: @"I just checked in to: %@", text];
        }
        
    }
}

- (MKMapView *)mapView {
    if (!mapView) {
        mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [mapView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [mapView setContentMode:UIViewContentModeScaleAspectFit];
        
        MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];  
        [annotationPoint setCoordinate: coord];
        [annotationPoint setTitle:sender];
        [annotationPoint setSubtitle:text];
        [mapView addAnnotation:annotationPoint];
        [mapView selectAnnotation:annotationPoint animated:NO];
        [mapView setScrollEnabled:NO];
        [mapView setZoomEnabled:NO];
        
        [self.contentView addSubview:mapView];
    }
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance (coord, 100, 100);
    [mapView setRegion:region animated:NO];
    return mapView;
}

+ (CGFloat) textHeightForItem: (ManagedObjFeedItem*) item {
    CGSize size = [[LocationObjItemCell textForItem: (ManagedObjFeedItem*)item] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    
    return size.height;
}

+ (CGFloat) mapHeight {
        
    return 200;
}

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    
    NSString* text = [LocationObjItemCell textForItem:(ManagedObjFeedItem*)item];
    
    if(text.length == 0) {
        text = @" ";
    }
    
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /*CGFloat left = self.detailTextLabel.origin.x;
    CGFloat top = self.timestampLabel.origin.y + self.timestampLabel.height + kTableCellMargin;
    
    self.mapView.frame = CGRectMake(left, top, self.detailTextLabel.frame.size.width, [LocationObjItemCell mapHeight]);
    
    CGFloat textTop = top + self.mapView.height;
    self.detailTextLabel.frame = CGRectMake(left, textTop, self.detailTextLabel.width, [LocationObjItemCell textHeightForItem:(ManagedObjFeedItem*)_item] + kTableCellSmallMargin);
    */
}

@end
