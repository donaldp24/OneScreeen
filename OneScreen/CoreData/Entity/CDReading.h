//
//  CDReading.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/20/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDReading : NSManagedObject

@property (nonatomic, retain) NSNumber * ambRh;
@property (nonatomic, retain) NSNumber * ambTemp;
@property (nonatomic, retain) NSString * jobUid;
@property (nonatomic, retain) NSNumber * rh;
@property (nonatomic, retain) NSString * ssn;
@property (nonatomic, retain) NSNumber * temp;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * battery;

@end
