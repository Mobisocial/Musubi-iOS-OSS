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

#import "IntroductionObj.h"
#import "MIdentity.h"

static NSString* kIdentitiesField = @"identities";
static NSString* kAuthorityField = @"authority";
static NSString* kPrincipalField = @"principal";
static NSString* kPrincipalHashField = @"hash";
static NSString* kNameField = @"name";

@implementation IntroductionObj

- (id) initWithIdentities: (NSArray*) ids {
    self = [super init];
    if (self) {
        [self setType: kObjTypeIntroduction];
        
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
    self = [super initWithType:kObjTypeIntroduction data:data andRaw:nil];
    return self;
}

//TODO: incorporate the information into the database

@end
