//
//  OSCalCheckManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 2/6/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import "OSCalCheckManager.h"
#import "OSConstants.h"
#import "OSSyncManager.h"
#import "OSCertificationManager.h"

static OSCalCheckManager *_sharedCalCheckManager = nil;

#define kLocalChanged       @"CalCheckManager_kLocalChanged"

@interface OSCalCheckManager () {
    //
}

@property (nonatomic, retain) NSMutableDictionary *dicSensorData;

@end

@implementation OSCalCheckManager

+ (OSCalCheckManager *)sharedInstance
{
    if (_sharedCalCheckManager == nil) {
        _sharedCalCheckManager = [[OSCalCheckManager alloc] init];
    }
    return _sharedCalCheckManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.currSaltSolution = nil;
        self.currSensorInfo = nil;
        self.dicSensorData = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLocalChanged:) name:kLocalChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLoginSuccess:) name:kLoginSuccess object:nil];
    }
    return self;
}

- (void)onLocalChanged:(NSNotification *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ssn = (NSString *)info.object;
        SensorInfo *sensorInfo = [self getSensorInfo:ssn];
        if (sensorInfo == nil)
            return;
        [self _recheckData:sensorInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:sensorInfo.ssn];
    });
    
}

- (void)onLoginSuccess:(NSNotification *)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currSensorInfo != nil) {
            [self _checkCalibrationDate:self.currSensorInfo];
            [self _checkFirstCalCheck:self.currSensorInfo];
            [self _checkLastCalCheck:self.currSensorInfo];
        }
    });
}

/*
 * called when get reading
 */
- (void)onGetReading:(SensorData *)sensorData {
    NSString *newSsn = sensorData.ssn;
    if (newSsn == nil || newSsn.length == 0)
        return;
    
    if (sensorData == nil) {
        NSLog(@"ERROR - sensor data is null : displayData");
        return;
    }
    
    BOOL isSensorChanged = false;
    if (self.currSensorInfo == nil)
        isSensorChanged = true;
    else if (![self.currSensorInfo.ssn isEqualToString:sensorData.ssn])
        isSensorChanged = true;
    
    // put data as lastSensorData
    SensorInfo *sensorInfo = [self.dicSensorData objectForKey:newSsn];
    if (sensorInfo == nil) {
        sensorInfo = [[SensorInfo alloc] initWithSsn:newSsn];
        sensorInfo.firstSensorData = sensorData;
        [self.dicSensorData setObject:sensorInfo forKey:newSsn];
    }
    
    NSTimeInterval secondsBetween = [[NSDate date] timeIntervalSinceDate:sensorInfo.requestedDate];
    if (secondsBetween > 60 * 60 /* 1 hrs */) {
        sensorInfo.requestedCalibrationDate = false;
        sensorInfo.retrievedCalibrationDate = RETRIEVED_NONE;
        
        sensorInfo.requestedFirstCalCheck = false;
        sensorInfo.retrievedFirstCalCheck = RETRIEVED_NONE;
        
        sensorInfo.requestedLastCalCheck = false;
        sensorInfo.retrievedLastCalCheck = RETRIEVED_NONE;
        
        sensorInfo.requestedDate = [NSDate date];
    }
    
    //sensorInfo.lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:newSsn];
    
    sensorInfo.lastSensorData = sensorData;
    sensorInfo.saltSolution = self.currSaltSolution;
    
    self.currSensorInfo = sensorInfo;
    
    // save reading
    /*
    if ([OSAppContext sharedInstance].isJobStarted && [OSAppContext sharedInstance].currentJob != nil)
    {
        [[OSModelManager sharedInstance] saveReadingForJob:[OSAppContext sharedInstance].currentJob.uid sensorData:sensorData];
    }
    else
    {
        [[OSModelManager sharedInstance] saveReadingForJob:nil sensorData:sensorData];
    }
     */
    [[OSModelManager sharedInstance] saveReadingForJob:nil sensorData:sensorData];
    
    // get sensor
    if (sensorInfo.sensor == nil)
        sensorInfo.sensor = [[OSModelManager sharedInstance] getSensorForSerial:newSsn];
    
    // create sensor
    if (sensorInfo.sensor == nil) {
        [[OSModelManager sharedInstance] setSensor:sensorInfo.ssn];
        sensorInfo.sensor = [[OSModelManager sharedInstance] getSensorForSerial:newSsn];
    }
    
    if (sensorInfo.sensor != nil) {
        
        // check sensor deleted, if deleted then un-delete it.
        if ([sensorInfo.sensor.deletedInv boolValue]) {
            sensorInfo.sensor.deletedInv = @(NO);
            [[OSModelManager sharedInstance] saveContext];
        }
        
        // update last reading timestamp
        [[OSModelManager sharedInstance] setLastReadingTimeForSensor:sensorInfo.sensor lastTime:[NSDate date]];
    }
    
    [self _checkCalibrationDate:sensorInfo];
    
    [self _checkFirstCalCheck:sensorInfo];
    
    [self _checkLastCalCheck:sensorInfo];
    
    if (isSensorChanged) {
        if (sensorInfo.lastCalCheck != nil &&
            ![sensorInfo.lastCalCheck.stored_on_server boolValue] &&
            sensorInfo.lastCalCheck.salt_name != nil &&
            ![sensorInfo.lastCalCheck.salt_name isEqualToString:[[OSSaltSolutionManager sharedInstance] defaultSolution].salt_name]) {
            [[OSSyncManager sharedInstance] addCalcheckToSyncList:sensorInfo.lastCalCheck.ssn
                                                               rh:[sensorInfo.lastCalCheck.rh floatValue]
                                                             temp:[sensorInfo.lastCalCheck.temp floatValue]
                                                        salt_name:sensorInfo.saltSolution.salt_name
                                                             date:sensorInfo.lastCalCheck.date];
        }
    }
    
    [self _recheckData:sensorInfo];
    
    if (sensorInfo != nil)
        [[NSNotificationCenter defaultCenter] postNotificationName:kReadingTaken object:sensorInfo.ssn];
}

