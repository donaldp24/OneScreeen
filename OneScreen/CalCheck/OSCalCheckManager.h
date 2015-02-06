//
//  OSCalCheckManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 2/6/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSModelManager.h"
#import "OSServerManager.h"
#import "OSSaltSolutionManager.h"
#import "SensorInfo.h"


@interface OSCalCheckManager : NSObject

+ (OSCalCheckManager *)sharedInstance;

@property (nonatomic, retain) SensorInfo *currSensorInfo;
@property (nonatomic, retain) OSSaltSolution *currSaltSolution;

- (void)onGetReading:(SensorData *)sensorData;
- (void) onSaltSolutionChanged:(OSSaltSolution *)saltSolution;
- (void) onStoreCalCheck:(SensorInfo *)sensorInfo sensorData:(SensorData *)sensorData;
- (SensorInfo *)getSensorInfo:(NSString *)ssn;

@end

