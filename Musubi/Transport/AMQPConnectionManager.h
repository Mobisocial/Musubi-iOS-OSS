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

#import <Foundation/Foundation.h>
#import "amqp.h"
#import "amqp_framing.h"
#import "utils.h"

#define kAMQPChannelIncoming 1
#define kAMQPChannelOutgoing 2

#define kAMQPConnectionException @"AMQPConnectionException"

@class Reachability;

@interface AMQPConnectionManager : NSObject {
    amqp_connection_state_t conn;
    
    int last_channel;
    BOOL connectionReady;
    uint32_t sequenceNumber;
    uint64_t lastIncomingDeliveryTag;
    
    Reachability* _reachability;
}

@property (nonatomic, strong) NSRecursiveLock* connLock;
@property (atomic, strong) NSString* connectionState;
@property (nonatomic, assign) int connectionAttempts;
@property (nonatomic, strong) Reachability* reachability;

- (BOOL) connectionIsAlive;
- (void) initializeConnection;
- (void) closeConnection;

- (void) amqpCheckReplyInContext: (NSString*) context;
- (NSString*) amqpErrorMessageFor: (amqp_rpc_reply_t) x inContext: (NSString*) context;
- (int) createChannel;
- (void) closeChannel: (int) channel;
- (amqp_bytes_t) declareQueue: (NSString*) queue onChannel: (int) channel passive: (BOOL) passive durable:(BOOL)durable exclusive:(BOOL)exclusive;
- (void) deleteQueue: (NSString*) queue onChannel: (int) channel;
- (BOOL) declareExchange: (NSString*) exchange onChannel: (int) channel passive: (BOOL) passive durable:(BOOL)durable;
- (void) deleteExchange: (NSString*) exchange onChannel: (int) channel;
- (void) bindQueue: (NSString*) queue toExchange: (NSString*) exchange onChannel: (int) channel;
- (void) unbindQueue: (NSString*) queue fromExchange: (NSString*) exchange onChannel: (int) channel;
- (void) bindExchange: (NSString*) dest to: (NSString*) src onChannel: (int) channel;
- (void) publish: (NSData*) data to: (NSString*) dest onChannel: (int) channel onAck:(void(^)())onAck;
//- (void)consumeFromQueue:(amqp_bytes_t)queue onChannel:(int)channel;
- (void)consumeFromQueue:(NSString*)queue onChannel:(int)channel nolocal:(BOOL)nolocal exclusive:(BOOL)exclusive;
- (NSData*) readMessageAndCall:(void(^)())block after:(NSDate*) date;
- (void) ackMessage: (int) deliveryTag onChannel: (int) channel;
- (uint32_t) nextSequenceNumber;
- (uint64_t) lastIncomingSequenceNumber;
@end
