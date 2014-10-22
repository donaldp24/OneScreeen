//
//  CDJob.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/19/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDJob : NSManagedObject

@property (nonatomic, retain) NSNumber * deleted;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSDate * createtime;
@property (nonatomic, retain) NSDate * starttime;
@property (nonatomic, retain) NSDate * endtime;

@end
