#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "MObj.h"
#import "MFeed.h"
#import "FeedPhotoSource.h"

@interface FeedPhoto : NSObject <TTPhoto> {
    NSString *_caption;
    NSString *_urlLarge;
    NSString *_urlSmall;
    NSString *_urlThumb;
    id <TTPhotoSource> _photoSource;
    CGSize _size;
    NSInteger _index;
    MObj* _obj;
}

@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) NSString *urlLarge;
@property (nonatomic, copy) NSString *urlSmall;
@property (nonatomic, copy) NSString *urlThumb;
@property (nonatomic, strong) id<TTPhotoSource> photoSource;
@property (nonatomic) CGSize size;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) MObj* obj;

- (id)initWithObj: (MObj*)obj;
- (id)initWithObj:(MObj *)obj andSource:(FeedPhotoSource*)source andIndex: (NSInteger) index;

@end