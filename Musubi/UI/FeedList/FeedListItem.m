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

#import "FeedListItem.h"
#import "FeedManager.h"
#import "MFeed.h"
#import "ObjManager.h"
#import "MObj.h"
#import "MIdentity.h"
#import "ObjFactory.h"
#import "StatusObj.h"
#import "LocationObj.h"
#import "VoiceObj.h"
#import "StoryObj.h"
#import "IntroductionObj.h"
#import "FeedNameObj.h"
#import "Musubi.h"
#import "UIImage+Resize.h"
#import "PictureObj.h"
#import "Three20Core/NSDateAdditions.h"
#import "NSData+Crypto.h"
#import "IdentityManager.h"
#import "PersistentModelStore.h"

@interface SneakyDate : NSObject
- (SneakyDate*)initWithDate:(NSDate*)date andNewest:(NSDate*)newest andOldest:(NSDate*)oldest;
@end

@implementation SneakyDate {
    NSDate* _newest;
    NSDate* _oldest;
    NSDate* _mine;
}

- (SneakyDate *)initWithDate:(NSDate *)date andNewest:(NSDate *)newest andOldest:(NSDate *)oldest
{
    self = [super init];
    if(!self) 
         return nil;
    
    _mine = date;
    _newest = newest;
    _oldest = oldest;
    
    return self;
}

- (NSString*)formatShortTime {
    NSTimeInterval diff = abs([_mine timeIntervalSinceNow]);
    
    if (diff < TT_DAY * 7) {
        return [_mine formatTime];
        
    } else {
        static NSDateFormatter* formatter = nil;
        if (nil == formatter) {
            formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = TTLocalizedString(@"M/d/yy", @"Date format: 7/27/09");
            formatter.locale = TTCurrentLocale();
        }
        return [formatter stringFromDate:_mine];
    }
}
@end


static NSMutableDictionary* sContactImages;



@implementation FeedListItem {
    int32_t _unread;
}
+ (NSMutableDictionary*)contactImages {
    if(!sContactImages)
        sContactImages = [NSMutableDictionary dictionary];
    return sContactImages;
}

@synthesize feed = _feed;
@synthesize image = _image;
@synthesize obj = _obj;
@synthesize start = _start;
@synthesize end = _end;
@synthesize picture = _picture;
@synthesize special = _special;

- (id)initWithFeed:(MFeed *)feed after:(NSDate*)after before:(NSDate*)before {
    self = [super init];
    if(!self)
        return nil;
    _feed = feed;
    FeedManager* feedMgr = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    ObjManager* objMgr = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    
    self.title = [feedMgr identityStringForFeed:feed];
    self.timestamp = [[SneakyDate alloc] initWithDate:[NSDate dateWithTimeIntervalSince1970:feed.latestRenderableObjTime] andNewest:after andOldest:before];

    
    _obj = [feed latestRenderableObj];
    if (_obj != nil) 
        _obj = (MObj*)[[Musubi sharedInstance].mainStore.context existingObjectWithID:_obj.objectID error:nil];
    
    if (_obj == nil) {
        _obj = [objMgr latestStatusObjInFeed:feed];
    }
    
    NSString* sender = nil;
    if (_obj.identity.owned) {
        sender = @"You";
    } else {
        sender = [IdentityManager displayNameForIdentity:_obj.identity];
        sender = [[sender componentsSeparatedByString:@" "] objectAtIndex:0];
    }
    
    if ([_obj.type isEqualToString:kObjTypeStatus]) {
        StatusObj* obj = (StatusObj*) [ObjFactory objFromManagedObj:_obj];
        self.text = [NSString stringWithFormat: @"%@: %@", sender, obj.text];
    }
    else if ([_obj.type isEqualToString:kObjTypeLocation]) {
        LocationObj* obj = (LocationObj*) [ObjFactory objFromManagedObj:_obj];
        if(obj.text.length == 0) {
            self.text = [NSString stringWithFormat: @"%@ just checked in somewhere.", sender];
        }
        else {
            self.text = [NSString stringWithFormat: @"%@ just checked in to: %@", sender, obj.text];
        }
    }
    else if ([_obj.type isEqualToString:kObjTypeStory]) {
        self.text = [NSString stringWithFormat: @"%@ just shared a story.", sender];
    }
    else if ([_obj.type isEqualToString:kObjTypeIntroduction]) {
        self.text = [NSString stringWithFormat: @"%@ just added some people to the chat.", sender];
    }
    else if ([_obj.type isEqualToString:kObjTypeFeedName]) {
        self.text = [NSString stringWithFormat: @"%@ just changed the chat details.", sender];
    }
    else {
        NSDictionary* objDescriptions = [NSDictionary dictionaryWithObjectsAndKeys:@"a picture", kObjTypePicture, @"a voice memo", kObjTypeVoice, @"a story", kObjTypeStory, nil];
        
        NSString* objDesc = [objDescriptions objectForKey:_obj.type];
        if (objDesc == nil) {
            self.text = [NSString stringWithFormat: @"%@ just did something in an app.", sender];
        }
        else {
            self.text = [NSString stringWithFormat: @"%@ sent %@", sender, objDesc];
        }
        self.special = YES;
    }
    /*
    for (MIdentity* ident in [feedMgr identitiesInFeed:feed]) {
        if (!ident.owned) {
            if(ident.musubiThumbnail) {
                self.image = [UIImage imageWithData:ident.musubiThumbnail];
                break;
            } else if (ident.thumbnail) {
                self.image = [UIImage imageWithData:ident.thumbnail];
                break;
            }
        }
    }*/
    
    NSArray* order = _obj ? [NSArray arrayWithObject:_obj.identity] : nil;
    if (feed.thumbnail != nil) {
        self.image = [UIImage imageWithData:feed.thumbnail];
    } else {
        self.image = [self imageForIdentities: [feedMgr identitiesInFeed:feed] preferredOrder:order];
    }
    _unread = feed.numUnread;
    self.start = after;
    self.end = before;
    return self;
}

