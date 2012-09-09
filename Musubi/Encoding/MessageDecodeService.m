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


#import "MessageDecodeService.h"
#import "Musubi.h"

#import "IBEncryptionScheme.h"

#import "MessageDecoder.h"
#import "ObjEncoder.h"
#import "PreparedObj.h"

#import "PersistentModelStore.h"
#import "MusubiDeviceManager.h"
#import "FeedManager.h"
#import "IdentityManager.h"
#import "AccountManager.h"
#import "TransportManager.h"
#import "AppManager.h"
#import "EncryptionUserKeyManager.h"

#import "MEncodedMessage.h"
#import "MEncryptionUserKey.h"
#import "MObj.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "ProfileObj.h"

#import "IncomingMessage.h"
#import "MDevice.h"

@implementation MessageDecodeService

@synthesize identityProvider = _identityProvider;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andIdentityProvider:(id<IdentityProvider>)ip {
    ObjectPipelineServiceConfiguration* config = [[ObjectPipelineServiceConfiguration alloc] init];
    config.model = @"EncodedMessage";
    config.selector = [NSPredicate predicateWithFormat:@"(processed == NO) AND (outbound == NO)"];
    config.notificationName = kMusubiNotificationEncodedMessageReceived;
    config.numberOfQueues = 1;
    config.operationClass = [MessageDecodeOperation class];
    
    self = [super initWithStoreFactory:sf andConfiguration:config];
    if (self) {
        _identityProvider = ip;
    }
    return self;
}

@end


@implementation MessageDecodeOperation

static int operationCount;

@synthesize dirtyFeeds = _dirtyFeeds, shouldRunProfilePush = _shouldRunProfilePush;
@synthesize deviceManager = _deviceManager, transportManager = _transportManager, identityManager = _identityManager, feedManager = _feedManager, accountManager = _accountManager, appManager = _appManager, decoder = _decoder;

- (id)initWithObjectId:(NSManagedObjectID *)objId andService:(ObjectPipelineService *)service {
    self = [super initWithObjectId:objId andService:service];
    if (self) {
        self.dirtyFeeds = [NSMutableArray array];
    }
    return self;
}

+ (int) operationCount {
    return operationCount;
}

- (BOOL)performOperationOnObject:(NSManagedObject *)object {
    operationCount += 1;

    @try {
        // Get the obj and decode it
        NSError* error = nil;
        MEncodedMessage* msg = (MEncodedMessage*)[self.store.context existingObjectWithID:self.objId error:&error];
        
        if (error != nil) {
            @throw error;
        }
        
        id<IdentityProvider> identityProvider = ((MessageDecodeService*) self.service).identityProvider;
        
        if (msg) {
            [self setDeviceManager: [[MusubiDeviceManager alloc] initWithStore: self.store]];
            [self setTransportManager: [[TransportManager alloc] initWithStore: self.store encryptionScheme: identityProvider.encryptionScheme signatureScheme:identityProvider.signatureScheme deviceName:[_deviceManager localDeviceName]]];
            [self setIdentityManager: _transportManager.identityManager];
            [self setFeedManager: [[FeedManager alloc] initWithStore: self.store]];
            [self setAccountManager: [[AccountManager alloc] initWithStore: self.store]];
            [self setAppManager: [[AppManager alloc] initWithStore: self.store]];        
            [self setDecoder: [[MessageDecoder alloc] initWithTransportDataProvider:_transportManager]];
            
            [self decodeMessage:msg];
            [self removePending];
            return YES;
        }
    } @catch (NSException* e) {
        [self log:@"Error: %@", e];
    } @catch (NSError* e) {
        [self log:@"Error: %@", e];
    } @finally {
        operationCount--;

        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationMessageDecodeFinished object:nil];        
    }
    return NO;
}

