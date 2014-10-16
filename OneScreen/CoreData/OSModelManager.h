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


- (NSMutableArray *)retrieveCalCheckForSensor:(NSString *)ssn;
- (CDCalibrationDate *)getCalibrationDateForSensor:(NSString *)ssn;
- (CDCalCheck *)getOldestCalCheckForSensor:(NSString *)ssn;
- (CDCalCheck *)getLatestCalCheckForSensor:(NSString *)ssn;
- (NSMutableArray *)retrieveSensorSerials;
- (NSMutableArray *)retrieveSensorNames;


- (CDCalCheck *)getCalCheckForSensor:(NSString *)ssn date:(NSDate *)date;

- (CDSensor *)getSensorForSerial:(NSString *)ssn;


- (void)setCalibrationDate:(NSDate *)date sensorSerial:(NSString *)ssn;
- (void)setCalCheckForSensor:(NSString *)ssn date:(NSDate *)date rh:(CGFloat)rh temp:(CGFloat)temp salt_name:(NSString *)salt_name oldest:(BOOL)oldest;
- (void)setSensor:(NSString *)ssn;
- (void)setSensor:(CDSensor *)sensor name:(NSString *)name;


@end
