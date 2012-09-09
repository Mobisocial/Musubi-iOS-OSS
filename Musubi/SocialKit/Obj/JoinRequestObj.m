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

#import "JoinRequestObj.h"
#import "IntroductionObj.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "MObj.h"
#import "FeedManager.h"
#import "AppManager.h"
#import "Musubi.h"
#import "PersistentModelStore.h"
#import "ObjHelper.h"

static NSString* kIdentitiesField = @"identities";
static NSString* kAuthorityField = @"authority";
static NSString* kPrincipalField = @"principal";
static NSString* kPrincipalHashField = @"hash";
static NSString* kNameField = @"name";

@implementation JoinRequestObj

- (id) initWithIdentities: (NSArray*) ids {
    self = [super init];
    if (self) {
        [self setType: kObjTypeJoinRequest];
        
        NSMutableArray* identities = [NSMutableArray arrayWithCapacity:ids.count];
        for (MIdentity* mId in ids) {
            NSMutableDictionary* ident = [NSMutableDictionary dictionaryWithCapacity:4];
            [ident setObject:[NSNumber numberWithUnsignedChar: mId.type] forKey:kAuthorityField];
            [ident setObject:mId.principalHash forKey:kPrincipalHashField];
            if (mId.principal)
                [ident setObject:mId.principal forKey:kPrincipalField];
            if (mId.name)
                [ident setObject:mId.name forKey:kNameField];
            [identities addObject: ident];
        }
        
        [self setData: [NSDictionary dictionaryWithObjectsAndKeys:identities, kIdentitiesField, nil]];        
    }
    
    return self;
}

- (id)initWithData:(NSDictionary *)data {
    self = [super initWithType:kObjTypeJoinRequest data:data andRaw:nil];
    return self;
}
-(BOOL)processObjWithRecord:(MObj *)obj
{
    //never process our own joins.
    if(obj.identity.owned)
        return NO;
    //TODO: incorporate the information into the database (like introduction obj)
    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
    FeedManager* fm = [[FeedManager alloc] initWithStore:store];
    NSError* error;
    
    MFeed* feed = (MFeed*)[store.context existingObjectWithID:obj.feed.objectID error:&error];
    [fm attachMember:(MIdentity*)[store.context existingObjectWithID:obj.identity.objectID error:&error] toFeed:feed];
    
    [store save];
    
    AppManager* am = [[AppManager alloc] initWithStore:store];
    MApp* app = [am ensureSuperApp];
    //TODO: don't just relay data, extract it from db
    IntroductionObj* intro = [[IntroductionObj alloc] initWithData:[NSJSONSerialization JSONObjectWithData:[obj.json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error]];
    
    [ObjHelper sendObj:intro toFeed:feed fromApp:app usingStore:store];
    return NO;
}
@end
