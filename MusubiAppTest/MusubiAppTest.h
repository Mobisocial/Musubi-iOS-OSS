//
//  MusubiAppTest.h
//  MusubiAppTest
//
//  Created by Willem Bult on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "OutgoingMessage.h"
#import "IncomingMessage.h"
#import "IBEncryptionScheme.h"

@interface MusubiAppTest : SenTestCase

- (NSString*) randomUniquePrincipal;
- (IBEncryptionIdentity*) randomIdentity;
- (void) assertMessage: (OutgoingMessage*) om isEqualTo: (IncomingMessage*) im;

@end
