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


#import "CorralHTTPConnection.h"
#import "HTTPDataResponse.h"
#import "GCDAsyncSocket.h"
#import "ObjManager.h"
#import "Musubi.h"
#import "MObj.h"
#import "NSData+HexString.h"

@implementation CorralHTTPConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    //NSLog(@"Requested %@", path);
    //NSLog(@"connected to %@", [asyncSocket connectedHost]);

    PersistentModelStore* store =[[Musubi sharedInstance] newStore];
    if ([path hasPrefix:@"/raw/"]) {
        NSString* hashString = [path substringFromIndex:5];
        ObjManager* manager = [[ObjManager alloc] initWithStore:store];
        NSData* hash = [hashString dataFromHex];
        MObj* obj = [manager objWithUniversalHash:hash];
        if (obj) {
            return [[HTTPDataResponse alloc] initWithData:obj.raw];
        }
    }

    NSLog(@"Failed to handle request for %@", path);
    NSData* invalid = [@"Invalid" dataUsingEncoding:NSUTF8StringEncoding];
    HTTPDataResponse* response = [[HTTPDataResponse alloc] initWithData:invalid];
    return response;
}

@end
