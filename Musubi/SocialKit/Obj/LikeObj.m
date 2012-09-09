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

#import "LikeObj.h"
#import "ObjHelper.h"
#import "ObjManager.h"
#import "Musubi.h"
#import "NSData+HexString.h"
#import "MLike.h"
#import "MObj.h"

@implementation LikeObj

- (id) initWithObjHash: (NSData*) hash {
    self = [super init];
    if (self) {
        [self setType: kObjTypeLike];
        [self setData: [NSDictionary dictionaryWithObjectsAndKeys:[hash hexString], kObjFieldTargetHash, nil]];        
    }
    
    return self;
}

- (id) initWithData: (NSDictionary*) data {
    self = [super initWithType:kObjTypeLike data:data andRaw:nil];
    return self;
}

- (BOOL)processObjWithRecord:(MObj *)obj {
    NSString *parentHash = [self.data objectForKey: kObjFieldTargetHash];
    if(parentHash == nil) {
        NSLog(@"Client sent an invalid like obj... %@", obj);
        return NO;
    }
    
    ObjManager* objMgr = [[ObjManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    NSData* hashData = [parentHash dataFromHex];

    MObj* likedObj = [objMgr objWithUniversalHash: hashData];
    [objMgr saveLikeForObj:likedObj from: obj.identity];
    return NO;
}

@end
