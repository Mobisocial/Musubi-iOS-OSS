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

#import "AppManager.h"
#import "MApp.h"

@implementation AppManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"App" andStore:s];
    if (self) {
        
    }
    return self;
}

- (id)ensureAppWithAppId:(NSString *)appId {
    MApp* app = (MApp*)[self queryFirst:[NSPredicate predicateWithFormat:@"appId = %@", appId]];
    if (app == nil) {
        app = (MApp*)[self create];
        [app setAppId:appId];
    }
    
    return app;
}

- (id)ensureSuperApp {
    NSString* appId = @"mobisocial.musubi";
    MApp* app = (MApp*)[self queryFirst:[NSPredicate predicateWithFormat:@"appId = %@", appId]];
    if (app == nil) {
        app = (MApp*)[self create];
        [app setAppId:appId];
    }
    
    return app;
}

- (BOOL)isSuperApp:(MApp *)app {
    return [app.appId isEqualToString:kSuperAppId];
}

@end
