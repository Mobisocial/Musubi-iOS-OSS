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

@class PersistentModelStore;

@interface EntityManager : NSObject{
    PersistentModelStore* store;
    NSString* entityName;
}

@property (nonatomic) NSString* entityName;
@property (nonatomic) PersistentModelStore* store;

- (id) initWithEntityName: (NSString*) name andStore: (PersistentModelStore*) s;
- (id) create;
- (NSArray*) query:(NSPredicate*) predicate;
- (NSArray *)query:(NSPredicate *)predicate sortBy:(NSSortDescriptor*) sortDescriptor;
- (NSArray *)query:(NSPredicate *)predicate sortBy:(NSSortDescriptor*) sortDescriptor limit:(NSInteger) limit;
- (NSManagedObject*) queryFirst: (NSPredicate*) predicate;

@end
