//
//  CDSensor.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/15/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDSensor : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * ssn;

@end
