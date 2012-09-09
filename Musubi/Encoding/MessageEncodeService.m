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


#import "MessageEncodeService.h"

#import "NSData+Crypto.h"

#import "Musubi.h"

#import "PersistentModelStore.h"
#import "MusubiDeviceManager.h"
#import "TransportManager.h"
#import "SignatureUserKeyManager.h"
#import "IBEncryptionScheme.h"
#import "FeedManager.h"
#import "IdentityManager.h"
#import "EncodedMessageManager.h"

#import "MObj.h"
#import "MFeed.h"
#import "MDevice.h"
#import "MIdentity.h"
#import "MApp.h"
#import "MFeedMember.h"
#import "MSignatureUserKey.h"
#import "MEncodedMessage.h"

#import "NSData+Crypto.h"
#import "MessageEncoder.h"
#import "ObjEncoder.h"
#import "OutgoingMessage.h"
#import "Authorities.h"
#import "ProfileObj.h"
#import "DeleteObj.h"
#import "LikeObj.h"
#import "ObjectPipelineService.h"

#define kSmallProcessorCutOff 20

@implementation MessageEncodeService

@synthesize identityProvider = _identityProvider;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andIdentityProvider:(id<IdentityProvider>)ip {
    PersistentModelStore* store = [self.storeFactory newStore];
    
    int (^selectQueue)(NSManagedObject* obj) =  ^(NSManagedObject* obj) {
        MObj* mObj = (MObj*) obj;
        if ([mObj.feed.name isEqualToString:kFeedNameGlobalWhitelist] && mObj.feed.type == kFeedTypeAsymmetric) {
            return 0;
        } else {
            NSArray* members = [store query:[NSPredicate predicateWithFormat:@"feed = %@", mObj.feed] onEntity:@"FeedMember"];
            if (members.count > kSmallProcessorCutOff) {
                return 0;
            } else {
                return 1;
            }
        }
    };
    
    ObjectPipelineServiceConfiguration* config = [[ObjectPipelineServiceConfiguration alloc] init];
    config.model = @"Obj";
    config.selector = [NSPredicate predicateWithFormat:@"(encoded == nil) AND (sent == NO)"];
    config.notificationName = kMusubiNotificationPlainObjReady;
    config.numberOfQueues = 2;
    config.queueSelector = selectQueue;
    config.operationClass = [MessageEncodeOperation class];

    self = [super initWithStoreFactory:sf andConfiguration:config];
    if (self) {
        _identityProvider = ip;
    }
    return self;
}

@end

@implementation MessageEncodeOperation

