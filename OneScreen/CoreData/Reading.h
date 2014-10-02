//
//  Reading.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Reading : NSManagedObject

@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * rh;
@property (nonatomic, retain) NSNumber * temp;
@property (nonatomic, retain) NSNumber * ambientRh;
@property (nonatomic, retain) NSNumber * ambientTemp;
@property (nonatomic, retain) NSString * sensorSerial;
@property (nonatomic, retain) NSNumber * battery;
@property (nonatomic, retain) NSDate * calibrationDate;
@property (nonatomic, retain) NSDate * expirationDate;

@end
