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

#import "AMQPConnectionManager.h"
#import "MEncodedMessage.h"
#import "BSONEncoder.h"
#import "IBEncryptionScheme.h"
#import "Recipient.h"
#import "MIdentity.h"
#import "PersistentModelStore.h"
#import "APNPushManager.h"
#import "Musubi.h"
#include <sys/socket.h>
#import "Reachability.h"

#define kMusubiAMQPServerHost @"bumblebee.musubi.us"

@implementation AMQPConnectionManager {
    NSMutableArray* pending;
}

@synthesize connLock, connectionState, connectionAttempts, reachability;

- (id)init {
    self = [super init];
    if (!self) return nil;

    [self setConnLock: [[NSRecursiveLock alloc] init]];
    conn = nil;
    connectionReady = NO;
    connectionAttempts = 0;
    pending = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.reachability = [Reachability reachabilityWithHostName:kMusubiAMQPServerHost];
    [self.reachability startNotifier];
    
    return self;
}

- (void) reachabilityChanged: (Reachability*) r {
    NSLog(@"OK!?");
}


- (void) amqpCheckReplyInContext: (NSString*) context {
    if (amqp_get_rpc_reply(conn).reply_type != AMQP_RESPONSE_NORMAL) {
        [connLock unlock];
        NSString* reason = [self amqpErrorMessageFor: amqp_get_rpc_reply(conn) inContext: context];
        //NSLog(@"AMQP Exception: %@", reason);
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: reason userInfo: nil];
    }
}

- (NSString*) amqpErrorMessageFor: (amqp_rpc_reply_t) x inContext: (NSString*) context {
    switch (x.reply_type) {
        case AMQP_RESPONSE_NORMAL:
            return nil;
            
        case AMQP_RESPONSE_NONE:
            return [NSString stringWithFormat:@"%@: missing RPC reply type!", context];
            
        case AMQP_RESPONSE_LIBRARY_EXCEPTION:
            return [NSString stringWithFormat:@"%@: %s", context, amqp_error_string(x.library_error)];       
            
        case AMQP_RESPONSE_SERVER_EXCEPTION:
            switch (x.reply.id) {
                case AMQP_CONNECTION_CLOSE_METHOD: {
                    amqp_connection_close_t *m = (amqp_connection_close_t *) x.reply.decoded;
                    return [NSString stringWithFormat:@"%@: server connection error %d, message: %.*s", context,
                            m->reply_code,
                            (int) m->reply_text.len, (char *) m->reply_text.bytes];
                }
                case AMQP_CHANNEL_CLOSE_METHOD: {
                    amqp_channel_close_t *m = (amqp_channel_close_t *) x.reply.decoded;
                    return [NSString stringWithFormat:@"%@: server channel error %d, message: %.*s", context,
                            m->reply_code,
                            (int) m->reply_text.len, (char *) m->reply_text.bytes];
                }
                default:
                    return [NSString stringWithFormat:@"%@: unknown server error, method id 0x%08X", context,
                            x.reply.id];
            }
    }
    return nil;
}

- (BOOL)connectionIsAlive {
    return connectionReady;
}

