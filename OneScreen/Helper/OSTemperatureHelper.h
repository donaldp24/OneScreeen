//
//  OSTemperatureHelper.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/26/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSTemperatureHelper : NSObject

+ (NSString *)unitCelcius;
+ (NSString *)unitFahrenheit;
+ (CGFloat)celciusFromFahrenheit:(CGFloat)fah;
+ (CGFloat)fahrenheitFromCelcius:(CGFloat)celcius;

@end
