//
//  SensorInfo.h
//  OneScreen
//
//  Created by Xiaoxue Han on 2/6/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCalCheck.h"
#import "CDSensor.h"
#import "CDCalibrationDate.h"
#import "SensorData.h"
#import "OSSaltSolutionManager.h"

// type of retrieved
#define RETRIEVED_NONE      0
#define RETRIEVED_NODATA    1
#define RETRIEVED_DATA      2
#define RETRIEVED_NETERROR  3



@interface SensorInfo : NSObject

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic, retain) SensorData *firstSensorData;
@property (nonatomic, retain) SensorData *lastSensorData;

@property (nonatomic) int retrievedFirstCalCheck;
@property (nonatomic) int retrievedLastCalCheck;

@property (nonatomic) BOOL requestedFirstCalCheck;
@property (nonatomic) BOOL requestedLastCalCheck;

@property (nonatomic) int retrievedCalibrationDate;
@property (nonatomic) BOOL requestedCalibrationDate;

@property (nonatomic) BOOL requestedStoringFirstCalCheck;

@property (nonatomic, weak) CDSensor *sensor;
@property (nonatomic, weak) CDCalCheck *firstCalCheck;
@property (nonatomic, weak) CDCalCheck *lastCalCheck;
@property (nonatomic, weak) CDCalibrationDate *calibrationDate;
@property (nonatomic, weak) OSSaltSolution *saltSolution;

@property (nonatomic) BOOL shouldRecertification;
@property (nonatomic) int isInWarningPeriodWithCalibrationDate;

@property (nonatomic) CalCheckResult result;

@property (nonatomic) NSDate *requestedDate;

- (id)initWithSsn:(NSString *)ssn;

@end
