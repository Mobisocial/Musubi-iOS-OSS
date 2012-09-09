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

#ifndef musubi_MusubiAnalytics_h
#define musubi_MusubiAnalytics_h

#import "GANTracker.h"

#define kAnalyticsPageAppEntryPoint @"/app_entry_point"
#define kAnalyticsPageEula @"/eula"
#define kAnalyticsPageFeedList @"/feed_list"
#define kAnalyticsPageFeed @"/feed"
#define kAnalyticsPageFeedGallery @"/feed_photo_gallery"

#define kAnalyticsCategoryApp @"App"
#define kAnalyticsActionSendObj @"Send Obj"
#define kAnalyticsActionFeedAction @"Feed Action"
#define kAnalyticsLabelFeedActionCamera @"Picture from Camera"
#define kAnalyticsLabelFeedActionGallery @"Picture from Gallery"
#define kAnalyticsLabelFeedActionRecordAudio @"Record Audio"
#define kAnalyticsLabelFeedActionSketch @"Sketch"
#define kAnalyticsLabelFeedActionCheckIn @"Check-In"

#define kAnalyticsActionInvite @"Invite"
#define kAnalyticsLabelYes @"Yes"
#define kAnalyticsLabelNo @"No"

#define kAnalyticsCategoryEditor @"Editor"
#define kAnalyticsActionEdit @"Edit"
#define kAnalyticsLabelEditFromFeed @"Edit from Feed"
#define kAnalyticsLabelEditFromGallery @"Edit from Gallery"


#define kAnalyticsCategoryOnboarding @"Onboarding"
#define kAnalyticsActionAcceptEula @"Accept Eula"
#define kAnalyticsActionDeclineEula @"Decline Eula"
#define kAnalyticsActionEmailEula @"Email Eula"
#define kAnalyticsActionConnectingAccount @"Connecting Account"
#define kAnalyticsActionConnectedAccount @"Connected Account"

#endif