- (void)_retrieveFirstCalCheckSuccess:(SensorInfo *)sensorInfo
                             ssn:(NSString *)ssn
                              rh:(float)rh
                            temp:(float)temp
                       salt_name:(NSString *)salt_name
                            date:(NSDate *)date
                       errorType:(ErrorType)errorType
{
    __block SensorInfo *finalSensorInfo = sensorInfo;
    
    if (finalSensorInfo.firstCalCheck != nil &&
        ![finalSensorInfo.firstCalCheck.stored_on_server boolValue])
    {
        // compare two data
        if ([finalSensorInfo.firstCalCheck.date compare:date] == NSOrderedAscending)
        {
            // store it on server
            [[OSServerManager sharedInstance] storeCalCheck:finalSensorInfo.firstCalCheck.ssn
                                                         rh:[finalSensorInfo.firstCalCheck.rh floatValue]
                                                       temp:[finalSensorInfo.firstCalCheck.temp floatValue]
                                                  salt_name:finalSensorInfo.firstCalCheck.salt_name
                                                       date:finalSensorInfo.firstCalCheck.date
                                                   complete:^(BOOL success, ErrorType errorType) {
                                                       if (success) {
                                                           dispatch_async(dispatch_get_main_queue(), ^{
                                                               finalSensorInfo.firstCalCheck.stored_on_server = @(YES);
                                                               [[OSModelManager sharedInstance] saveContext];
                                                           });
                                                       }
                                                   }];
        }
        else
        {
            // store it
            dispatch_async(dispatch_get_main_queue(), ^{
                [[OSModelManager sharedInstance] setCalCheckForSensor:ssn
                                                                 date:date
                                                                   rh:rh
                                                                 temp:temp
                                                            salt_name:salt_name
                                                                first:YES
                                                     stored_on_server:YES];
                finalSensorInfo.firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:finalSensorInfo.ssn];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:finalSensorInfo.ssn];
            });
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[OSModelManager sharedInstance] setCalCheckForSensor:ssn
                                                             date:date
                                                               rh:rh
                                                             temp:temp
                                                        salt_name:salt_name
                                                            first:YES
                                                 stored_on_server:YES];
            
            
            finalSensorInfo.firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:finalSensorInfo.ssn];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:finalSensorInfo.ssn];
        });
        
    }
    finalSensorInfo.retrievedFirstCalCheck = RETRIEVED_DATA;
}

