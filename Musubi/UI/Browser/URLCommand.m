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

@implementation URLFeedCommand

@synthesize url, className, methodName, parameters, app;

+ (id)createFromURL:(NSURL *)url withApp:(App*) app{
    NSArray* hostComponents = [[url host] componentsSeparatedByString:@"."];
    NSString* className = [NSString stringWithFormat:@"%@Command", [[hostComponents objectAtIndex:0] capitalizedString]];
    NSString* methodName = [NSString stringWithFormat:@"%@WithParams:", [hostComponents objectAtIndex:1]];
    
    NSLog(@"Creating %@:%@", className, methodName);
    
    URLFeedCommand* cmd = [[[NSClassFromString(className) alloc] init] autorelease];
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
        
    return cmd;
}

- (NSString*) execute {
    id res = [self performSelector:NSSelectorFromString([self methodName]) withObject:[self parameters]];
    return res;
}

@end

@implementation FeedCommand

- (id) messagesWithParams:(NSDictionary *)params {
    ManagedFeed* mgdFeed = [[Musubi sharedInstance] feedByName: [params objectForKey:@"feedName"]];
    
    NSMutableArray* msgs = [NSMutableArray array];
    for (ManagedMessage* msg in [mgdFeed allMessages]) {
        [msgs addObject:[[msg message] json]];
    }
    
    return msgs;
}

- (id) postWithParams:(NSDictionary *)params {
    SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary* json = [parser objectWithString:[params objectForKey:@"obj"]];
    
    Obj* obj = [[[Obj alloc] init] autorelease];
    [obj setType:[json objectForKey:@"type"]];
    [obj setData:[json objectForKey:@"data"]];
    
    [[Musubi sharedInstance] sendMessage:[Message createWithObj:obj forApp:app]];
    
    return nil;
}

@end