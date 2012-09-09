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

#import "FriendListModel.h"
#import "Musubi.h"
#import "IdentityManager.h"

@implementation FriendListModel

@synthesize results = _results;

- (id)init {
    self = [super init];
    if (self) {
        _identityManager = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    }
    return self;
}

- (BOOL)isLoaded {
    return _loaded;
}

- (BOOL)isLoading {
    return _loading;
}

- (void) reset {
    _loaded = NO;
    _loading = NO;
}

- (void) load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
    _loading = YES;
    [self didStartLoad];
    
    _results = [NSMutableArray arrayWithArray:[_identityManager query:[NSPredicate predicateWithFormat:@"principal != null"]]];
    
    _loaded = YES;
    _loading = NO;  
    
    [self didFinishLoad];
}

@end