- (void) _retrievedFirstCalCheckFailed:(SensorInfo *)sensorInfo errorType:(ErrorType)errorType
{
    __block SensorInfo *finalSensorInfo = sensorInfo;
    
    if (errorType == ErrorTypeParseError) {
        finalSensorInfo.retrievedFirstCalCheck = RETRIEVED_NODATA;
        
        if (finalSensorInfo.firstCalCheck == nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                // store it locally
                [[OSModelManager sharedInstance] setCalCheckForSensor:finalSensorInfo.firstSensorData.ssn
                                                                 date:finalSensorInfo.firstSensorData.readingTimeStamp
                                                                   rh:finalSensorInfo.firstSensorData.rh
                                                                 temp:finalSensorInfo.firstSensorData.temp
                                                            salt_name:[[OSSaltSolutionManager sharedInstance] defaultSolution].salt_name
                                                                first:YES
                                                     stored_on_server:NO];
                
                finalSensorInfo.firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:finalSensorInfo.ssn];
                [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:finalSensorInfo.ssn];
                
                if (finalSensorInfo.firstCalCheck != nil)
                {
                    [[OSServerManager sharedInstance] storeCalCheck:finalSensorInfo.ssn
                                                                 rh:[finalSensorInfo.firstCalCheck.rh floatValue]
                                                               temp:[finalSensorInfo.firstCalCheck.temp floatValue]
                                                          salt_name:finalSensorInfo.firstCalCheck.salt_name
                                                               date:finalSensorInfo.firstCalCheck.date
                                                           complete:^(BOOL success, ErrorType errorType) {
                                                               if (success) {
                                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                                       [[OSModelManager sharedInstance] setStoredOnServerForCalCheck:finalSensorInfo.firstCalCheck stored_on_server:YES];
                                                                   });
                                                               }
                                                           }];
                }
            });
            
        }
    }
    else
        finalSensorInfo.retrievedFirstCalCheck = RETRIEVED_NETERROR;
}

- (void) _checkFirstCalCheck:(SensorInfo *)sensorInfo {
    if (sensorInfo == nil)
        return;
    
    // check first cal check date
    if (sensorInfo.firstCalCheck == nil)
        sensorInfo.firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:sensorInfo.ssn];
    
    // store it
    if (sensorInfo.requestedFirstCalCheck == false ||
        sensorInfo.retrievedFirstCalCheck == RETRIEVED_NETERROR) {
        // retrieve first cal check
        if (![OSServerManager sharedInstance].isLoggedIn ||
            ![[OSServerManager sharedInstance] hasConnectivity]) {
            // server not logged in or
            // network not connected
            if (sensorInfo.firstCalCheck == nil) {
                // store first cal check locally
                [[OSModelManager sharedInstance] setCalCheckForSensor:sensorInfo.firstSensorData.ssn
                                                                 date:sensorInfo.firstSensorData.readingTimeStamp
                                                                   rh:sensorInfo.firstSensorData.rh
                                                                 temp:sensorInfo.firstSensorData.temp
                                                            salt_name:[[OSSaltSolutionManager sharedInstance] defaultSolution].salt_name
                                                                first:YES
                                                     stored_on_server:NO];
                
                sensorInfo.firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:sensorInfo.ssn];
            }
        }
        else {
            sensorInfo.requestedFirstCalCheck = true;
            __block SensorInfo *finalSensorInfo = sensorInfo;
            
            // retry to retrieve cal check
            [[OSServerManager sharedInstance] retrieveCalCheckForSensor:sensorInfo.ssn
                                                                  first:YES
                                                               complete:^(BOOL success, NSString *ssn, float rh, float temp, NSString *salt_name, NSDate *date, ErrorType errorType) {
                                                                   if (success) {
                                                                       [self _retrieveFirstCalCheckSuccess:finalSensorInfo
                                                                                                       ssn:ssn
                                                                                                        rh:rh
                                                                                                      temp:temp
                                                                                                 salt_name:salt_name
                                                                                                      date:date
                                                                                                 errorType:errorType];
                                                                   }
                                                                   else {
                                                                       [self _retrievedFirstCalCheckFailed:finalSensorInfo errorType:errorType];
                                                                   }
                                                               }];
        }
    }
}

