//
//  OSModelManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CDCalCheck.h"
#import "CDCalibrationDate.h"
#import "CDSensor.h"
#import "CDJob.h"
#import "CDReading.h"

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
- (void)deleteObject:(id)object;


#pragma mark - sensor
- (NSMutableArray *)retrieveSensors;
- (CDSensor *)getSensorForSerial:(NSString *)ssn;
- (void)setSensor:(NSString *)ssn;
- (void)setSensor:(CDSensor *)sensor name:(NSString *)name;
- (void)removeSensorFromInventory:(CDSensor *)sensor;
- (void)removeSensorFromJob:(CDJob *)job sensor:(CDSensor *)sensor;
- (void)setLastReadingTimeForSensor:(CDSensor *)sensor lastTime:(NSDate *)lastTime;

- (void)undeleteSensors;


#pragma mark - calcheck
- (NSMutableArray *)retrieveCalCheckForSensor:(NSString *)ssn;
- (CDCalCheck *)getFirstCalCheckForSensor:(NSString *)ssn;
- (void)printCalCheckForSensor:(NSString *)ssn;
- (CDCalCheck *)getLatestCalCheckForSensor:(NSString *)ssn;
- (CDCalCheck *)getCalCheckForSensor:(NSString *)ssn date:(NSDate *)date;
- (void)setCalCheckForSensor:(NSString *)ssn date:(NSDate *)date rh:(CGFloat)rh temp:(CGFloat)temp salt_name:(NSString *)salt_name first:(BOOL)first;


#pragma mark - calibration date
- (CDCalibrationDate *)getCalibrationDateForSensor:(NSString *)ssn;
- (void)setCalibrationDate:(NSDate *)date sensorSerial:(NSString *)ssn;


// job
- (CDJob *)getJobWithUid:(NSString *)uid;
- (CDJob *)createNewJob:(NSString *)jobName;
- (void)setNameForJob:(CDJob *)job jobName:(NSString *)jobName;
- (NSMutableArray *)retrieveJobs;
- (void)startJob:(CDJob *)job;
- (void)endJob:(CDJob *)job;
- (void)removeJob:(CDJob *)job;

// reading
- (CDReading *)getLastReadingForSensor:(NSString *)ssn ofJob:(NSString *)jobUuid;
- (NSMutableArray *)getSensorSerialsForJob:(NSString *)jobUid;
- (void)saveReadingForJob:(NSString *)jobUid sensorData:(NSDictionary *)dicInfo;

@end
