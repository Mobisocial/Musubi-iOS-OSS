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
#import "Musubi.h"
#import "XQueryComponents.h"
#import "MApp.h"

@class HTMLAppViewController;

@interface URLFeedCommand : NSObject {
    NSURL* url;
    NSString* className;
    NSString* methodName;
    NSDictionary* parameters;

    MApp* app;
    HTMLAppViewController* viewController;
}

@property (nonatomic,retain) NSURL* url;
@property (nonatomic,retain) NSString* className;
@property (nonatomic,retain) NSString* methodName;
@property (nonatomic,retain) NSDictionary* parameters;
@property (nonatomic,retain) MApp* app;
@property (nonatomic,retain) HTMLAppViewController* viewController;

- (NSString*) execute;
+ (id)createFromURL:(NSURL *)url withApp:(MApp*) app withViewController: (HTMLAppViewController*) viewController;

@end


@interface FeedCommand  : URLFeedCommand
- (id) messagesWithParams: (NSDictionary*) params;
- (id) postWithParams: (NSDictionary*) params;

@end

@interface AppCommand : URLFeedCommand
- (id) quitWithParams:(NSDictionary*) params;
- (id) backWithParams:(NSDictionary*) params;
@end