- (void) initializeConnection {
    //TODO: Check to see if there already is an open connection
    [connLock lock];
    if (connectionReady) {
        NSLog(@"Already connected when initializing connection");
        [connLock unlock];
        return;
    }
    [pending removeAllObjects];
    
    //threads wake up ok after a sudden background transition but sockets
    //dont do so well.
    //we close out the connection in the backgorund expiration callback
    //which will trigger a reconnect. 
    //we want to block that reconnect if the connection is just going to 
    //jam up if it suceeds fast enough
    BOOL message_set = NO;
    while([UIApplication sharedApplication].backgroundTimeRemaining < 15) {
        if(!message_set)  {
            self.connectionState = @"Restarting...";
            message_set = YES;
        }
        [NSThread sleepForTimeInterval:0.5];
    }

    self.connectionState = @"Offline. Waiting to reconnect...";
    [NSThread sleepForTimeInterval: MIN(60, powl(2, connectionAttempts) - 1)];
    self.connectionState = @"Connecting...";
    connectionAttempts++;
    
    
    //NSLog(@"Connecting to AMQP");
    amqp_connection_state_t new_conn = amqp_new_connection();
    
    //TODO: Listen for connection close and terminate
    //amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    //        amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    //        amqp_destroy_connection(conn);
    
    // Open socket to AMQP server
    int sockfd = amqp_open_socket([kMusubiAMQPServerHost UTF8String], 5672);
    if (sockfd < 0) {
        amqp_destroy_connection(new_conn);
        [connLock unlock];
        return;
    }
    int set = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
    amqp_set_sockfd(new_conn, sockfd);
    
    // Login to server using default username/password
    amqp_login(new_conn, "/", 0, 131072, 30, AMQP_SASL_METHOD_PLAIN, "guest", "guest");
    
    /*if (reply.reply_type != AMQP_REPLY_SUCCESS) {
     NSLog(@"Login fail");
     amqp_destroy_connection(conn);
     return nil;
     }*/
    
    NSLog(@"AMQPConnectionManager: Connected");
    conn = new_conn;
    
    // Open channels
    amqp_channel_open(new_conn, kAMQPChannelIncoming);
    [self amqpCheckReplyInContext:@"Opening incoming channel"];
    amqp_confirm_select(conn, kAMQPChannelIncoming);

    amqp_channel_open(new_conn, kAMQPChannelOutgoing);
    [self amqpCheckReplyInContext:@"Opening outgoing channel"];
    amqp_confirm_select(conn, kAMQPChannelOutgoing);

    last_channel = 2;
    connectionReady = YES;
    connectionAttempts = 0;
    
    [connLock unlock];
}

- (void) closeConnection {
    [connLock lock];
    
    if (conn) {
        amqp_channel_close(conn, kAMQPChannelIncoming, AMQP_REPLY_SUCCESS);
        amqp_channel_close(conn, kAMQPChannelOutgoing, AMQP_REPLY_SUCCESS);
        amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
        amqp_destroy_connection(conn);
    }
    
    conn = nil;
    connectionReady = NO;
    self.connectionState = @"Disconnected";
    
    [connLock unlock];
    
    NSLog(@"AMQPConnectionManager: Disconnected");
}

- (int)createChannel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    amqp_channel_open(conn, ++last_channel);
    [self amqpCheckReplyInContext:@"Opening new channel"];
    
    amqp_confirm_select(conn, last_channel);
    
    [connLock unlock];
    
    return last_channel;
}

- (void) closeChannel: (int) channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    amqp_channel_close(conn, channel, AMQP_REPLY_SUCCESS);
    
    [connLock unlock];
}

- (amqp_bytes_t) declareQueue: (NSString*) queue onChannel: (int) channel passive: (BOOL) passive  durable:(BOOL)durable exclusive:(BOOL)exclusive{
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* name = [queue cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_queue_declare_ok_t* res = amqp_queue_declare(conn, channel, amqp_cstring_bytes(name), passive ? 1 : 0, durable ? 1 : 0, exclusive ? 1 : 0, 0, amqp_empty_table);
    [self amqpCheckReplyInContext:@"Declaring queue"];
    
    amqp_bytes_t q = amqp_bytes_malloc_dup(res->queue);
    
    [connLock unlock];
    
    return q;
}

- (void) deleteQueue: (NSString*) queue onChannel: (int) channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* name = [queue cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_queue_delete(conn, channel, amqp_cstring_bytes(name), NO, NO);
    [self amqpCheckReplyInContext:@"Deleting queue"];

    [connLock unlock];
}

- (BOOL) declareExchange: (NSString*) exchange onChannel: (int) channel passive: (BOOL) passive durable:(BOOL)durable{
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* name = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_exchange_declare_ok_t* res = amqp_exchange_declare(conn, channel, amqp_cstring_bytes(name), amqp_cstring_bytes("fanout"), passive ? 1 : 0, durable ? 1 : 0, amqp_empty_table);
    
    [self amqpCheckReplyInContext:@"Declaring exchange"];

    [connLock unlock];
    
    return res != NULL;
}

- (void) deleteExchange: (NSString*) exchange onChannel: (int) channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* name = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_exchange_delete(conn, channel, amqp_cstring_bytes(name), NO);
    [self amqpCheckReplyInContext:@"Deleting exchange"];
    
    [connLock unlock];
}

