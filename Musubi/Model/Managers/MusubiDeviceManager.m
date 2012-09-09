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

#import "MusubiDeviceManager.h"
#import "PersistentModelStore.h"
#import "MDevice.h"
#import "MMyDeviceName.h"
#import "IdentityManager.h"

@implementation MusubiDeviceManager

static uint64_t __localDeviceName;

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Device" andStore:s];
    if (self != nil) {
    }
    return self;
}

- (uint64_t)localDeviceName {
    if(__localDeviceName != 0)
        return __localDeviceName;
    
    MMyDeviceName* deviceName = (MMyDeviceName*)[store queryFirst:nil onEntity:@"MyDeviceName"];
    
    if(deviceName != nil) {
        __localDeviceName = deviceName.deviceName;
        return __localDeviceName;
    }
    
    //generated a unique name
    uint64_t generated;
    generated = (uint64_t)arc4random();
    generated = (generated << 32) + (uint64_t)arc4random();
    __localDeviceName = generated;
    
    //save it to the database
    deviceName = (MMyDeviceName*)[store createEntity:@"MyDeviceName"];
    deviceName.deviceName = generated;
    [store save];
    return __localDeviceName;
}

- (MDevice*) deviceForName: (uint64_t) name andIdentity: (MIdentity*) mId {
    return (MDevice*)[self queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND deviceName = %llu", mId, name]];
}

@end
