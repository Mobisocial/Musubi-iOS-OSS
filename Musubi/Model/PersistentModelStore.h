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
#import <CoreData/CoreData.h>

@interface PersistentModelStore : NSObject {
    NSManagedObjectContext* context;
    NSMutableArray* createdObjects;
}

@property (nonatomic, strong) NSManagedObjectContext* context;
@property (nonatomic, strong) NSMutableArray* createdObjects;

- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator;
- (id) initWithParent: (PersistentModelStore*)parent;

- (BOOL) isDeletedObject: (NSManagedObject*) object;

- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName;
- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor;
- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor limit:(NSInteger)limit;
- (NSManagedObject*) queryFirst: (NSPredicate*) predicate onEntity: (NSString*) entityName;
- (NSManagedObject *)createEntity: (NSString*) entityName;

- (void) save;

@end

@interface PersistentModelStoreFactory : NSObject {
    NSPersistentStoreCoordinator* coordinator;
    PersistentModelStore* rootStore;
}

@property (nonatomic, strong) NSPersistentStoreCoordinator* coordinator;
@property (nonatomic, strong, readonly) PersistentModelStore* rootStore;

+ (PersistentModelStoreFactory *)sharedInstance;
+ (NSURL*) pathForStoreWithName: (NSString*) name;
+ (void) deleteStoreWithName: (NSString*) name;
+ (void) restoreStoreFromFile: (NSURL*) path;

- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator;
- (id) initWithPath: (NSURL*) path;
- (id) initWithName: (NSString*) name;

- (PersistentModelStore*) newStore;

@end
