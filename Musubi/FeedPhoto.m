#import "FeedPhoto.h"
#import "FeedPhotoSource.h"
#import "CorralHTTPServer.h"
#import "SBJsonParser.h"
#import "PictureObj.h"

@implementation FeedPhoto
@synthesize caption = _caption;
@synthesize urlLarge = _urlLarge;
@synthesize urlSmall = _urlSmall;
@synthesize urlThumb = _urlThumb;
@synthesize photoSource = _photoSource;
@synthesize size = _size;
@synthesize index = _index;
@synthesize obj = _obj;

- (id)initWithObj: (MObj*) obj {
    if (self = [super init]) {
        FeedPhotoSource* source = [[FeedPhotoSource alloc] initWithFeed:obj.feed];
        NSInteger position = [source.photos indexOfObject:obj];
        self = [self initWithObj:obj andSource:source andIndex:position];
    }
    return self;
}

- (id)initWithObj: (MObj*) obj andSource: (FeedPhotoSource*)source andIndex: (NSInteger) index {
    if (self = [super init]) {
        _obj = obj;
        if (obj.json) {
            SBJsonParser* parser = [[SBJsonParser alloc] init];
            NSDictionary *json = [parser objectWithString:obj.json];
            self.caption = [json objectForKey:kTextField];
        }
        self.urlLarge = [CorralHTTPServer urlForRaw:obj];
        self.urlSmall = self.urlLarge;
        self.urlThumb = self.urlLarge;
        self.index = index;
        UIImage* image = [[UIImage alloc] initWithData:obj.raw];
        self.size = [image size];
        self.photoSource = source;
    }
    return self;
}

#pragma mark TTPhoto

- (NSString*)URLForVersion:(TTPhotoVersion)version {
    switch (version) {
        case TTPhotoVersionLarge:
            return _urlLarge;
        case TTPhotoVersionMedium:
            return _urlLarge;
        case TTPhotoVersionSmall:
            return _urlSmall;
        case TTPhotoVersionThumbnail:
            return _urlThumb;
        default:
            return nil;
    }
}

@end