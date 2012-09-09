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

#import "ManagedObjFeedItem.h"
#import "MObj.h"
#import "FeedItemCell.h"

@implementation ManagedObjFeedItem {
    NSDictionary* parsedJson;
}

@synthesize managedObj, cellClass, parsedJson, computedData;

- (id)initWithManagedObj:(MObj*)mObj
{
    self = [super init];
    if (self) {
        self.managedObj = mObj;
    }
    return self;
}

- (NSDictionary *)parsedJson {
    if (parsedJson || !managedObj.json) {
        NSLog(@"parsed %@", parsedJson);
        return parsedJson;
    }

    NSError* error;
    parsedJson = [NSJSONSerialization JSONObjectWithData:[managedObj.json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (!parsedJson) {
        NSLog(@"Failed to parse json %@", error);
    }
    return parsedJson;
}

@end
