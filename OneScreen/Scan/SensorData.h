//
//  SensorData.h
//  OneScreen
//
//  Created by Xiaoxue Han on 2/6/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SensorData : NSObject

@property (nonatomic) int batteryLevel;
@property (nonatomic) float rh;
@property (nonatomic) float ambientRh;
@property (nonatomic) float temp;
@property (nonatomic) float ambientTemp;
@property (nonatomic, strong) NSDate *readingTimeStamp;
@property (nonatomic, strong) NSString *ssn;

- (BOOL)isEqual:(id)b;

@end
