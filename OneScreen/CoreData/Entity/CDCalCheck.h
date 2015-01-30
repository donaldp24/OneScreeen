//
//  CDCalCheck.h
//  OneScreen
//
//  Created by Xiaoxue Han on 1/29/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CDCalCheck : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * rh;
@property (nonatomic, retain) NSString * salt_name;
@property (nonatomic, retain) NSString * ssn;
@property (nonatomic, retain) NSNumber * temp;
@property (nonatomic, retain) NSNumber * stored_on_server;

@end
