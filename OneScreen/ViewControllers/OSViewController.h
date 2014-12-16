//
//  OSViewController.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/25/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSViewController : UIViewController

+ (OSViewController *)sharedInstance;

@end

@interface SensorInfo : NSObject

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic, retain) NSDictionary *firstSensorData;
@property (nonatomic, retain) NSDictionary *lastSensorData;
@property (nonatomic) BOOL retrievedFirstCalCheck;
@property (nonatomic) BOOL retrievedLastCalCheck;
@property (nonatomic) BOOL requestedFirstCalCheck;
@property (nonatomic) BOOL requestedLastCalCheck;

@property (nonatomic) BOOL retrievedCalibrationDate;
@property (nonatomic) BOOL requestedCalibrationDate;

@property (nonatomic) BOOL requestedStoringFirstCalCheck;

- (id)initWithSsn:(NSString *)ssn;

@end
