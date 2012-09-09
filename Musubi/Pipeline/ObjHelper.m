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

#import "ObjHelper.h"
#import "Obj.h"
#import "MObj.h"
#import "MFeed.h"
#import "MApp.h"
#import "MDevice.h"
#import "Musubi.h"
#import "PersistentModelStore.h"
#import "FeedManager.h"
#import "IdentityManager.h"
#import "MusubiDeviceManager.h"
#import "SBJSON.h"

@implementation ObjHelper

+ (BOOL)isRenderable:(Obj *)obj {
    if ([obj conformsToProtocol:@protocol(RenderableObj)]) {
        return YES;
    }

    return obj.data != nil &&
        ([obj.data objectForKey:kObjFieldHtml]
         || [obj.data objectForKey:kObjFieldText]
         || [obj.data objectForKey:kObjFieldRenderMode]);
}

+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed fromApp: (MApp*) app usingStore: (PersistentModelStore*) store {
    FeedManager* feedManager = [[FeedManager alloc] initWithStore:store];
    MIdentity* ownedId = [feedManager ownedIdentityForFeed: feed];
    if (ownedId == nil) {
        @throw [NSException exceptionWithName:kMusubiExceptionFeedWithoutOwnedIdentity reason:@"No owned identity for feed" userInfo: nil];
    }
    return [ObjHelper sendObj:obj toFeed:feed asIdentity:ownedId fromApp:app usingStore:store];

}

+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed asIdentity:(MIdentity*)ownedId fromApp: (MApp*) app usingStore: (PersistentModelStore*) store {
    FeedManager* feedManager = [[FeedManager alloc] initWithStore:store];
    MusubiDeviceManager* deviceManager = [[MusubiDeviceManager alloc] initWithStore: store];
    
    if (![feedManager app: app isAllowedInFeed: feed]) {
        @throw [NSException exceptionWithName:kMusubiExceptionAppNotAllowedInFeed reason:@"App not allowed in feed" userInfo:nil];
    }
    
    MDevice* device = [deviceManager deviceForName:[deviceManager localDeviceName] andIdentity:ownedId];
    assert (device != nil);
    assert (device.deviceName == [deviceManager localDeviceName]);
    
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    NSString* json = [writer stringWithObject:obj.data];
    if (json.length > 480*1024)
        @throw [NSException exceptionWithName:kMusubiExceptionMessageTooLarge reason:@"JSON is too large to send" userInfo:nil];
    
    if (obj.raw.length > 480*1024)
        @throw [NSException exceptionWithName:kMusubiExceptionMessageTooLarge reason:@"Raw is too large to send" userInfo:nil];
    
    
    MObj* mObj = (MObj*)[store createEntity:@"Obj"];
    [mObj setType: obj.type];
    [mObj setJson: json];
    [mObj setRaw: obj.raw];
    [mObj setFeed: feed];
    [mObj setApp: app];
    [mObj setIdentity: ownedId];
    [mObj setDevice: device];
    [mObj setTimestamp: [NSDate date]];
    [mObj setLastModified: mObj.timestamp];
    [mObj setProcessed: NO];
    [mObj setRenderable: [ObjHelper isRenderable:obj]];
    [mObj setEncoded: nil];
    [mObj setParent: nil];
    [mObj setSent: NO];
    
    /*NSError* error;
    if (![store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:mObj] error:&error])
        @throw error;
    */
    [store save];
    
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationPlainObjReady object:mObj.objectID];
    
    return mObj;
}
@end
