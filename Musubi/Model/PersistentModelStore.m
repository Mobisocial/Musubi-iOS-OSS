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


#import "PersistentModelStore.h"
#import "Musubi.h"

@implementation PersistentModelStoreFactory

@synthesize coordinator, rootStore;

static PersistentModelStoreFactory *sharedInstance = nil;

+ (PersistentModelStoreFactory *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[PersistentModelStoreFactory alloc] initWithName:@"Store"];
    }
    
    return sharedInstance;
}

+ (NSURL*) pathForStoreWithName: (NSString*) name {
    NSArray *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    return [NSURL fileURLWithPath: [[documentsPath objectAtIndex:0] 
                                    stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.sqlite", name]]];
}

+ (void) deleteStoreWithName: (NSString*) name {
    NSURL* storePath = [PersistentModelStoreFactory pathForStoreWithName:name];
    [[NSFileManager defaultManager] removeItemAtPath:storePath.path error:NULL];
}

+ (void) restoreStoreFromFile: (NSURL*) path {
    NSManagedObjectContext *context = [PersistentModelStoreFactory sharedInstance].rootStore.context;
    NSPersistentStoreCoordinator *c = context.persistentStoreCoordinator;
    NSPersistentStore* store = [[c persistentStores] objectAtIndex:0];
    NSURL* storePath = store.URL;
    
    NSError* error = nil;

    // detach store from coordinator
    [c removePersistentStore:store error:&error];
    if (error) @throw error;
    
    // move over the old file to a temp loaction
    NSURL* tempPath = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@_TMP", storePath.path]];
    NSLog(@"Moving old store to %@", tempPath);
    [[NSFileManager defaultManager] moveItemAtURL:storePath toURL:tempPath error:&error];
    if (error) @throw error;

    // move over new file to store location
    NSLog(@"Moving new store from %@", path);
    [[NSFileManager defaultManager] moveItemAtURL:path toURL:storePath error:&error];
    if (error) {
        // move back the store
        [[NSFileManager defaultManager] moveItemAtURL:tempPath toURL:storePath error:nil]; 
        @throw error;
    }
    
    // create new store
    NSLog(@"Creating new persistent store at %@", storePath);
    [c addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storePath options:nil error:&error];
    if (error) {
        // move back the store
        [[NSFileManager defaultManager] moveItemAtURL:tempPath toURL:storePath error:nil];        
        @throw error;
    }
    
    // remove the temp backed up store
    [[NSFileManager defaultManager] removeItemAtURL:tempPath error:nil];
}

- (id) initWithName: (NSString*) name {
    NSURL *path = [PersistentModelStoreFactory pathForStoreWithName:name];
    return [self initWithPath: path];
}

- (id) initWithPath: (NSURL*) path {
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
        [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    NSPersistentStoreCoordinator *c = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    [c addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:path options:options error:&error];
    
    if (error) {
        NSLog(@"Store error: %@", error);
    }
    
    return [self initWithCoordinator:c];
}

- (id)initWithCoordinator:(NSPersistentStoreCoordinator *)c {
    self = [super init];
    if (!self)
        return nil;
    
    self.coordinator = c;
    rootStore = [[PersistentModelStore alloc] initWithCoordinator:self.coordinator];
    return self;
}

- (PersistentModelStore *) newStore {
    return [[PersistentModelStore alloc] initWithParent: rootStore];
}

@end

@implementation PersistentModelStore

@synthesize context, createdObjects;

- (id) initWithParent: (PersistentModelStore*)parent
{
    self = [super init];
    if (!self)
        return nil;

    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    self.context.parentContext = parent.context;
    self.createdObjects = [NSMutableArray array];
    
    return self;
}
- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator {
    self = [super init];
    if (!self)
        return nil;
    
    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = coordinator;
    self.createdObjects = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otherContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];
    return self;
}

- (void)dealloc {
    if(self.context.parentContext == nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
    }
}

- (void) otherContextSaved: (NSNotification*) notification {
    NSManagedObjectContext* moc = notification.object;
    if (moc.parentContext == context) {
        // call the result handler block on the main queue (i.e. main thread)
        dispatch_async( dispatch_get_main_queue(), ^{
            [context mergeChangesFromContextDidSaveNotification:notification];
            NSError* error;
            if(![context save:&error]) {
                NSLog(@"failed to save changes merged from other context");
            }
        });
    }
}

- (BOOL) isDeletedObject: (NSManagedObject*) object {
    NSManagedObject* clone = [context existingObjectWithID:object.objectID error:NULL];
    if (!clone) {
        return YES;
    } else {
        return NO;
    }
}

- (NSArray *)query:(NSPredicate *)predicate onEntity:(NSString *)entityName {
    return [self query:predicate onEntity:entityName sortBy:nil];
}

- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor limit:(NSInteger) limit{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:predicate];
    if (sortDescriptor)
        [request setSortDescriptors: [NSArray arrayWithObject: sortDescriptor]];
    if (limit > 0)
        [request setFetchLimit: limit];
    
    NSError *error = nil;
    NSDate* start = [NSDate date];
    NSArray* result = [context executeFetchRequest:request error:&error];
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:start];
//    NSLog(@"Query %@ took %f", predicate, interval);
    return result;
}

- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor{
    return [self query:predicate onEntity:entityName sortBy:sortDescriptor limit:-1];
}

- (NSManagedObject*) queryFirst: (NSPredicate*) predicate onEntity: (NSString*) entityName {
    NSArray* results = [self query:predicate onEntity:entityName];
    if (results.count > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSManagedObject *)createEntity: (NSString*) entityName {
    NSManagedObject* entity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext: context];
    [createdObjects addObject:entity];
    return entity;
}

- (void)save {
    NSError* err = nil;
    
    // Filter out the objects that already have a permanent ID
    for (NSManagedObject* object in createdObjects) {
        if (!object.objectID.isTemporaryID) {
            [createdObjects removeObject:object];
        }
    }
    
    // Get a permanent ID for the rest
    if (![context obtainPermanentIDsForObjects:createdObjects error:&err]) {
        @throw [NSException exceptionWithName:kMusubiExceptionUnexpected reason:[NSString stringWithFormat:@"Unexpected error occurred: %@", err] userInfo:nil];
    }
    
    // And clear
    [createdObjects removeAllObjects];
    
    // Save and exit
    if(![context save:&err]) {
        @throw [NSException exceptionWithName:kMusubiExceptionUnexpected reason:[NSString stringWithFormat:@"Unexpected error occurred: %@", err] userInfo:nil];
    }
}

@end
