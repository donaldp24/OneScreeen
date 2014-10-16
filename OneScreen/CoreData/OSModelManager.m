//
//  OSModelManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSModelManager.h"
#import "NSDate+convenience.h"

@implementation OSModelManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (OSModelManager *)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return (OSModelManager*)sharedInstance;
}

- (NSMutableArray *)retrieveCalCheckForSensor:(NSString *)ssn
{
    NSMutableArray * allRecords = [NSMutableArray arrayWithCapacity:0];
    if (ssn == nil || ssn.length == 0)
        return allRecords;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDCalCheck"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"date"
                                 ascending:NO];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        if(fetchedObjects) {
            for (NSManagedObject *obj in fetchedObjects){
                [allRecords addObject:obj];
            }
        }
    }
    return allRecords;
}

- (CDCalibrationDate *)getCalibrationDateForSensor:(NSString *)ssn
{
    if (ssn == nil || ssn.length == 0)
        return nil;
    
    CDCalibrationDate *ret = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDCalibrationDate"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];

    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        if(fetchedObjects && fetchedObjects.count > 0) {
            ret = [fetchedObjects objectAtIndex:0];
        }
    }
    return ret;
}

- (CDCalCheck *)getOldestCalCheckForSensor:(NSString *)ssn
{
    if (ssn == nil || ssn.length == 0)
        return nil;
    
    CDCalCheck *ret = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDCalCheck"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"date"
                                 ascending:YES];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        if(fetchedObjects && fetchedObjects.count > 0) {
            ret = [fetchedObjects objectAtIndex:0];
        }
    }
    return ret;
}

- (CDCalCheck *)getLatestCalCheckForSensor:(NSString *)ssn
{
    if (ssn == nil || ssn.length == 0)
        return nil;
    
    CDCalCheck *ret = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDCalCheck"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"date"
                                 ascending:NO];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        if(fetchedObjects && fetchedObjects.count > 0) {
            ret = [fetchedObjects objectAtIndex:0];
        }
    }
    return ret;
}

- (NSMutableArray *)retrieveSensorSerials
{
    NSMutableArray *sensors = [[NSMutableArray alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDCalCheck"
                                   inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"date"
                                 ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    [fetchRequest setEntity:entity];
   
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        for (CDCalCheck *calCheck in fetchedObjects) {
            if (![sensors containsObject:calCheck.ssn])
                [sensors addObject:[NSString stringWithFormat:@"%@", calCheck.ssn]];
        }
    }
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription
              entityForName:@"CDCalibrationDate"
              inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    
    error = nil;
    fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        for (CDCalibrationDate *cdCalibrationDate in fetchedObjects) {
            if (![sensors containsObject:cdCalibrationDate.ssn])
                [sensors addObject:[NSString stringWithFormat:@"%@", cdCalibrationDate.ssn]];
        }
    }
    return sensors;

}

- (NSMutableArray *)retrieveSensorNames
{
    NSMutableArray *sensors = [[NSMutableArray alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDSensor"
                                   inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"name"
                                 ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    
    for (id obj in fetchedObjects) {
        [sensors addObject:obj];
    }
    
    return sensors;
}

- (CDCalCheck *)getCalCheckForSensor:(NSString *)ssn date:(NSDate *)date
{
    if (ssn == nil || ssn.length == 0)
        return nil;
    
    CDCalCheck *ret = nil;
    
    // search equal calcheck
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDCalCheck"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"date"
                                 ascending:NO];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        for (CDCalCheck *calCheck in fetchedObjects) {
            //if ([calCheck.date compareWithoutHour:date])
            if ([calCheck.date compare:date])
            {
                ret = calCheck;
                break;
            }
        }
    }

    return ret;
}

- (CDSensor *)getSensorForSerial:(NSString *)ssn
{
    if (ssn == nil || ssn.length == 0)
        return nil;
    
    CDSensor *ret = nil;
    
    // search equal calcheck
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDSensor"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"name"
                                 ascending:YES];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error != nil)
    {
        NSLog(@"error in fetching : %@", error);
    }
    else
    {
        if (fetchedObjects.count > 0)
            ret = [fetchedObjects objectAtIndex:0];
    }
    
    return ret;
}

#pragma mark - save sensor