- (void) bindQueue: (NSString*) queue toExchange: (NSString*) exchange onChannel: (int) channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* queueName = [queue cStringUsingEncoding:NSUTF8StringEncoding];
    const char* exchangeName = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_queue_bind(conn, channel, amqp_cstring_bytes(queueName), amqp_cstring_bytes(exchangeName), amqp_cstring_bytes(""), amqp_empty_table);
    [self amqpCheckReplyInContext:@"Binding queue"];
    
    [connLock unlock];
}

- (void) unbindQueue: (NSString*) queue fromExchange: (NSString*) exchange onChannel: (int) channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* queueName = [queue cStringUsingEncoding:NSUTF8StringEncoding];
    const char* exchangeName = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_queue_unbind(conn, channel, amqp_cstring_bytes(queueName), amqp_cstring_bytes(exchangeName), amqp_cstring_bytes(""), amqp_empty_table);
    [self amqpCheckReplyInContext:@"Unbinding queue"];
    
    [connLock unlock];
}

- (void) bindExchange: (NSString*) dest to: (NSString*) src onChannel: (int) channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* destName = [dest cStringUsingEncoding:NSUTF8StringEncoding];
    const char* srcName = [src cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_exchange_bind(conn, channel, amqp_cstring_bytes(destName), amqp_cstring_bytes(srcName), amqp_cstring_bytes(""), amqp_empty_table);
    [self amqpCheckReplyInContext:@"Binding exchange"];
    
    [connLock unlock];
}

- (void)consumeFromQueue:(NSString*)queue onChannel:(int)channel nolocal:(BOOL)nolocal exclusive:(BOOL)exclusive {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    // Consume from the queue
    const char* queueName = [queue cStringUsingEncoding:NSUTF8StringEncoding];
    
    amqp_basic_consume(conn, channel, amqp_cstring_bytes(queueName), amqp_empty_bytes, nolocal ? 1 : 0, 0, exclusive ? 1 : 0, amqp_empty_table);
    [self amqpCheckReplyInContext:@"Basic consume"];
    
    [connLock unlock];
}