- (int32_t)unread {
    //update the unread count on the old items if need be
    if(_start && _unread) {
        _unread = _feed.numUnread;
    }
    return _unread;
}
- (UIImage*) imageForIdentities: (NSArray*) identities preferredOrder:(NSArray*)order {
    NSMutableArray* selected = [NSMutableArray arrayWithCapacity:4];
    
    NSMutableArray* images = [NSMutableArray arrayWithCapacity:4];
    NSMutableSet* knownpics = [NSMutableSet set];

    for (MIdentity* i in identities) {
        if (i.owned)
            continue;
        
        if (selected.count > 3)
            break;
        NSData* thumbnail = i.musubiThumbnail;
        if(!thumbnail)
            thumbnail = i.thumbnail;
        
        //skip dupes
        if([knownpics containsObject:thumbnail.sha1Digest])
            continue;
        
        if(thumbnail) {
            [knownpics addObject:thumbnail.sha1Digest];
            [selected addObject:i];
        }
        
    }
    NSMutableArray* selected_ids = [NSMutableArray arrayWithCapacity:selected.count];
    for(MIdentity* i in selected) {
        [selected_ids addObject:i.objectID];
    }
    
    NSMutableDictionary* feedImageCache = [FeedListItem contactImages];
    UIImage * cachedImage = [feedImageCache objectForKey:selected_ids];
    //TODO: profile change invalidation
    if(cachedImage)
        return cachedImage;
    

    for (MIdentity* i in selected) {
        UIImage* img = nil;
        
        if(i.musubiThumbnail) {
            img = [UIImage imageWithData:i.musubiThumbnail];                
        }
        if (!img && i.thumbnail) {
            img = [UIImage imageWithData:i.thumbnail];
        }
        
        if (img)
            [images addObject: img];
    }
    
    if (images.count > 1) {
        
        // Set up the context
        CGSize size = CGSizeMake(120, 120);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();        
        
        // Set up the stroke buffer and settings
        CGPoint* pointBuffer = malloc(sizeof(CGPoint) * 2);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(context, 2.0);
        
        // The number of rows for the second column, and the x-pos offset for it
        int rows = images.count - 1;
        CGFloat leftColWidth = (size.width / MIN(3, rows+1)) + 1; // add 1 for the line
        
        // The right column image is the largest, and placed at (0,0)
        UIImage* rightImg = [(UIImage*)[images objectAtIndex:0] centerFitAndResizeTo:CGSizeMake(size.width - leftColWidth, size.height)];
        [rightImg drawAtPoint: CGPointMake(leftColWidth, 0)];
        
        // Calc the size of the small images in the left column
        CGSize leftColImgBounds = CGSizeMake(leftColWidth, size.height / rows);
        
        // Draw the left column
        for (int row=0; row<rows; row++) {
            // Resize/crop the image and draw it
            UIImage* curImg = ((UIImage*)[images objectAtIndex:row + 1]);            
            UIImage* cropped = [curImg centerFitAndResizeTo:leftColImgBounds];          
            [cropped drawAtPoint: CGPointMake(0, leftColImgBounds.height * row)];
            
            // Draw a line under it if we have more coming
            if (row<rows-1) {                
                pointBuffer[0] = CGPointMake(0, leftColImgBounds.height * (row + 1) - 1);
                pointBuffer[1] = CGPointMake(leftColWidth, leftColImgBounds.height * (row + 1) - 1);
                CGContextStrokeLineSegments(context, pointBuffer, 2);
            }
        }
        
        // Draw a line to the right of it
        pointBuffer[0] = CGPointMake(leftColWidth+1, 0);
        pointBuffer[1] = CGPointMake(leftColWidth+1, size.height);
        CGContextStrokeLineSegments(context, pointBuffer, 2);
        
        // Clear and return
        UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        free(pointBuffer);
        return result;        
    } else if (images.count == 1) {
        return [images objectAtIndex:0];
    }
    else {
        return [UIImage imageNamed:@"missing.png"];
    }
     
    return nil;
}


@end
