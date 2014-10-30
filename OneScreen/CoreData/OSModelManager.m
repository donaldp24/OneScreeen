//
//  OSModelManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSModelManager.h"
#import "NSDate+convenience.h"
#import "NSDate+String.h"

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

- (void)deleteObject:(id)object
{
    [self.managedObjectContext deleteObject:object];
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

#pragma mark - calcheck
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

- (NSMutableArray *)retrieveSensors
{
    NSMutableArray *sensors = [[NSMutableArray alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDSensor"
                                   inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"lastreadingtime"
                                 ascending:NO];
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

- (void)removeSensorFromInventory:(CDSensor *)sensor
{
    sensor.deletedInv = @(YES);
    [self saveContext];
}

- (void)removeSensorFromJob:(CDJob *)job sensor:(CDSensor *)sensor
{
    if (job == nil)
        return;
    
    if (sensor == nil)
        return;
    
    // search equal calcheck
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDReading"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(jobUid == %@) AND (ssn == %@)", job.uid, sensor.ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"timestamp"
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
        for (CDReading *reading in fetchedObjects) {
            [self deleteObject:reading];
        }
        
        [self saveContext];
    }
}

- (void)setLastReadingTimeForSensor:(CDSensor *)sensor lastTime:(NSDate *)lastTime
{
    if (sensor == nil)
        return;
    if (lastTime == nil)
        return;
    
    sensor.lastreadingtime = lastTime;
    [self saveContext];
    return;
}

#pragma mark - job
- (CDJob *)getJobWithUid:(NSString *)uid
{
    if (uid == nil || uid.length == 0)
        return nil;
    
    CDJob *ret = nil;
    
    // search equal calcheck
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDJob"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid == %@", uid];
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

- (CDJob *)createNewJob:(NSString *)jobName
{
    NSDate *date = [NSDate date];
    NSString *strDate = [date toStringWithFormat:kDateTimeFormat];
    NSTimeInterval interval = [date timeIntervalSince1970];
    NSString *uid = [NSString stringWithFormat:@"%@_%.2f", strDate, interval];
    
    CDJob *newJob = [NSEntityDescription
                     insertNewObjectForEntityForName:@"CDJob"
                     inManagedObjectContext:self.managedObjectContext];
    newJob.isdeleted = @(NO);
    newJob.uid = uid;
    newJob.name = jobName;
    newJob.createtime = [NSDate date];
    
    [self saveContext];
    
    return newJob;
}

- (void)setNameForJob:(CDJob *)job jobName:(NSString *)jobName
{
    if (job == nil)
        return;
    
    job.name = jobName;
    [self saveContext];
}

- (void)startJob:(CDJob *)job
{
    if (job == nil)
        return;
    
    job.endtime = nil;
    
    if (job.starttime != nil)
        return;
    
    job.starttime = [NSDate date];
    
    
    [self saveContext];
}

- (void)endJob:(CDJob *)job
{
    if (job == nil)
        return;
    
    job.endtime = [NSDate date];
    [self saveContext];
}

- (void)removeJob:(CDJob *)job
{
    if (job == nil)
        return;
    
    job.isdeleted = @(YES);
    [self saveContext];
}

- (NSMutableArray *)retrieveJobs
{
    NSMutableArray *arrayJobs = [[NSMutableArray alloc] init];
    
    // search equal
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDJob"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isdeleted == %@", @(NO)];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"starttime"
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
        for (id obj in fetchedObjects) {
            [arrayJobs addObject:obj];
        }
    }
    
    return arrayJobs;

}

#pragma mark - reading
- (CDReading *)getLastReadingForSensor:(NSString *)ssn ofJob:(NSString *)jobUid
{
    if (jobUid == nil || jobUid.length == 0)
        return nil;
    
    if (ssn == nil || ssn.length == 0)
        return nil;
    
    CDReading *ret = nil;
    
    // search equal calcheck
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDReading"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(jobUid == %@) AND (ssn == %@)", jobUid, ssn];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"timestamp"
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
        if (fetchedObjects.count > 0)
            ret = [fetchedObjects objectAtIndex:0];
    }
    
    return ret;
}

- (NSMutableArray *)getSensorSerialsForJob:(NSString *)jobUid
{
    NSMutableArray *arraySensorSerials = [[NSMutableArray alloc] init];
    if (jobUid == nil || jobUid.length == 0)
        return arraySensorSerials;
    
    // search equal
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CDReading"
                                   inManagedObjectContext:self.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(jobUid == %@)", jobUid];
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc]
                                 initWithKey:@"timestamp"
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
        for (CDReading *reading in fetchedObjects) {
            if (![arraySensorSerials containsObject:reading.ssn])
                [arraySensorSerials addObject:reading.ssn];
        }
    }
    
    return arraySensorSerials;
}

- (void)saveReadingForJob:(NSString *)jobUid sensorData:(NSDictionary *)dicInfo
{
    if (dicInfo == nil || ![dicInfo isKindOfClass:[NSDictionary class]])
        return;
    /*
    NSString * const kSensorDataBatteryKey = @"battery";
    NSString * const kSensorDataRHKey = @"rh";
    NSString * const kSensorDataRHAmbientKey = @"rhAmbient";
    NSString * const kSensorDataTemperatureKey = @"temp";
    NSString * const kSensorDataTemperatureAmbientKey = @"tempAmbient";
    NSString * const kSensorDataReadingTimestampKey = @"readingTimestamp";
    NSString * const kSensorDataSerialNumberKey = @"serial";
     */
    CGFloat rh = [[dicInfo objectForKey:kSensorDataRHKey] floatValue];
    CGFloat temp = [[dicInfo objectForKey:kSensorDataTemperatureKey] floatValue];
    CGFloat ambRh = [[dicInfo objectForKey:kSensorDataRHAmbientKey] floatValue];
    CGFloat ambTemp = [[dicInfo objectForKey:kSensorDataTemperatureAmbientKey] floatValue];
    int battery = [[dicInfo objectForKey:kSensorDataBatteryKey] intValue];
    
    NSString *ssn = [dicInfo objectForKey:kSensorDataSerialNumberKey];
    
    if (ssn == nil || ssn.length == 0)
        return;
    
    CDReading *reading = [NSEntityDescription
                          insertNewObjectForEntityForName:@"CDReading"
                          inManagedObjectContext:self.managedObjectContext];
    reading.rh = @(rh);
    reading.temp = @(temp);
    reading.ambRh = @(ambRh);
    reading.ambTemp = @(ambTemp);
    reading.ssn = ssn;
    reading.battery = @(battery);
    reading.timestamp = [NSDate date];
    reading.jobUid = jobUid;
    
    [self saveContext];
    return;
}

@end
