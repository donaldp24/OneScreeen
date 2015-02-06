//
//  SensorInfo.m
//  OneScreen
//
//  Created by Xiaoxue Han on 2/6/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import "SensorInfo.h"

@implementation SensorInfo

- (id)initWithSsn:(NSString *)ssn {
    self = [super init];
    [self initMembers:ssn];
    return self;
}

- (void)initMembers:(NSString *)ssn {
    
    self.ssn = ssn;
    
    self.firstSensorData = nil;
    self.lastSensorData = nil;
    
    self.retrievedFirstCalCheck = RETRIEVED_NONE;
    self.retrievedLastCalCheck = RETRIEVED_NONE;
    
    self.requestedFirstCalCheck = NO;
    self.requestedLastCalCheck = NO;
    
    self.retrievedCalibrationDate = RETRIEVED_NONE;
    self.requestedCalibrationDate = NO;
    
    self.requestedStoringFirstCalCheck = NO;
    
    self.sensor = nil;
    self.calibrationDate = nil;
    self.firstCalCheck = nil;
    self.lastCalCheck = nil;
    self.saltSolution = nil;
    
    self.shouldRecertification = NO;
    self.isInWarningPeriodWithCalibrationDate = 0;
    
    self.result = CalCheckResultError;
    
    self.requestedDate = [NSDate date];
}

@end
