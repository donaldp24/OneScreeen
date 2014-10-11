//
//  OSExpirationManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/9/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSExpirationManager.h"
#import "NSDate+convenience.h"

@implementation OSExpirationManager

+ (NSDate *)expirationDateWithCalibrationDate:(NSDate *)calibrationDate
{
    if (calibrationDate == nil)
        return nil;
    NSDate *expirationDate = [calibrationDate offsetMonth:kMonthsAfterExpiration];
    return expirationDate;
}

@end
