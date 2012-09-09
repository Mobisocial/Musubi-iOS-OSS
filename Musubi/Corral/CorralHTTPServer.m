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


#import "CorralHTTPServer.h"
#import "CorralHTTPConnection.h"
#import "NSData+HexString.h"

@implementation CorralHTTPServer
- (id)init
{
    self = [super init];
    if (self) {
        [self setPort:kCorralHttpPort];
        [self setInterface:@"127.0.0.1"];
        [self setConnectionClass:[CorralHTTPConnection class]];
    }
    return self;
}

+ (NSString *)urlForRaw:(MObj *)obj {
    NSString* universalHash = [obj.universalHash hexString];
    return [NSString stringWithFormat:@"http://127.0.0.1:%d/raw/%@", kCorralHttpPort, universalHash];
}
@end
