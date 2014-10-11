//
//  ServerManager.h
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerManagerDelegate.h"
#import "ServerGatewayDelegate.h"

@class ServerGateway;

@interface ServerManager : NSObject <ServerGatewayDelegate>

@property (nonatomic, assign) id<ServerManagerDelegate> delegate;
@property (nonatomic, retain) ServerGateway *serverGateway;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * userpassword;

- (BOOL)isUserLoggedIn;
- (BOOL)login;
- (void)logout;

- (void)getExpirationDateForSensor:(NSString*)sensorSerial;
//- (void)getExpirationDatesForSensor:(NSString*)sensorArray;

- (void)uploadDataFileAtPath:(NSString*)path;
- (void) checkServerAvailability;

- (void)cancel;

- (void)storeData:(NSDictionary *)data;
- (void)retrieveData:(NSString *)ssn;

- (void)retrieveOldestData:(NSString *)ssn;

@end
