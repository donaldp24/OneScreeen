//
//  OSSaltSolution.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/2/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSSaltSolution : NSObject

@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *salt_name;
@property (nonatomic) BOOL calculable;
@property (nonatomic) BOOL storable;

- (id)initWithDesc:(NSString *)desc salt_name:(NSString *)salt_name calculable:(BOOL)calculable storable:(BOOL)storable;

@end
