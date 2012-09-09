#import "FeedPhotoSource.h"
#import "FeedPhoto.h"
#import "ObjManager.h"
#import "Musubi.h"

@implementation FeedPhotoSource
@synthesize title = _title;
@synthesize photos = _photos;

/*
 Use this code to launch Sketch on top of a photo:
 
 NSString* appId = @"musubi.sketch";
 AppManager* appMgr = [[AppManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
 MApp* app = [appMgr ensureAppWithAppId:appId];
 MObj* obj = // get the FeedPhoto's obj
 [(FeedViewController*)self.controller launchApp:app withObj:obj];
 
 */

- (id) initWithFeed:(MFeed*)feed {
    if ((self = [super init])) {
        // unlimited content size, we've already downloaded it once!
        [[TTURLRequestQueue mainQueue] setMaxContentLength:0];

        self.title = @"Chat Photos";
        ObjManager* objManager = [[ObjManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
        NSLog(@"Loading photos for %@...", feed);
        self.photos = [objManager pictureObjsInFeed:feed];
        NSLog(@"Loaded %d photos", self.photos.count);
    }
    return self;
}

#pragma mark TTModel

- (BOOL)isLoading {
    return FALSE;
}

- (BOOL)isLoaded {
    return TRUE;
}

#pragma mark TTPhotoSource

- (NSInteger)numberOfPhotos {
    return _photos.count;
}

- (NSInteger)maxPhotoIndex {
    return _photos.count-1;
}

- (id<TTPhoto>)photoAtIndex:(NSInteger)photoIndex {
    if (photoIndex < _photos.count) {
        return [[FeedPhoto alloc] initWithObj:[_photos objectAtIndex:photoIndex] andSource:self andIndex:photoIndex];
    } else {
        return nil;
    }
}
@end