//
//  OSServerManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/1/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSServerManager : NSObject

@property (nonatomic) BOOL isLoggedIn;

+ (OSServerManager *)sharedInstance;
- (BOOL)hasConnectivity;

- (void)storeCalCheck:(NSString *)ssn
                   rh:(float)rh
                 temp:(float)temp
            salt_name:(NSString *)salt_name
                 date:(NSDate *)date
             complete:(void(^)(BOOL success))block;

- (void)retrieveCalCheckForSensor:(NSString *)sensor
                            first:(BOOL)first
                         complete:(void(^)(BOOL success, NSString *ssn, float rh, float temp, NSString *salt_name, NSDate *date))block;

- (void)retrieveCalibrationDateForSensor:(NSString *)sensor
                                complete:(void(^)(BOOL success, NSDate *date))block;

- (BOOL)loginWithUserName:(NSString *)userName
                 password:(NSString *)password
                 complete:(void(^)(BOOL))block;

- (void)logout;

@end
