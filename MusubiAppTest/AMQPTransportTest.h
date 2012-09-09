//
//  AMQPTransportTest.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import "MusubiAppTest.h"
#import "UnverifiedIdentityProvider.h"
#import "AMQPTransport.h"

@interface AMQPTransportTest : MusubiAppTest {
    PersistentModelStore* store;
    PersistentModelStoreFactory* storeFactory;
    UnverifiedIdentityProvider* identityProvider;
}

@property (nonatomic, retain) UnverifiedIdentityProvider* identityProvider;
@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;

- (BOOL) waitForConnection: (AMQPTransport*) transport during: (NSTimeInterval) interval;

@end