- (void) _checkLastCalCheck:(SensorInfo *)sensorInfo {
    if (sensorInfo == nil)
        return;
    
    // retrieve last cal check
    if (sensorInfo.lastCalCheck == nil)
        sensorInfo.lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:sensorInfo.ssn];
    
    // retrieve last cal check
    if (sensorInfo.requestedLastCalCheck == false ||
        sensorInfo.retrievedLastCalCheck == RETRIEVED_NETERROR) {
        if (![OSServerManager sharedInstance].isLoggedIn ||
            ![[OSServerManager sharedInstance] hasConnectivity]) {
            // not retrieve
        }
        else {
            __block SensorInfo *finalSensorInfo = sensorInfo;
            sensorInfo.requestedLastCalCheck = true;
            [[OSServerManager sharedInstance] retrieveCalCheckForSensor:finalSensorInfo.ssn
                                                                  first:NO
                                                               complete:^(BOOL success, NSString *ssn, float rh, float temp, NSString *salt_name, NSDate *date, ErrorType errorType) {
                                                                   if (success) {
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                           // store it
                                                                           [[OSModelManager sharedInstance] setCalCheckForSensor:ssn
                                                                                                                            date:date
                                                                                                                              rh:rh
                                                                                                                            temp:temp
                                                                                                                       salt_name:salt_name
                                                                                                                           first:NO
                                                                                                                stored_on_server:YES];
                                                                           
                                                                           finalSensorInfo.lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:finalSensorInfo.ssn];
                                                                           
                                                                           finalSensorInfo.retrievedLastCalCheck = RETRIEVED_DATA;
                                                                           
                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:finalSensorInfo.ssn];
                                                                       });
                                                                   }
                                                                   else {
                                                                       if (errorType == ErrorTypeParseError)
                                                                           finalSensorInfo.retrievedLastCalCheck = RETRIEVED_NODATA;
                                                                       else
                                                                           finalSensorInfo.retrievedLastCalCheck = RETRIEVED_NETERROR;
                                                                   }

                                                               }];
        }
    }
}

- (void) _checkCalibrationDate:(SensorInfo *)sensorInfo {
    if (sensorInfo == nil)
        return;
    
    // check calibration date
    if (sensorInfo.calibrationDate == nil) {
        
        // calibration date for sensor
        if (sensorInfo.requestedCalibrationDate == false ||
            sensorInfo.retrievedCalibrationDate == RETRIEVED_NETERROR) {
            // request calibration date
            if (![OSServerManager sharedInstance].isLoggedIn ||
                ![[OSServerManager sharedInstance] hasConnectivity]) {
                // server not logged in or
                // network is not linked
            }
            else {
                sensorInfo.requestedCalibrationDate = true;
                __block SensorInfo *finalSensorInfo = sensorInfo;
                [[OSServerManager sharedInstance] retrieveCalibrationDateForSensor:sensorInfo.ssn
                                                                          complete:^(BOOL success, NSDate *date, ErrorType errorType) {
                                                                              if (success) {
                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                      finalSensorInfo.retrievedCalibrationDate = RETRIEVED_DATA;
                                                                                      [[OSModelManager sharedInstance] setCalibrationDate:date sensorSerial:finalSensorInfo.ssn];
                                                                                      
                                                                                      finalSensorInfo.calibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:finalSensorInfo.ssn];
                                                                                      
                                                                                      [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:finalSensorInfo.ssn];
                                                                                  });
                                                                              }
                                                                              else {
                                                                                  if (errorType == ErrorTypeParseError)
                                                                                      finalSensorInfo.retrievedCalibrationDate = RETRIEVED_NODATA;
                                                                                  else
                                                                                      finalSensorInfo.retrievedCalibrationDate = RETRIEVED_NETERROR;
                                                                              }
                                                                          }];
            }
        }
    }
}

