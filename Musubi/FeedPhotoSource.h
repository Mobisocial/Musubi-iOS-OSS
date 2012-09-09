#import <Foundation/Foundation.h>
#import "Three20/Three20.h"
#import "MFeed.h"

@interface FeedPhotoSource : TTURLRequestModel <TTPhotoSource> {
    NSString* _title;
    NSArray* _photos;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSArray* photos;

- (id) initWithFeed: (MFeed*)feed;

@end