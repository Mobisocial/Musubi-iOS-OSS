//
//  EncodingTest.h
//  Musubi
//
//  Created by Willem Bult on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import "TransientTransportDataProvider.h"
#import "MusubiAppTest.h"

@interface EncodingTestBlacklistProvider : NSObject<BlackListProvider> {
    NSArray* blacklist;
}

@property (nonatomic, retain) NSArray* blacklist;
- (id) initWithBlacklist: (NSArray*) list;

@end

@interface EncodingTestSignatureController : NSObject<SignatureController> {
    uint64_t t;
}
@end
    
@interface EncodingTestEncryptionController : NSObject<EncryptionController> {
    uint64_t t;
}
@end

@interface EncodingTest : MusubiAppTest

@end
