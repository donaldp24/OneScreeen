//
//  OSSaltSolutionManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/2/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSSaltSolution.h"

#define kSaltSolutionNone       @"None"
#define kSaltSolutionNaBr       @"NaBr"
#define kSaltSolutionNaCl       @"NaCl"
#define kSaltSolutionKCl        @"KCl"

typedef NS_ENUM(int, CalCheckResult) {
    CalCheckResultError = -1,
    CalCheckResultPass = 0,
    CalCheckResultFail = 1
};

@interface OSSaltSolutionManager : NSObject

@property (nonatomic, retain) NSMutableArray *arraySalts;

+ (OSSaltSolutionManager *)sharedInstance;

- (CalCheckResult)calCheckWithRh:(CGFloat)rh temp_f:(CGFloat)temp_f saltSolution:(OSSaltSolution *)saltSolution;
- (OSSaltSolution *)saltSolutionWithSolution:(NSString *)solution;
- (OSSaltSolution *)defaultSolution;

@end
