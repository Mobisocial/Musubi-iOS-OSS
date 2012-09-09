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


#import "ObjEncoder.h"
#import "Musubi.h"

#import "NSData+Crypto.h"
#import "SBJSON.h"
#import "BSONEncoder.h"
#import "MIdentity.h"
#import "MDevice.h"
#import "MObj.h"
#import "MFeed.h"
#import "MApp.h"
#import "PreparedObj.h"

@implementation ObjEncoder

static uint32_t kVersionHeader = 30050081;
static uint32_t kDefaultFlags = 0x0;
static uint32_t kHeaderGuesstimate = 200;

+ (PreparedObj *)prepareObj:(MObj *)obj forFeed:(MFeed *)feed andApp:(MApp *)app {
    
    // Verify that the JSON is valid
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    [parser objectWithString:obj.json];
    
    return [[PreparedObj alloc] initWithFeedType:feed.type feedCapability:feed.capability appId:app.appId timestamp:[obj.timestamp timeIntervalSince1970] * 1000 data:obj];
}

+ (NSData *)encodeObj:(PreparedObj *)obj {
    
    int approx = (obj.raw == nil) ? kHeaderGuesstimate : (obj.raw.length + kHeaderGuesstimate);
    
    NSMutableData* encoded = [NSMutableData dataWithCapacity:approx];
    
    uint32_t versionBigEndian = CFSwapInt32HostToBig(kVersionHeader);
    uint32_t flagsBigEndian = CFSwapInt32HostToBig(kDefaultFlags);
    
    [encoded appendBytes:&versionBigEndian length:sizeof(versionBigEndian)];
    [encoded appendBytes:&flagsBigEndian length:sizeof(flagsBigEndian)];
    [encoded appendData:[BSONEncoder encodeObj: obj]];
    
    return encoded;
}


+ (PreparedObj *)decodeObj:(NSData *)data {
    const void* dataPtr = data.bytes;
    
    uint32_t version = CFSwapInt32BigToHost(*(uint32_t*)dataPtr);
    if (version != kVersionHeader) {
        @throw [NSException exceptionWithName:kMusubiExceptionBadObjFormat reason:[NSString stringWithFormat: @"Bad version header: %lu", version] userInfo:nil];
    }
    dataPtr += sizeof(uint32_t);
        
    //uint32_t flags = CFSwapInt32BigToHost(*(uint32_t*)dataPtr);

    dataPtr += sizeof(uint32_t);
    
    NSData* encoded = [NSData dataWithBytes:dataPtr length:data.length - (dataPtr - data.bytes)];
    
    return [BSONEncoder decodeObj:encoded];
}


+ (NSData*) computeUniversalHashFor: (NSData*) hash from: (MIdentity*) from onDevice: (MDevice*) device {
    uint8_t type = (uint8_t) from.type;
    uint64_t deviceName = CFSwapInt64HostToBig((uint64_t) device.deviceName);
    
    NSMutableData* input = [NSMutableData data];
    [input appendBytes:&type length:1];
    [input appendData:from.principalHash];
    [input appendBytes:&deviceName length: sizeof(deviceName)];
    [input appendData:hash];
    
    return input.sha256Digest;
}


@end