- (BOOL) decodeMessage: (MEncodedMessage*) msg {
    if (msg == nil)
        @throw [NSException exceptionWithName:kMusubiExceptionUnexpected reason:@"Message was nil!" userInfo:nil];
    
    id<IdentityProvider> identityProvider = ((MessageDecodeService*) self.service).identityProvider;
    
    assert (msg != nil);
    IncomingMessage* im = nil;
    @try {
        im = [_decoder decodeMessage:msg];
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:kMusubiExceptionNeedEncryptionUserKey]) {
            
            @try {
                IBEncryptionIdentity* errId = (IBEncryptionIdentity*)[exception.userInfo objectForKey:@"identity"];
                if (errId) {
                    [self log:@"Getting new encryption key for %@", errId];
                    
                    MIdentity* to = [_identityManager identityForIBEncryptionIdentity:errId];
                    IBEncryptionUserKey* userKey = [identityProvider encryptionKeyForIdentity:errId];
                    
                    if (userKey) {
                        EncryptionUserKeyManager* cryptoUserKeyMgr = _transportManager.encryptionUserKeyManager;
                        MEncryptionUserKey* cryptoKey = (MEncryptionUserKey*)[cryptoUserKeyMgr create];
                        [cryptoKey setIdentity: to];
                        [cryptoKey setPeriod: errId.temporalFrame];
                        [cryptoKey setKey: userKey.raw];
                        [self.store save];
                        
                        // Try again, should work now :)
                        im = [_decoder decodeMessage:msg];
                    } else {
                        @throw exception;
                    }
                } else {
                    @throw exception;
                }
                
            }
            @catch (NSException *exception) {
                [self log:@"Failed to decode message beause a user key was required for %@: %@", msg.fromIdentity, exception];
                /*TODO: refresh key
                 if(mKeyUpdateHandler != null) {
                 if (DBG) Log.i(TAG, "Updating key for identity #" + e.identity_, e);
                 mKeyUpdateHandler.requestEncryptionKey(e.identity_);
                 }*/
//                [_store save];
                return true;
            }
        } else if ([exception.name isEqualToString:kMusubiExceptionDuplicateMessage]){
            
            MDevice* from = [[exception userInfo] objectForKey:@"from"];
            
            // RabbitMQ does not support the "no deliver to self" routing policy.
            // don't log self-routed device duplicates, everything else we want to know about
            if (from.deviceName != _deviceManager.localDeviceName) {
                [self log:@"Failed to decode message %@: %@", msg.objectID, exception];
            }
            
            [self.store.context deleteObject:msg];
            [self.store save];
            return YES;
            
        } else {
            [self log:@"Failed to decode message: %@: %@", msg.objectID, exception];
            [self.store.context deleteObject:msg];
            [self.store save];
            return YES;
        }
    }
        
    
    MDevice* device = im.fromDevice;
    MIdentity* sender = im.fromIdentity;
    BOOL whiteListed = YES; //TODO: whitelisting (sender.owned || sender.whitelisted);
    

    PreparedObj* obj = nil;
    @try {
        obj = [ObjEncoder decodeObj: im.data];
    } @catch (NSException *exception) {
        [self log:@"Failed to decode message %@: %@", im, exception];
        [self.store.context deleteObject:msg];
        [self.store save];
        return YES;
    }
    
    // Look for profile updates, which don't require whitelisting
    if ([obj.type isEqualToString:kObjTypeProfile]) {
        //never even make it an MObj
        [ProfileObj handleFromSender:sender profileJson:obj.jsonSrc profileRaw:obj.raw withStore:self.store];
        
        [self log:@"Message was profile message %@", obj];
        [self.store.context deleteObject:msg];
        [self.store save];
        return true;
    }

    // Handle feed details
    
    if (obj.feedType == kFeedTypeFixed) {
        // Fixed feeds have well-known capabilities.
        NSData* computedCapability = [FeedManager fixedIdentifierForIdentities: im.recipients];
        if (![computedCapability isEqualToData:obj.feedCapability]) {
            [self log:@"Capability mismatch"];
            [self.store.context deleteObject:msg];
            [self.store save];
            return YES;
        }
    }

    MFeed* feed = nil;
    BOOL asymmetric = NO;
    if (obj.feedType == kFeedTypeAsymmetric || obj.feedType == kFeedTypeOneTimeUse) {
        // Never create well-known broadcast feeds
        feed = [_feedManager global];
        asymmetric = YES;
    } else {
        feed = [_feedManager feedWithType: obj.feedType andCapability: obj.feedCapability];
    }

    
    if (feed == nil) {
        MFeed* newFeed = (MFeed*)[_feedManager create];
        [newFeed setCapability: obj.feedCapability];
        if (newFeed.capability) {
            [newFeed setShortCapability: *(uint64_t*) newFeed.capability.bytes];
        }
        [newFeed setType: obj.feedType];
        [newFeed setAccepted: whiteListed];
        //NSError* error = nil;
        //[self.store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:newFeed] error:&error];
        [self.store save];
        
        [_feedManager attachMember: sender toFeed:newFeed];
        
        for (MIdentity* recipient in im.recipients) {
            BOOL added = [_feedManager attachMember: recipient toFeed: newFeed];
            
             // Send a profile request if we don't have one from them yet
             if (added) {
                 _shouldRunProfilePush = YES;
             }
        }
                
        feed = newFeed;
    } else {
        if (!feed.accepted && whiteListed && !asymmetric) {
            feed.accepted = YES;
            [_dirtyFeeds addObject:feed];
        }
        if (feed.type == kFeedTypeExpanding) {
            NSArray* res = [self expandMembershipOfFeed: feed forRecipients: im.recipients andPersonas: im.personas];
            if (((NSNumber*)[res objectAtIndex:0]).boolValue) {
                [_dirtyFeeds addObject: feed];
            }
            _shouldRunProfilePush |= ((NSNumber*)[res objectAtIndex:1]).boolValue;
        }
    }
    
    MObj* mObj = (MObj*)[self.store createEntity:@"Obj"]; 
    MApp* mApp = [_appManager ensureAppWithAppId: obj.appId];
    NSData* uHash = [ObjEncoder computeUniversalHashFor:im.hash from:sender onDevice:device];
    
    [mObj setFeed:feed];
    [mObj setIdentity: device.identity];
    [mObj setDevice: device];
    [mObj setParent: nil];
    [mObj setApp: mApp];
    [mObj setTimestamp: [NSDate dateWithTimeIntervalSince1970:obj.timestamp / 1000]];
    [mObj setUniversalHash: uHash];
    [mObj setShortUniversalHash: *(uint64_t*)uHash.bytes];
    [mObj setType: obj.type];
    [mObj setJson: obj.jsonSrc];
    [mObj setRaw: obj.raw];
    [mObj setIntKey:obj.intKey];
    [mObj setStringKey:obj.stringKey];
    [mObj setLastModified: [NSDate dateWithTimeIntervalSince1970:obj.timestamp / 1000]];
    [mObj setEncoded: msg];
    [mObj setDeleted: NO];
    [mObj setRenderable: NO];
    [mObj setProcessed: NO];
    [mObj setSent: YES];
    
    // Grant app access
    if (![_appManager isSuperApp: mApp]) {
        [_feedManager attachApp: mApp toFeed: feed];
    }
    
    // Finish up
    [msg setProcessed: YES];
    [msg setProcessedTime: [NSDate date]];
    
    /*NSError* error;
    if (![self.store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:mObj] error:&error])
        @throw error;
    */

    [self.store save];        

    // Notify the ObjPipeline
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationAppObjReady object:mObj.objectID]];
    
    [self log:@"Decoded: %@", mObj.objectID];
    if(_shouldRunProfilePush) {
        [self log:@"Detected new identities, pinging them"];
        NSMutableArray* new_peeps = [NSMutableArray arrayWithCapacity:im.recipients.count];
        for (MIdentity* recipient in im.recipients) {
            if(recipient.receivedProfileVersion != 0)
                continue;
            [new_peeps addObject:recipient];
        }
        [ProfileObj sendProfilesTo:new_peeps replyRequested:YES withStore:self.store];
    }
    
    return YES;
}

