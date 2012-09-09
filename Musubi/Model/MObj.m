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


#import "MObj.h"
#import "MApp.h"
#import "MDevice.h"
#import "MEncodedMessage.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "MLike.h"
#import "MObj.h"


@implementation MObj

@dynamic deleted;
@dynamic json;
@dynamic lastModified;
@dynamic processed;
@dynamic sent;
@dynamic raw;
@dynamic intKey;
@dynamic stringKey;
@dynamic renderable;
@dynamic shortUniversalHash;
@dynamic timestamp;
@dynamic type;
@dynamic universalHash;
@dynamic app;
@dynamic device;
@dynamic encoded;
@dynamic feed;
@dynamic identity;
@dynamic likes;
@dynamic parent;

@end