- (NSData*) readMessageAndCall:(void(^)())block after:(NSDate*) date {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    int sock = amqp_get_sockfd(conn);
    
    while(amqp_frames_enqueued(conn) == 0 && amqp_data_in_buffer(conn) == 0) {
        fd_set read_flags, error_flags;
        FD_ZERO(&read_flags);
        FD_ZERO(&error_flags);
        FD_SET(sock, &read_flags);
        FD_SET(sock, &error_flags);
        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 50000;

        //dont freeze the connection while waiting for data
        [connLock unlock];
        // we have no frames in buffer and we don't want to block
        // check the socket to see if we can read from it without blocking
        int res = select(sock+1, &read_flags, NULL, &error_flags, &timeout);
        if (FD_ISSET(sock, &error_flags)) {
            @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection error during select" userInfo: nil];
        }
            
        [connLock lock];
        if (res <= 0) {
            if(self.connectionState && [self.connectionState rangeOfString:@"Sending"].location == NSNotFound)
                self.connectionState = nil;
        }
        if (!connectionReady) {
            [connLock unlock];
            @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
        }
        timeout.tv_sec = 0;
        timeout.tv_usec = 0;
        //double check that we have something available
        res = select(sock+1, &read_flags, NULL, NULL, &timeout);
        if (res > 0) {
            break;
        }
        if(self.connectionState && [self.connectionState rangeOfString:@"Sending"].location == NSNotFound)
            self.connectionState = nil;
        if(date && block && [[NSDate date] timeIntervalSinceDate:date] > 0) {
            //send a heart beat whenever the receive timer runs out
            amqp_frame_t f;
            f.frame_type = AMQP_FRAME_HEARTBEAT;
            f.channel = 0;
            //date must always be < heartbeat request time submitted to the server
            int res = amqp_send_frame(conn, &f);
            [connLock unlock];
            if (res < 0) {
                @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Error sending heartbeat" userInfo:nil];
            }

            block();
            return nil;
        }
    }
    @try {
        amqp_frame_t frame;
        int result;
        size_t body_received;
        size_t body_target;
        
        
        amqp_maybe_release_buffers(conn);
        result = amqp_simple_wait_frame(conn, &frame);
        
        if (result < 0) {
            @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Got error waiting for frame" userInfo:nil];
        } else if (frame.frame_type == AMQP_FRAME_HEARTBEAT) {
            amqp_frame_t f;
            f.frame_type = AMQP_FRAME_HEARTBEAT;
            f.channel = 0;
            int res = amqp_send_frame(conn, &f);
            if (res < 0) {
                @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Error sending heartbeat" userInfo:nil];
            }
            [connLock unlock];
            return nil;
        } else if (frame.frame_type != AMQP_FRAME_METHOD) {
            [self closeConnection];
            @throw [NSException exceptionWithName:kAMQPConnectionException reason:[NSString stringWithFormat: @"Unhandled AMQP frame %d", frame.frame_type] userInfo:nil];
        } else if (frame.payload.method.id == AMQP_BASIC_ACK_METHOD) {
            if(pending.count == 0)
                @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Unexpected basic ack from broker" userInfo:nil];
            void (^ack_block)()  = (void(^)())[pending objectAtIndex:0];
            [pending removeObjectAtIndex:0];
            [connLock unlock];
            ack_block();
            return nil;
        } else if (frame.payload.method.id == AMQP_CHANNEL_CLOSE_METHOD) {
            [self closeConnection];
            @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Unexpected channel close from broker" userInfo:nil];
        } else if (frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD) {            
            [self closeConnection];
            @throw [NSException exceptionWithName:kAMQPConnectionException reason:[NSString stringWithFormat: @"Unhandled AMQP method %d", frame.payload.method.id] userInfo:nil];
        }
        
        lastIncomingDeliveryTag = ((amqp_basic_deliver_t*) frame.payload.method.decoded)->delivery_tag;
        
        result = amqp_simple_wait_frame(conn, &frame);
        if (result < 0) {
            @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Got error waiting for frame" userInfo:nil];
        }
        
        if (frame.frame_type != AMQP_FRAME_HEADER) {
            @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Expected frame header but got something else" userInfo:nil];
        }
        
        self.connectionState = @"Retrieving messages...";

        body_target = frame.payload.properties.body_size;
        body_received = 0;
        
        NSMutableData* messageData = [NSMutableData data];
        
        while (body_received < body_target) {
            result = amqp_simple_wait_frame(conn, &frame);
            if (result < 0) {
                @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Got error waiting for frame" userInfo:nil];
            }
            
            if (frame.frame_type != AMQP_FRAME_BODY) {
                @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Expected body" userInfo:nil];
            }
            
            body_received += frame.payload.body_fragment.len;
            [messageData appendBytes:frame.payload.body_fragment.bytes length:frame.payload.body_fragment.len];
            assert(body_received <= body_target);
        }
        
        [connLock unlock];
        return messageData;
        
    } @catch (NSException* exception) {
        NSLog(@"AMQP exception: %@", exception);
        [connLock unlock];
        @throw exception;
    }

}

- (void) publish: (NSData*) data to: (NSString*) dest onChannel: (int) channel onAck:(void(^)())onAck
{
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    const char* destName = [dest cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Publish the data on the exchange 
    amqp_bytes_t message;
    message.bytes = (void*) [data bytes];
    message.len = [data length];
    
    int result = amqp_basic_publish(conn, channel, amqp_cstring_bytes(destName), amqp_cstring_bytes(""), 1, 0, NULL, message);
    if (result != 0) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Error while publishing" userInfo:nil];
    }
    [pending addObject:onAck];
    sequenceNumber++;
    
    [connLock unlock];
}

- (void)ackMessage:(int)deliveryTag onChannel:(int)channel {
    [connLock lock];
    if (!connectionReady) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason: @"Connection not ready" userInfo: nil];
    }
    
    int result = amqp_basic_ack(conn, channel, deliveryTag, FALSE);
    if (result != 0) {
        [connLock unlock];
        @throw [NSException exceptionWithName:kAMQPConnectionException reason:@"Error while acking" userInfo:nil];
    }

    [connLock unlock];
}

- (uint32_t)nextSequenceNumber {
    return sequenceNumber;
}

- (uint64_t)lastIncomingSequenceNumber {
    return lastIncomingDeliveryTag;
}

@end
