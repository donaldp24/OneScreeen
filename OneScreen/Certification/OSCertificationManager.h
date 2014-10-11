//
//  OSCertificationManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/9/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMessageForRecertification  @"This sensor has not had a factory recertification of calibration within the last %d months.  To ensure compliance with ASTM F2170, please return to Wagner Meters for an annual calibration recertification. No Cal Check data will be stored until this sensor is within compliance."

#define kMessageForBeforeRecertification    @"This sensor is due for recertification of calibration by manufacturer within %d days."

#define kMessageForDueRecertification       @"This sensor's calibration has not been recertified by manufacturer in the previous 12 months"

// 60 days
#define kDaysBeforeRecertificationForWarning    (60)

// 12 months
#define kMonthsAfterRecertification     (12)

@interface OSCertificationManager : NSObject

// compare (expiration date - calibration date + 2 years) : (fist cal check date + 12 months)
// return earlier date of them
+ (NSDate *)earlierRecertificationDate:(NSDate *)calibrationDate firstCalCheckDate:(NSDate *)firstCalCheckDate;

+ (BOOL)shouldRecertificationWithCalibrationDate:(NSDate *)calibrationDate firstCalCheckDate:(NSDate *)firstCalCheckDate;

+ (int)isInWarningPeriodWithCalibrationDate:(NSDate *)calibrationDate firstCalCheckDate:(NSDate *)firstCalCheckDate;

+ (NSString *)messageForRecertification;

+ (NSString *)messageForBeforeRecertification:(int)days;

+ (NSString *)messageForDueRecertification;

@end
