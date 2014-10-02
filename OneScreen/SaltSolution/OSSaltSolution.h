//
//  OSSaltSolution.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/2/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSSaltSolution : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *solution;
@property (nonatomic) BOOL calculable;
@property (nonatomic) BOOL storable;

- (id)initWithName:(NSString *)name solution:(NSString *)solution calculable:(BOOL)calculable storable:(BOOL)storable;

@end
