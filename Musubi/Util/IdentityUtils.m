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

#import "IdentityUtils.h"
#import "MIdentity.h"
#import "Authorities.h"

@implementation IdentityUtils
+ (NSString*) internalSafeNameForIdentity:(MIdentity *)identity {
    if (identity == nil) {
        return nil;
    }
    
    if(identity.musubiName != nil) {
        return identity.musubiName;
    } else if(identity.name != nil) {
        return identity.name;
    } else if(identity.principal != nil) {
        return [self safePrincipalForIdentity:identity];
    } else {
        return nil;
    }
}

+ (NSString*) safePrincipalForIdentity:(MIdentity *)identity {
    //face book identities should pretty much always have an associated name
    //for us to use.  We consider the users name to be their identity at facebook
    //for the purposes of display.
    if(identity.type == kIdentityTypeFacebook && identity.name != nil) {
        return [NSString stringWithFormat:@"Facebook: %@", identity.name];
    }
    if(identity.principal != nil) {
        if(identity.type == kIdentityTypeEmail) 
            return identity.principal;
        if(identity.type == kIdentityTypeFacebook) 
            return [NSString stringWithFormat:@"Facebook #%@", identity.principal];
        return identity.principal;
    }
    if(identity.type == kIdentityTypeEmail) {
        return @"Email User";
    }
    if(identity.type == kIdentityTypeFacebook) {
        return @"Facebook User";
    }
    //we prefer not to say <unknown> anywhere, so principal will be blank
    //in cases where it would be displayed on the screen and we don't
    //have anything reasonable to display
    return @"";
}
@end