- (NSArray*) expandMembershipOfFeed: (MFeed*) feed forRecipients: (NSArray*) recipients andPersonas: (NSArray*) personas {
    
    NSMutableDictionary* participants = [NSMutableDictionary dictionaryWithCapacity:recipients.count];
    for (MIdentity* participant in recipients) {
        [participants setObject:participant forKey:participant.objectID];
    }
    
    for (MIdentity* existing in [_feedManager identitiesInFeed: feed]) {
        [participants removeObjectForKey: existing.objectID];
    }
    /* TODO: whitelist
    NSMutableArray* provisionalAccounts = [NSMutableArray arrayWithCapacity: personas.count];
    NSMutableArray* whitelistAccounts = [NSMutableArray arrayWithCapacity: personas.count];
    
    for (MIdentity* persona in personas) {
        [provisionalAccounts addObject:[thread.accountManager provisionalWhitelistForIdentity: persona]];
        [whitelistAccounts addObject:[thread.accountManager whitelistForIdentity: persona]];
    }*/
    
    BOOL shouldRunProfilePushBecauseOfExpand = NO;
    for (MIdentity* participant in participants.allValues) {
        BOOL added = [_feedManager attachMember:participant toFeed:feed];
        
        // Send a profile request if we don't have one from them yet
        if (added) {
            shouldRunProfilePushBecauseOfExpand = YES;
        }
        
        /* TODO: whitelist 
        if (feed.accepted) {
            for (int i=0; i<personas.count; i++) {
                shouldRunProfilePush |= [thread.feedManager addRecipient: participant toWhitelistsIfNecessaryWithProvisional: [provisionalAccounts objectAtIndex:i] whitelist: [whitelistAccounts objectAtIndex:i] andPersona: [personas objectAtIndex:i]];
            }
        }*/
    }
    
    return [NSArray arrayWithObjects:[NSNumber numberWithBool:participants.count > 0], [NSNumber numberWithBool: shouldRunProfilePushBecauseOfExpand], nil];
}

@end