//
//  OSModelManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reading.h"

@interface OSModelManager : NSObject

// Context for CoreData
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// Object model for CoreData
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

// Persistent store coordinator for CoreData
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (OSModelManager *)sharedInstance;

// Save context
- (void)saveContext;


- (NSMutableArray *)retrieveReadings;


@end
