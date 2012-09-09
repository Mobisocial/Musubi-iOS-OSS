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

#import "URLCommand.h"
#import "SBJsonParser.h"
#import "ObjHelper.h"
#import "Obj.h"
#import "NSData+Base64.h"
#import "Musubi.h"
#import "PersistentModelStore.h"
#import "HTMLAppViewController.h"

@implementation URLFeedCommand

@synthesize url, className, methodName, parameters, app, viewController;

+ (id)createFromURL:(NSURL *)url withApp:(MApp*) app withViewController:(HTMLAppViewController *)viewController {
    NSArray* hostComponents = [[url host] componentsSeparatedByString:@"."];
    NSString* className = [NSString stringWithFormat:@"%@Command", [[hostComponents objectAtIndex:0] capitalizedString]];
    NSString* methodName = [NSString stringWithFormat:@"%@WithParams:", [hostComponents objectAtIndex:1]];
    
    NSLog(@"URLFeedCommand-- %@:%@", className, methodName);
    
    URLFeedCommand* cmd = [[NSClassFromString(className) alloc] init];
    if (!cmd) {
        NSLog(@"ERROR: Command class '%@' not defined", className);
        return nil;
    }

    if (! [cmd isKindOfClass:[URLFeedCommand class]] ) {
        NSLog(@"ERROR: Command class '%@' is not a URLFeedCommand", className);
        return nil;
    }
    
    if (! [cmd respondsToSelector:NSSelectorFromString(methodName)] ) {
        // There's no method to call, so throw an error.
        NSLog(@"ERROR: Method '%@' not defined in command class '%@'", methodName, className);
        return nil;
    }
    
    NSMutableDictionary* params = [url queryComponents];
    [cmd setParameters:params];
    [cmd setMethodName:methodName];
    [cmd setApp:app];
    [cmd setViewController:viewController];
        
    return cmd;
}

- (NSString*) execute {
    id res = [self performSelector:NSSelectorFromString([self methodName]) withObject:[self parameters]];
    return res;
}

@end

@implementation FeedCommand

- (id) messagesWithParams:(NSDictionary *)params {
    
    //ManagedFeed* mgdFeed = [[Musubi sharedInstance] feedByName: [params objectForKey:@"feedName"]];
    
    NSMutableArray* msgs = [NSMutableArray array];
/*    for (ManagedMessage* msg in [mgdFeed allMessages]) {
        [msgs addObject:[[msg message] json]];
    }*/
    
    return msgs;
}

- (id) postWithParams:(NSDictionary *)params {
    SBJsonParser* parser = [[SBJsonParser alloc] init];
    NSDictionary* json = [parser objectWithString:[params objectForKey:@"obj"]];
    NSString* feedIdString = [params objectForKey:@"feedSession"];
    if (feedIdString == nil || json == nil) {
        NSLog(@"Bad arguments to post");
        return nil;
    }

    Obj* obj = [[Obj alloc] init];
    [obj setType:[json objectForKey:@"type"]];
    [obj setData:[json objectForKey:@"json"]];
    if ([[json allKeys] containsObject:@"raw_data_url"]) {
        NSString* b64UrlString = [json objectForKey:@"raw_data_url"];
        NSRange range = [b64UrlString rangeOfString:@"base64,"];
        if (range.location != NSNotFound) {
            NSInteger b64Index = range.location + range.length;
            NSString* b64String = [b64UrlString substringFromIndex:b64Index];
            NSData* raw = [b64String decodeBase64];
            [obj setRaw:raw];  
        } else {
            NSLog(@"Malformed base64 data url");
        } 
    }

    PersistentModelStore* store = [[Musubi sharedInstance] mainStore];
    NSURL* feedUri = [NSURL URLWithString:feedIdString];
    NSManagedObjectID* feedId = [store.context.persistentStoreCoordinator managedObjectIDForURIRepresentation:feedUri];
    NSError* error;
    MFeed* feed = (MFeed*)[store.context existingObjectWithID:feedId error:&error];
    if (feed == nil) {
        NSLog(@"Bad feed in feed.post()");
        return nil;
    }
    [ObjHelper sendObj:obj toFeed:feed fromApp:app usingStore:store];

    return nil;
}

@end

@implementation AppCommand

-(id)backWithParams:(NSDictionary*) params {
    [[self viewController].navigationController popViewControllerAnimated:true];
    return nil;
}

-(id)quitWithParams:(NSDictionary*) params {
    [[self viewController].navigationController popViewControllerAnimated:true];
    return nil;
}

@end