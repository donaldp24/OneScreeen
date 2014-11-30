//
//  OSServerManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/1/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSServerManagerDelegate <NSObject>

@optional
- (void)didLogin:(BOOL)success;
- (void)didRetrieveCalibrationDate:(NSString *)ssn success:(BOOL)success;
- (void)didRetrieveCalCheck:(NSString *)ssn success:(BOOL)success first:(BOOL)first;
- (void)didStoreCalCheck:(NSString *)ssn success:(BOOL)success;

@end

@interface OSServerManager : NSObject

@property (nonatomic, retain) id<OSServerManagerDelegate> delegate;

+ (OSServerManager *)sharedInstance;

- (void)storeCalCheck:(NSDictionary *)calCheck;
- (void)retrieveCalCheckForSensor:(NSString *)sensor first:(BOOL)first;
- (void)retrieveCalibrationDateForSensor:(NSString *)sensor;

- (void)loginWithUserName:(NSString *)userName password:(NSString *)password;
- (void)logout;

@end
