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
    if ([obj.solution isEqualToString:self.solution])
        return YES;
    return NO;
}

- (id)initWithName:(NSString *)name solution:(NSString *)solution calculable:(BOOL)calculable storable:(BOOL)storable
{
    self = [super init];
    self.name = name;
    self.solution = solution;
    self.calculable = calculable;
    self.storable = storable;
    return self;
}

@end
