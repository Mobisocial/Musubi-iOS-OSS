//
//  MessageListener.h
//  Musubi
//
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnverifiedIdentityProvider.h"
#import "IBEncryptionScheme.h"
#import "TransportManager.h"
#import "AMQPTransport.h"
#import "MEncodedMessage.h"

@interface MessageListener : NSObject {
    UnverifiedIdentityProvider* identityProvider;
    IBEncryptionIdentity* identity;
    TransportManager* transportManager;
    AMQPTransport* transport;
}

@property (nonatomic,retain) UnverifiedIdentityProvider* identityProvider;
@property (nonatomic,retain) IBEncryptionIdentity* identity;
@property (nonatomic,retain) TransportManager* transportManager;
@property (nonatomic,retain) AMQPTransport* transport;

- (id) initWithIdentityProvider: (UnverifiedIdentityProvider*) ip andIdentity: (IBEncryptionIdentity*) i;
- (MEncodedMessage*) waitForMessage:(int)seq during:(NSTimeInterval)interval;
- (void) stop;
@end
