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
#define kDateFormat                             @"MM-dd-yyyy"
#define kUploadDataDateFormat                   @"yyyy-MM-dd"
#define KJSONDateTimeFormat                     @"yyyy-MM-dd'T'HH:mm:ss.SSSz"
#define kShortDateFormat                        @"yy-M-d"

#define kGlobalUserName                         @"donald"
#define kGlobalUserPass                         @"donald"

#define kSqliteName                             @"Model.sqlite"

// constants for storing/retrieving data on/from server
#define kDataSuccessKey                         @"success"
#define kDataSensorSerialKey                    @"ssn"
#define kDataSaltSolutionKey                    @"salt_name"
#define kDataRhKey                              @"rh"
#define kDataTempKey                            @"temp"
#define kDataDateKey                            @"date"

// notifications
#define kCalibrationDateChanged                 @"calibration date changed"
#define kLastCalCheckChanged                        @"calcheck data changed"
#define kOldestCalCheckChanged                      @"oldest calcheck data changed"

#endif
