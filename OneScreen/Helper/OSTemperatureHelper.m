//
//  OSTemperatureHelper.m
//  OneScreen
//
//  Created by Xiaoxue Han on 9/26/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSTemperatureHelper.h"

@implementation OSTemperatureHelper

+ (NSString *)unitCelcius
{
    return @"°C";
}

+ (NSString *)unitFahrenheit
{
    return @"°F";
}

+ (CGFloat)celciusFromFahrenheit:(CGFloat)fah
{
    //[°C] = ([°F] - 32) × 5/9
    //[°F] = [°C] × 9/5 + 32
    return (fah - 32) * 5.0 / 9.0;
}

+ (CGFloat)fahrenheitFromCelcius:(CGFloat)celcius
{
    return ((celcius * 9.0 / 5.0) + 32);
}

@end
