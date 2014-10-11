//
//  OSCertificationManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/9/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSCertificationManager.h"
#import "NSDate+convenience.h"
#import "NSDate+String.h"
#import "OSExpirationManager.h"

@implementation OSCertificationManager

#pragma mark - private functions
// compare (expiration date - calibration date + 2 years) : (fist cal check date + 12 months)
// return earlier date of them
+ (NSDate *)earlierRecertificationDate:(NSDate *)calibrationDate firstCalCheckDate:(NSDate *)firstCalCheckDate
{
    NSDate *earlierDate = nil;
    if (calibrationDate == nil)
    {
        if (firstCalCheckDate == nil)
            return nil;
        else
            earlierDate = [firstCalCheckDate offsetMonth:kMonthsAfterRecertification];
    }
    else
    {
        NSDate *expiratinDate = [OSExpirationManager expirationDateWithCalibrationDate:calibrationDate];
        
        // check first cal check date
        if (firstCalCheckDate == nil)
            earlierDate = expiratinDate;
        else
        {
            NSDate *recertificationDate = [firstCalCheckDate offsetMonth:kMonthsAfterRecertification];
            if ([recertificationDate compare:expiratinDate] == NSOrderedAscending)
                earlierDate = recertificationDate;
            else
                earlierDate = expiratinDate;
        }
    }
    
    return earlierDate;
}

#pragma mark - public functions
+ (BOOL)shouldRecertificationWithCalibrationDate:(NSDate *)calibrationDate firstCalCheckDate:(NSDate *)firstCalCheckDate
{
    NSDate *earlierDate = [OSCertificationManager earlierRecertificationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
    
    if (earlierDate == nil)
        return NO;

    NSDate *today = [NSDate date];
    NSComparisonResult result = [today compareWithoutHour:earlierDate];
    if (result == NSOrderedSame || result == NSOrderedDescending)
        return YES;
    return NO;
}

+ (int)isInWarningPeriodWithCalibrationDate:(NSDate *)calibrationDate firstCalCheckDate:(NSDate *)firstCalCheckDate
{
    NSDate *earlierDate = [OSCertificationManager earlierRecertificationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
    if (earlierDate == nil)
        return 0;
    
    NSDate *today = [NSDate date];
    NSDate *beforeDay = [earlierDate offsetDay:-kDaysBeforeRecertificationForWarning];
    NSComparisonResult result1 = [today compareWithoutHour:earlierDate];
    NSComparisonResult result2 = [beforeDay compareWithoutHour:today];
    if (result1 == NSOrderedAscending &&
        (result2 == NSOrderedSame || result2 == NSOrderedAscending))
    {
        int days = (int)[NSDate daysBetweenDate:today andDate:earlierDate];
        return days;
    }
    return 0;
}

+ (NSString *)messageForRecertification
{
    NSString *msg = [NSString stringWithFormat:kMessageForRecertification, kMonthsAfterRecertification];
    return msg;
}

+ (NSString *)messageForBeforeRecertification:(int)days
{
    NSString *msg = [NSString stringWithFormat:kMessageForBeforeRecertification, days];
    return msg;
}

+ (NSString *)messageForDueRecertification
{
    NSString *msg = [NSString stringWithFormat:@"%@", kMessageForDueRecertification];
    return msg;
}

@end
