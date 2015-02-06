//
//  OSSyncManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 1/28/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCalCheck.h"

@interface SensorDataWithSaltName : NSObject

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic) float rh;
@property (nonatomic) float temp;
@property (nonatomic, retain) NSString *salt_name;
@property (nonatomic, retain) NSDate *date;

@end

@interface OSSyncManager : NSObject

+ (OSSyncManager *)sharedInstance;


- (void)addCalcheckToSyncList:(NSString *)ssn rh:(float)rh temp:(float)temp salt_name:(NSString *)salt_name date:(NSDate *)date;


@end
