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

#import "APNPushManager.h"
#import "FeedManager.h"
#import "MFeed.h"
#import "Musubi.h"
#import "NSData+HexString.h"

static NSOperationQueue* sApnQueue = nil;

@implementation APNPushManager
+ (NSOperationQueue*)apnQueue {
    @synchronized([APNPushManager class]) {
        if(sApnQueue != nil)
            return sApnQueue;
        else 
            sApnQueue = [[NSOperationQueue alloc] init];
        return sApnQueue;
    }
}
+ (void) registerDevice:(NSString*)deviceToken identities:(NSArray*)idents localUnread:(int)count {
    NSMutableDictionary* registrationRequest = [[NSMutableDictionary alloc] init];
    [registrationRequest setValue:idents forKey:@"identityExchanges"];
    [registrationRequest setValue:deviceToken forKey:@"deviceToken"];
[registrationRequest setValue:deviceToken forKey:@"deviceToken"];
#ifdef DEBUG
    BOOL production = NO;
#else
    BOOL production = YES;
#endif
    [registrationRequest setValue:[NSNumber numberWithBool:production] forKey:@"production"];
    NSError* error = nil;
    NSData* body = [NSJSONSerialization dataWithJSONObject:registrationRequest options:0 error:&error];
    if(!body) {
        NSLog(@"Failed to serialize json for registration %@", error);
    } else {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/api/0/register"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%u", body.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:body];

        [NSURLConnection sendAsynchronousRequest:request queue:[APNPushManager apnQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError * error) {
            NSLog(@"Registration returned %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
        }];
       
    }
}

+ (void) resetLocalUnread:(NSString*)deviceToken count:(int)count background:(BOOL)background {
    NSMutableDictionary* registrationRequest = [[NSMutableDictionary alloc] init];
    [registrationRequest setValue:[NSNumber numberWithInt:count] forKey:@"count"];
    [registrationRequest setValue:deviceToken forKey:@"deviceToken"];
    [registrationRequest setValue:[NSNumber numberWithBool:background] forKey:@"background"];
    NSError* error = nil;
    NSData* body = [NSJSONSerialization dataWithJSONObject:registrationRequest options:0 error:&error];
    if(!body) {
        NSLog(@"Failed to serialize device token for clearing unread %@", error);
    } else {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/api/0/resetunread"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%u", body.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:body];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[APNPushManager apnQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError * error) {
            NSLog(@"Clear returned %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
        }];
    }
}
+ (void) clearRemoteUnread:(NSString*)deviceToken background:(BOOL)background {
    NSError* error = nil;
    NSData* body = [deviceToken dataUsingEncoding:NSASCIIStringEncoding];
    if(!body) {
        NSLog(@"Failed to serialize device token for clearing unread %@", error);
    } else {
      	  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/api/0/clearunread"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%u", body.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:body];

        [NSURLConnection sendAsynchronousRequest:request queue:[APNPushManager apnQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError * error) {
            NSLog(@"Clear returned %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
        }];

    }
}
+ (int) tallyLocalUnread {
    FeedManager* feedManager = [[FeedManager alloc] initWithStore: [Musubi sharedInstance].newStore];
    int total = 0;
    for(MFeed* feed in [feedManager displayFeeds]) {
        total += feed.numUnread;
    }
    return total;
}
+ (void) resetLocalUnreadInBackgroundTask:(BOOL)background {
    NSString* deviceToken = [Musubi sharedInstance].apnDeviceToken;
    if(!deviceToken)	
        return;
    UIApplication* application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier bgt = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        [application endBackgroundTask:bgt];
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        //TODO: could have several go in out of order if the net is slow
        int unread = [APNPushManager tallyLocalUnread];
        [APNPushManager resetLocalUnread:deviceToken count:unread background:background];
        [application setApplicationIconBadgeNumber:unread ];
        //TODO: main thread?
        [application endBackgroundTask:bgt];
    });
}
+ (void) resetBothUnreadInBackgroundTask {
    NSString* deviceToken = [Musubi sharedInstance].apnDeviceToken;
    if(!deviceToken)	
        return;
    UIApplication* application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier bgt = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        [application endBackgroundTask:bgt];
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        //TODO: could have several go in out of order if the net is slow
        int unread = [APNPushManager tallyLocalUnread];
        [APNPushManager clearRemoteUnread:deviceToken background:(application.backgroundTimeRemaining < 10000)];
        [APNPushManager resetLocalUnread:deviceToken count:unread background:(application.backgroundTimeRemaining < 10000)];
        [application setApplicationIconBadgeNumber:unread ];
        //TODO: main thread?
        [application endBackgroundTask:bgt];
    });
}


@end
