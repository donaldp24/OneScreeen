//
//  CDJob.h
//  OneScreen
//
//  Created by Xiaoxue Han on 29/10/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDJob : NSManagedObject

@property (nonatomic, retain) NSDate * createtime;
@property (nonatomic, retain) NSNumber * isdeleted;
@property (nonatomic, retain) NSDate * endtime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * starttime;
@property (nonatomic, retain) NSString * uid;

@end
