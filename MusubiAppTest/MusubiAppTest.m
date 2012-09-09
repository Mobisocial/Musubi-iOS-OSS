//
//  MusubiAppTest.m
//  MusubiAppTest
//
//  Created by Willem Bult on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MusubiAppTest.h"
#import "IBEncryptionScheme.h"
#import "NSData+Crypto.h"


@implementation MusubiAppTest


- (NSString*) randomUniquePrincipal {
    NSMutableString* str = [[NSMutableString alloc] init];
    int length = random() % 16;
    
    for (int i=0; i<length; i++) {
        char c = 'a' + (random() % ('z' - 'a'));
        [str appendFormat:@"%c", c];
    }
    
    [str appendString:@"@gmail.com"];
    return str;
}

- (IBEncryptionIdentity *)randomIdentity {
    return [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:[self randomUniquePrincipal] temporalFrame:0];
}

- (void) assertMessage: (OutgoingMessage*) om isEqualTo: (IncomingMessage*) im {
    STAssertTrue([om.data isEqualToData: im.data], @"Data mismatch");
    STAssertTrue([om.recipients count] == [im.recipients count], @"Recipients count mismatch");
    
    for (int i=0; i<[im.recipients count]; i++) {
        MIdentity* ir = [im.recipients objectAtIndex:i];
        MIdentity* or = [om.recipients objectAtIndex:i];
        STAssertTrue([ir.principalHash isEqualToData: or.principalHash], @"Principal Hash mismatch");
        STAssertTrue(ir.type == or.type, @"Type mismatch");
    }
    
    STAssertTrue([om.fromIdentity.principalHash isEqualToData: im.fromIdentity.principalHash], @"FromIdentity principal hash mismatch");
    STAssertTrue(om.fromIdentity.type == im.fromIdentity.type, @"FromIdentity type mismatch");
}

@end
