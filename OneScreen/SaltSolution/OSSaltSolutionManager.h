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

#define kSaltSolutionNameDefault    @"Normal Reading"
#define kSaltSolutionNameNaCl       @"Sodium Chloride (NaCl)"
#define kSaltSolutionNameNaBr       @"Sodium Bromide (NaBr)"
#define kSaltSolutionNameKCl        @"Potassium Chloride (KCl)"

#define kSaltSolutionNameInactive   @"Inactive Solution"
#define kSaltSolutionInactive       @"inactive"

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
- (OSSaltSolution *)inactiveSolution;
- (BOOL)isDefaultSolution:(NSString *)salt_name;
- (BOOL)isInactiveSolution:(NSString *)salt_name;

@end
