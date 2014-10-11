//
//  OSExpirationManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/9/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

// 2 years
#define kMonthsAfterExpiration       (2 * 12)

@interface OSExpirationManager : NSObject

+ (NSDate *)expirationDateWithCalibrationDate:(NSDate *)calibrationDate;

@end
