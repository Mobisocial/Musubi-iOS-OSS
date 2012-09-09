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


#import "EntityManager.h"
#import "PersistentModelStore.h"

@implementation EntityManager

@synthesize entityName, store;

- (id)initWithEntityName:(NSString *)name andStore:(PersistentModelStore *)s {
    self = [super init];
    if (self != nil) {
        [self setEntityName: name];
        [self setStore: s];
    }
    return self;
}

- (NSArray*) query: (NSPredicate*) predicate {
    return [store query:predicate onEntity:entityName];
}

- (NSArray *)query:(NSPredicate *)predicate sortBy:(NSSortDescriptor*) sortDescriptor {
    return [store query:predicate onEntity:entityName sortBy:sortDescriptor];
}

- (NSArray *)query:(NSPredicate *)predicate sortBy:(NSSortDescriptor *)sortDescriptor limit:(NSInteger)limit {
    return [store query:predicate onEntity:entityName sortBy:sortDescriptor limit:limit];
}

- (NSManagedObject*) queryFirst: (NSPredicate*) predicate {
    return [store queryFirst:predicate onEntity:entityName];
}

- (id)create {
    return [store createEntity:entityName];
}

@end
