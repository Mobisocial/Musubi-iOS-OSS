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

#define kObjFieldTargetHash @"target_hash"
#define kObjFieldTargetRelation @"target_relation"
#define kObjFieldMimeType @"mimeType"
#define kObjFieldLocalUri @"localUri"
#define kObjFieldSharedKey @"sharedKey"
#define kObjFieldHtml @"__html"
#define kObjFieldText @"__text"
#define kObjFieldStatusText @"text"
#define kObjFieldRenderMode @"__render_mode"

#define kObjFieldRelationParent @"parent"
#define kObjFieldRenderModeLatest @"latest"

@class Obj, MObj, MFeed, MApp, PersistentModelStore, MIdentity;

@interface ObjHelper : NSObject

+ (BOOL) isRenderable: (Obj*) obj;
+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed fromApp: (MApp*) app usingStore: (PersistentModelStore*) store;
+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed asIdentity:(MIdentity*)ownedId fromApp: (MApp*) app usingStore: (PersistentModelStore*) store;

@end