- (void) _recheckData:(SensorInfo *)sensorInfo {
    if (sensorInfo == nil)
        return;
    
    // cal check
    if (sensorInfo.saltSolution != nil &&
        sensorInfo.saltSolution.calculable)
        sensorInfo.result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:sensorInfo.lastSensorData.rh
                                                                            temp_f:sensorInfo.lastSensorData.temp
                                                                      saltSolution:sensorInfo.saltSolution];

    // check certification
    CDCalibrationDate *cdCalibrationDate = sensorInfo.calibrationDate;
    NSDate *calibrationDate = (cdCalibrationDate == nil) ? nil : cdCalibrationDate.calibrationDate;
    CDCalCheck *firstData = sensorInfo.firstCalCheck;
    NSDate *firstCalCheckDate;
    if (firstData == nil)
        firstCalCheckDate = nil;
    else
        firstCalCheckDate = firstData.date;
    
    sensorInfo.shouldRecertification = [OSCertificationManager shouldRecertificationWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
    sensorInfo.isInWarningPeriodWithCalibrationDate = [OSCertificationManager isInWarningPeriodWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
}

/*
 * called when user change salt solution
 */
- (void) onSaltSolutionChanged:(OSSaltSolution *)saltSolution {
    self.currSaltSolution = saltSolution;
    if (self.currSensorInfo == nil)
        return;
    self.currSensorInfo.saltSolution = saltSolution;
    if (saltSolution.calculable)
        self.currSensorInfo.result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:self.currSensorInfo.lastSensorData.rh
                                                                                     temp_f:self.currSensorInfo.lastSensorData.temp
                                                                               saltSolution:self.currSensorInfo.saltSolution];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kSaltChanged object:self.currSensorInfo.ssn];
}

/*
 * called when user store cal check
 */
- (void) onStoreCalCheck:(SensorInfo *)sensorInfo sensorData:(SensorData *)sensorData {
    if (![OSServerManager sharedInstance].isLoggedIn ||
        ![[OSServerManager sharedInstance] hasConnectivity]) {
        
        // store it locally
        [[OSModelManager sharedInstance] setCalCheckForSensor:sensorData.ssn
                                                         date:sensorData.readingTimeStamp
                                                           rh:sensorData.rh
                                                         temp:sensorData.temp
                                                    salt_name:sensorInfo.saltSolution.salt_name
                                                        first:NO
                                             stored_on_server:0];
         
        
        sensorInfo.lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:sensorData.ssn];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:sensorInfo.ssn];
        
        [[OSSyncManager sharedInstance] addCalcheckToSyncList:sensorData.ssn
                                                           rh:sensorData.rh
                                                         temp:sensorData.temp
                                                    salt_name:sensorInfo.saltSolution.salt_name
                                                         date:sensorData.readingTimeStamp];
    }
    else {
        [[OSServerManager sharedInstance] storeCalCheck:sensorData.ssn
                                                     rh:sensorData.rh
                                                   temp:sensorData.temp
                                              salt_name:sensorInfo.saltSolution.salt_name
                                                   date:sensorData.readingTimeStamp
                                               complete:^(BOOL success, ErrorType errorType) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [[OSModelManager sharedInstance] setCalCheckForSensor:sensorData.ssn
                                                                                                        date:sensorData.readingTimeStamp
                                                                                                          rh:sensorData.rh
                                                                                                        temp:sensorData.temp
                                                                                                   salt_name:sensorInfo.saltSolution.salt_name
                                                                                                       first:NO
                                                                                            stored_on_server:success];
                                                       
                                                       sensorInfo.lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:sensorInfo.ssn];
                                                       [[NSNotificationCenter defaultCenter] postNotificationName:kLocalChanged object:sensorInfo.ssn];
                                                       
                                                       if (!success) {
                                                           [[OSSyncManager sharedInstance] addCalcheckToSyncList:sensorData.ssn
                                                                                                              rh:sensorData.rh
                                                                                                            temp:sensorData.temp
                                                                                                       salt_name:sensorInfo.saltSolution.salt_name
                                                                                                            date:sensorData.readingTimeStamp];
                                                       }
                                                   });
                                               
                                               }];
    }
}

- (SensorInfo *)getSensorInfo:(NSString *)ssn {
    if (self.dicSensorData == nil)
        return nil;
    SensorInfo *info = [self.dicSensorData objectForKey:ssn];
    info.firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:ssn];
    info.lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:ssn];
    info.sensor = [[OSModelManager sharedInstance] getSensorForSerial:ssn];
    info.calibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:ssn];
    return info;
}


@end
