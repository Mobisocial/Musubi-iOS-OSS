
//
//  FeedNameObjCell.m
//  musubi
//
//  Created by Ian Vo on 6/4/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "FeedNameObjItemCell.h"
#import "ManagedObjFeedItem.h"
#import "ObjHelper.h"

@implementation FeedNameObjItemCell

+ (NSString*) textForItem: (ManagedObjFeedItem*) item {
    NSString* text = @"I changed the chat details.";
    return text;
}

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    CGSize size = [[FeedNameObjItemCell textForItem: (ManagedObjFeedItem*)item] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

- (void)setObject:(id)object {
    [super setObject:object];
    NSString* text = [FeedNameObjItemCell textForItem:(ManagedObjFeedItem*)object];
    self.detailTextLabel.text = text;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
