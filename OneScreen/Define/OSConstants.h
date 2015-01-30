//
//  OSConstants.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/25/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#ifndef OneScreen_OSConstants_h
#define OneScreen_OSConstants_h

#define kDateTimeFormatWithTimezone             @"yyyy-MM-dd HH:mm:ss ZZZ"
#define kDateTimeFormat                         @"yyyy-MM-dd HH:mm:ss"
#define kDateFormat                             @"MMM dd, yyyy"
#define kUploadDataDateFormat                   @"yyyy-MM-dd HH:mm:ss"
#define KJSONDateTimeFormat                     @"yyyy-MM-dd'T'HH:mm:ss.SSSz"

//#define kShortDateFormat                        @"yy-M-d"
#define kShortDateFormat                        @"MMM dd, yyyy"

#define kGlobalUserName                         @"donald"
#define kGlobalUserPass                         @"donald"

#define kSqliteName                             @"Model.sqlite"

// notifications
//#define kCalibrationDateChanged                 @"calibration date changed"
//#define kLastCalCheckChanged                        @"calcheck data changed"
//#define kFirstCalCheckChanged                      @"first calcheck data changed"
#define kDataChanged                      @"data for cal cert due changed"

// colors for cal check due
#define kDefaultDueDateColor        [UIColor colorWithRed:0 green:255 blue:0 alpha:0.8]
#define kBeforeDueDateColor         [UIColor colorWithRed:1 green:1 blue:0 alpha:0.8]
#define kDuedDueDateColor           [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8]

// custom fonts
#define kFontBebasNeue(fSize)           [UIFont fontWithName:@"BebasNeue" size:fSize]
#define kFontMyriadProRegular(fSize)    [UIFont fontWithName:@"MyriadPro-Regular" size:fSize]


// constants for table view cell
#define kDefaultBackgroundColor     [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0]
#define kReadingBackgroundColor     [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]

#define kNameTextColor              [UIColor colorWithRed:243/255.0 green:143/255.0 blue:29/255.0 alpha:1.0]
#define kSerialTextColor            [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]

#define kSwipeAnimateDuration (0.25)


// format constant
#define kFormatForRh        @"%.1f"
#define kFormatForTemp      @"%.1f"
#define kFormatForAmbRh     @"%.1f"
#define kFormatForAmbTemp   @"%.1f"


// refresh
#define kRefreshHintText        @"Pull to refresh"
#define kRefreshTintColor       [UIColor colorWithWhite:1 alpha:1]
#define kRefreshProcessingText  @"Updating..."

// parse
#define kSensorDataBatteryKey  @"battery"
#define kSensorDataRHKey  @"rh"
#define kSensorDataRHAmbientKey  @"rhAmbient"
#define kSensorDataTemperatureKey  @"temp"
#define kSensorDataTemperatureAmbientKey  @"tempAmbient"
#define kSensorDataReadingTimestampKey  @"readingTimestamp"
#define kSensorDataSerialNumberKey  @"serial"

// configure

// indicating to use job or nob 0 : not use, 1 : use
#define kUseJobsFunction            0


#endif
