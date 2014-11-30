//
//  OSSaltSolution.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/2/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSSaltSolution.h"

@implementation OSSaltSolution

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[OSSaltSolution class]])
        return NO;
    OSSaltSolution *obj = (OSSaltSolution *)object;
    if ([obj.salt_name isEqualToString:self.salt_name])
        return YES;
    return NO;
}

- (id)initWithDesc:(NSString *)desc salt_name:(NSString *)salt_name calculable:(BOOL)calculable storable:(BOOL)storable
{
    self = [super init];
    self.desc = desc;
    self.salt_name = salt_name;
    self.calculable = calculable;
    self.storable = storable;
    return self;
}

@end
