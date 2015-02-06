//
//  SensorData.m
//  OneScreen
//
//  Created by Xiaoxue Han on 2/6/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import "SensorData.h"

@implementation SensorData

- (BOOL)isEqual:(id)b {
    SensorData *bb = (SensorData *)b;
    
    if (bb == nil ||
        ![bb isKindOfClass:[SensorData class]])
        return false;
    
    if (self.batteryLevel == bb.batteryLevel &&
        self.rh == bb.rh &&
        self.ambientRh == bb.ambientRh &&
        self.temp == bb.temp &&
        self.ambientTemp == bb.ambientTemp &&
        [self.ssn isEqualToString:bb.ssn])
        return true;
    return false;
}

@end