- (BOOL)performOperationOnObject:(NSManagedObject *)object {
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationMessageEncodeStarted object:nil];

    MObj* obj = (MObj*) object;
    
    FeedManager * feedManager = [[FeedManager alloc] initWithStore:self.store];
    IdentityManager * identityManager = [[IdentityManager alloc] initWithStore:self.store];
    
    // Make sure we have all the required inputs
    assert(obj != nil);
    
    MFeed* feed = obj.feed;
    assert(feed != nil);
    
    MIdentity* sender = obj.identity;
    assert(sender != nil);
    
    BOOL localOnly = sender.type == kIdentityTypeLocal;
    if (!localOnly && !sender.owned) {
        EncodedMessageManager* emm = [[EncodedMessageManager alloc] initWithStore:self.store];
        MEncodedMessage* encoded = [emm create];
        obj.encoded = encoded;
        encoded.processed = YES;
        encoded.outbound = NO;
        [self.store save];
        return YES;
    }
    
    MApp* app = obj.app;
    assert (app != nil);
    
    NSMutableArray* recipients = [NSMutableArray array];
    if(feed.type == kFeedTypeAsymmetric && [feed.name isEqualToString:kFeedNameGlobalWhitelist]) {
        recipients = [NSMutableArray arrayWithArray:[identityManager claimedIdentities]];
    } else {
        for (MFeedMember* fm in [self.store query:[NSPredicate predicateWithFormat:@"feed = %@", feed] onEntity:@"FeedMember"]) {
            [recipients addObject: fm.identity];
        }
    }
    // Create the OutgoingMessage    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    PreparedObj* outbound = [ObjEncoder prepareObj:obj forFeed:feed andApp:app];
    
    if (feed.type == kFeedTypeAsymmetric || feed.type == kFeedTypeOneTimeUse) {
        // When broadcasting a message to all friends, don't
        // Leak friend of friend information
        om.blind = YES;
    }
    if([obj.type isEqualToString:kObjTypeDelete] || [obj.type isEqualToString:kObjTypeLike]) {
        //these two renderable obj never need to expand the set of members, and this
        //lets us use the blind flag to help get rid of annoying notifications
        om.blind = YES;
    }
    
    [om setData: [ObjEncoder encodeObj:outbound]];
    [om setFromIdentity: sender];
    // TODO: insert actual app id here
    [om setApp: [[@"musubi.mobisocial.stanford.edu" dataUsingEncoding:NSUTF8StringEncoding] sha256Digest]];
    [om setRecipients: recipients];
    
    // Remove any blocked people
    for (MIdentity* ident in om.recipients) {
        if (ident.blocked) {
            NSMutableArray* newRcpts = [NSMutableArray arrayWithCapacity:om.recipients.count - 1];
            for (MIdentity* mId in om.recipients) {
                if (!mId.blocked) {
                    [newRcpts addObject:mId];
                }
            }
            
            [om setRecipients: newRcpts];
            break;
        }
    }
    
    [om setHash: [om.data sha256Digest]];
    
    // Universal hash it, must happen before the encoding step so
    // Local messages can still run through the pipeline
    MusubiDeviceManager* deviceManager = [[MusubiDeviceManager alloc] initWithStore:self.store];
    MDevice* device = obj.device;
    assert (device.deviceName == [deviceManager localDeviceName]);
    
    [obj setUniversalHash: [ObjEncoder computeUniversalHashFor:om.hash from:sender onDevice:device]];
    [obj setShortUniversalHash: *(uint64_t*)obj.universalHash.bytes];
    
    
    if (localOnly) {
        return YES;
    }
    
    id<IdentityProvider> identityProvider = ((MessageEncodeService*)self.service).identityProvider;
    TransportManager* transportManager = [[TransportManager alloc] initWithStore:self.store encryptionScheme:identityProvider.encryptionScheme signatureScheme:identityProvider.signatureScheme deviceName:deviceManager.localDeviceName];
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:transportManager];
    MEncodedMessage* encoded = nil;
    
    BOOL success = NO;
    
    @try {
        encoded = [encoder encodeOutgoingMessage:om];        
        success = YES;
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:kMusubiExceptionNeedSignatureUserKey]) {
            @try {
                IBEncryptionIdentity* errId = (IBEncryptionIdentity*)[exception.userInfo objectForKey:@"identity"];
                if (errId) {
                    [self log:@"Making new signature key for %@", errId];
                    
                    IBSignatureUserKey* userKey = [identityProvider signatureKeyForIdentity:errId];
                    
                    if (userKey) {
                        SignatureUserKeyManager* sigUserKeyMgr = transportManager.signatureUserKeyManager;
                        MSignatureUserKey* sigKey = (MSignatureUserKey*)[sigUserKeyMgr create];
                        [sigKey setIdentity: sender];
                        [sigKey setPeriod: errId.temporalFrame];
                        [sigKey setKey: userKey.raw];
                        [sigUserKeyMgr createSignatureUserKey:sigKey];
                        
                        // Try again, should work now :)
                        encoded = [encoder encodeOutgoingMessage:om];
                    } else {
                        @throw exception;
                    }
                } else {
                    @throw exception;
                }
                
            }
            @catch (NSException *exception) {
                // If we can't get the identity
                self.retryCount = INT_MAX - 1;
                [self log:@"Error: %@", exception];
            }
        } else {
            @throw exception;
        }
    }
    
    if([obj.type isEqualToString:kObjTypeProfile]) {
        [self.store.context deleteObject:obj];
    } else {
        obj.encoded = encoded;
    }
    
    if(feed.type == kFeedTypeOneTimeUse) {
        [feedManager deleteFeedAndMembersAndObjs:feed];
    }
    
    [self.store save];
    
    NSLog(@"obj: %@", obj);
    
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationAppObjReady object:obj.objectID]];
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationPreparedEncoded object:encoded.objectID]];

    if(success)
        [self removePending];
    return success;
}

@end
