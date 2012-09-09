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

#import "AMQPSenderService.h"
#import "AMQPConnectionManager.h"
#import "AMQPUtil.h"
#import "NSData+Base64.h"

#import "Musubi.h"
#import "IBEncryptionScheme.h"

#import "PersistentModelStore.h"
#import "FeedManager.h"
#import "EncodedMessageManager.h"
#import "MEncodedMessage.h"
#import "MIdentity.h"
#import "MObj.h"

#import "BSONEncoder.h"
#import "Message.h"
#import "Recipient.h"
#import "IdentityManager.h"

@implementation AMQPSenderService

@synthesize declaredGroups = _declaredGroups;
@synthesize connMngr = _connMngr;
@synthesize groupProbeChannel = _groupProbeChannel;

- (id)initWithConnectionManager:(AMQPConnectionManager *)conn storeFactory:(PersistentModelStoreFactory *)sf {
    ObjectPipelineServiceConfiguration* config = [[ObjectPipelineServiceConfiguration alloc] init];
    config.model = @"EncodedMessage";
    config.selector = [NSPredicate predicateWithFormat:@"processed=0 AND outbound=1"];
    config.notificationName = kMusubiNotificationPreparedEncoded;
    config.numberOfQueues = 1;
    config.operationClass = [AMQPSendOperation class];
    
    self = [super initWithStoreFactory:sf andConfiguration:config];
    if (self) {
        self.connMngr = conn;
        self.declaredGroups = [NSMutableSet set];
        self.groupProbeChannel = -1;
    }
    return self;
}

@end 


@implementation AMQPSendOperation

- (BOOL)performOperationOnObject:(NSManagedObject *)object {
    MEncodedMessage* msg = (MEncodedMessage*) object;
    
    AMQPConnectionManager* connMngr = ((AMQPSenderService*) self.service).connMngr;
    
    while (![connMngr connectionIsAlive]){
        [connMngr initializeConnection];
    }

    @try {
        assert(msg.outbound);
        
        int pending = ((AMQPSenderService*) self.service).pending.count;
        connMngr.connectionState = [NSString stringWithFormat: @"Sending %@message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
        
        [self send: msg];
    } @catch (NSException* exception) {
        [self log:@"Crashed in send: %@", exception];
        // Failed to send message, close connection
        [connMngr closeConnection];
        
        return NO;
    }
    
    [self removePending];
    return YES;
}

- (void) send: (MEncodedMessage*) msg {
    Message* m = [BSONEncoder decodeMessage:msg.encoded];
    
    NSMutableArray* ids = [NSMutableArray arrayWithCapacity:[m.r count]];
    NSMutableSet* hidForQueue = [NSMutableSet setWithCapacity:[m.r count]];
    IdentityManager* identityManager = [[IdentityManager alloc] initWithStore:self.store];
    
    
    if (m.r.count > 100) {
        [self log:@"Message to more than 100 people, can't deal with this, discarding"];
        
        [[msg managedObjectContext] deleteObject:msg];
        [[msg managedObjectContext] save:nil];
        return;
    }
    
    for (int i=0; i<m.r.count; i++) {
        IBEncryptionIdentity* ident = [[[IBEncryptionIdentity alloc] initWithKey:((Recipient*)[m.r objectAtIndex:i]).i] keyAtTemporalFrame:0];
        [hidForQueue addObject: ident];
        
        MIdentity* mIdent = [identityManager identityForIBEncryptionIdentity:ident];
        
        [mIdent setPrincipalHash:[ident hashed]];
        [mIdent setType: [ident authority]];
        [self.store save];
        [ids addObject:mIdent];
    }
    
    AMQPSenderService* service = (AMQPSenderService*) self.service;
    
    NSData* groupExchangeNameBytes = [FeedManager fixedIdentifierForIdentities: ids];
    //the original android group exchanges were ibegroup and they were durable.  the non-durable version
    //has a t in the name, for temporary.
    NSString* groupExchangeName = [AMQPUtil queueNameForKey:groupExchangeNameBytes withPrefix:@"ibetgroup-"];
    
    
    if (![service.declaredGroups containsObject:groupExchangeName]) {
        [service.connMngr declareExchange:groupExchangeName onChannel:kAMQPChannelOutgoing passive:NO durable:NO];
        //[self log:@"Creating group exchange: %@", groupExchangeName];
        
        for (IBEncryptionIdentity* recipient in hidForQueue) {
            NSString* dest = [AMQPUtil queueNameForKey:recipient.key withPrefix:@"ibeidentity-"];
            [self log:@"Sending message to %@", dest];
            
            if(service.groupProbeChannel == -1)
                service.groupProbeChannel = [service.connMngr createChannel];
            @try {
                // This will fail if the exchange doesn't exist
                [service.connMngr declareExchange:dest onChannel:service.groupProbeChannel passive:YES durable:YES];
            } @catch (NSException *exception) {
                [service.connMngr closeChannel:service.groupProbeChannel];
                service.groupProbeChannel = -1;
                [self log:@"Identity change was not bound, define initial queue"];
                
                NSString* initialQueueName = [NSString stringWithFormat:@"initial-%@", dest];
                [service.connMngr declareQueue:initialQueueName onChannel:kAMQPChannelOutgoing passive:NO durable:YES exclusive:NO];
                [service.connMngr declareExchange:dest onChannel:kAMQPChannelOutgoing passive:NO durable:YES];
                [service.connMngr bindQueue:initialQueueName toExchange:dest onChannel:kAMQPChannelOutgoing];
            }
            
            //[self log:@"Binding exchange %@ <= exchange %@", dest, groupExchangeName];
            [service.connMngr bindExchange:dest to:groupExchangeName onChannel:kAMQPChannelOutgoing];
        }
        [service.declaredGroups addObject:groupExchangeName];
    }
    
    //[self log:@"Publishing to %@", groupExchangeName];
    
    NSManagedObjectID* msgObjId = msg.objectID;
    [service.connMngr publish:msg.encoded to:groupExchangeName onChannel:kAMQPChannelOutgoing onAck:[^{
        PersistentModelStore* store = [[Musubi sharedInstance] newStore];
        NSError* error;
        
        MEncodedMessage* sentMessage = (MEncodedMessage*)[store.context existingObjectWithID:msgObjId error:&error];
        if (!sentMessage)
            @throw error;
        
        assert(sentMessage.outbound);
        sentMessage.processed = YES;
        
        MObj* obj = (MObj*)[store queryFirst:[NSPredicate predicateWithFormat:@"encoded == %@", msgObjId] onEntity:@"Obj"];
        if (obj) {
            obj.sent = YES;
        }
        
        [store save];
        
        [self log:@"Message acked"];
        
        [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationEncodedMessageSent object:msgObjId]];
        
        if (obj) {
            [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationObjSent object:obj.objectID]];
        }

    } copy]];
}

@end