- (void)setCalibrationDate:(NSDate *)date sensorSerial:(NSString *)ssn
{
    if (ssn == nil || ssn.length == 0)
        return;
    
    [self setSensor:ssn];
    
    CDCalibrationDate *cdCalibrationDate = [self getCalibrationDateForSensor:ssn];
    if (cdCalibrationDate == nil)
        cdCalibrationDate = [NSEntityDescription
                             insertNewObjectForEntityForName:@"CDCalibrationDate"
                             inManagedObjectContext:self.managedObjectContext];
    cdCalibrationDate.ssn = ssn;
    cdCalibrationDate.calibrationDate = date;
    
    [self saveContext];
}

- (void)setCalCheckForSensor:(NSString *)ssn date:(NSDate *)date rh:(CGFloat)rh temp:(CGFloat)temp salt_name:(NSString *)salt_name oldest:(BOOL)oldest
{
    if (ssn == nil || ssn.length == 0)
        return;
    
    [self setSensor:ssn];
    
    if (!oldest)
    {
        // search equal calcheck
        CDCalCheck *existCalCheck = [self getCalCheckForSensor:ssn date:date];
        if (existCalCheck == nil)
            existCalCheck = [NSEntityDescription
                             insertNewObjectForEntityForName:@"CDCalCheck"
                             inManagedObjectContext:self.managedObjectContext];
        existCalCheck.ssn = ssn;
        existCalCheck.date = date;
        existCalCheck.rh = @(rh);
        existCalCheck.temp = @(temp);
        existCalCheck.salt_name = salt_name;
        
        [self saveContext];
    }
    else
    {
        // search prior calcheck
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription
                                       entityForName:@"CDCalCheck"
                                       inManagedObjectContext:self.managedObjectContext];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ssn == %@", ssn];
        NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                     initWithKey:@"date"
                                     ascending:NO];
        
        [fetchRequest setEntity:entity];
        [fetchRequest setPredicate:predicate];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sorter, nil]];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error != nil)
        {
            NSLog(@"error in fetching : %@", error);
        }
        else
        {
            NSMutableArray *arrayRemoves = [[NSMutableArray alloc] init];
            for (CDCalCheck *calCheck in fetchedObjects) {
                NSComparisonResult compareResult = [calCheck.date compare:date];
                if (compareResult == NSOrderedAscending)
                {
                    [arrayRemoves addObject:calCheck];
                }
            }
            
            // remove data that is older than oldest one
            for (CDCalCheck *calCheck in arrayRemoves) {
                [self deleteObject:calCheck];
            }
        }
        
        // search equal calcheck
        CDCalCheck *existCalCheck = [self getCalCheckForSensor:ssn date:date];
        if (existCalCheck == nil)
            existCalCheck = [NSEntityDescription
                             insertNewObjectForEntityForName:@"CDCalCheck"
                             inManagedObjectContext:self.managedObjectContext];
        existCalCheck.ssn = ssn;
        existCalCheck.date = date;
        existCalCheck.rh = @(rh);
        existCalCheck.temp = @(temp);
        existCalCheck.salt_name = salt_name;
        
        [self saveContext];

    }
}

- (void)setSensor:(NSString *)ssn
{
    CDSensor *sensor = [self getSensorForSerial:ssn];
    if (sensor)
        return;
    sensor = [NSEntityDescription
              insertNewObjectForEntityForName:@"CDSensor"
              inManagedObjectContext:self.managedObjectContext];
    sensor.ssn = ssn;
    sensor.name = @"";
}

- (void)setSensor:(CDSensor *)sensor name:(NSString *)name
{
    if (sensor == nil)
        return;
    
    if (name != nil)
        sensor.name = name;
    else
        sensor.name = @"";
    
    [self saveContext];
}

#pragma mark - CoreData stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (_managedObjectContext == savedContext)
    {
        return;
    }
    
    if (_managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator)
    {
        // that's another database
        return;
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    });
}
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setUndoManager:nil];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        // subscribe to change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
        
    }
    
    
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [DOCUMENTS_DIR URLByAppendingPathComponent:kSqliteName];
    //add lightweight migration
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],
                             NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES],
                             NSInferMappingModelAutomaticallyOption,nil];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    
    return _persistentStoreCoordinator;
}

- (void) deleteObject:(id)sender{
    [self.managedObjectContext deleteObject:sender];
}

@end
