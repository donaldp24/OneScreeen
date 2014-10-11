//
//  CDCalCheck.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/9/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDCalCheck : NSManagedObject

@property (nonatomic, retain) NSString * ssn;
@property (nonatomic, retain) NSNumber * rh;
@property (nonatomic, retain) NSNumber * temp;
@property (nonatomic, retain) NSString * salt_name;
@property (nonatomic, retain) NSDate * date;

@end
