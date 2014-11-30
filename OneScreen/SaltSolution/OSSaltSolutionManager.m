//
//  OSSaltSolutionManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/2/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSSaltSolutionManager.h"

static OSSaltSolutionManager *_sharedSaltSolutionManager = nil;

@interface OSSaltSolutionManager () {
    OSSaltSolution *inactiveSolution;
}

@end

@implementation OSSaltSolutionManager

// this function does linear interpolation between 2 known points
// it takes in the 2 known points, the known x value and returns the interpolated y value.
+ (CGFloat)YInterpWithX1:(CGFloat)X1 Y1:(CGFloat)Y1 X2:(CGFloat)X2 Y2:(CGFloat)Y2 Xi:(CGFloat)Xi
{
    CGFloat Slope = (Y2 - Y1) / (X2 - X1);
    CGFloat Intercept = Y1 - Slope * X1;
    CGFloat ret = Slope * Xi + Intercept;
    return ret;
}

// This function performs a check on a given RH (%) and Temperature (F) value for a particular saturated salt solution
// to determine if the RH is within expected results, allowing for accuracy tolerance of the sensor and for
// uncertainty of RH provided by salt solution at a particular temperature.
// this funtion will return either "PASS" or "FAIL" depending on result or "ERROR" if temp outside limits of 5 to 50 degree C
// current SALT supported are "NaBr", "NaCl", and "KCl"
+ (CalCheckResult)CAL_CHECK_WITH_RH:(CGFloat)RH TEMP_F:(CGFloat)TEMP_F SALT:(NSString *)SALT
{
    //CGFloat BASE;
    //CGFloat DELTA;
    CGFloat Salt_Base[10];
    CGFloat Salt_delta[10];
    //CGFloat Slope;
    //CGFloat Intercept;
    CGFloat RH_interpolated;
    CGFloat Delta_interpolated;
    CGFloat TEMP_C;

    // first load up the tabular known data.
    // there are known RH values for certain salts at given temperatures
    // we are using table of data as found in ASTM E-104 standard
    // the table of RH values for each salt is separated by 5 degree celsius increments (i.e., 5, 10, 15, etc...)
    // we are providing a range from 5 degree C to 50 degree C (5, 10, 15, ..., 50)
    // we will interpolate RH values based on input temperature ranging from 5 to 50 degree C
    CGFloat Salt_NaBr_base[] = {63.5, 62.2, 60.7, 59.1, 57.6, 56, 54.6, 53.2, 52, 50.9};      // Sodium Bromide RH data
    CGFloat Salt_NaCl_base[] = {75.7, 75.7, 75.6, 75.5, 75.3, 75.1, 74.9, 74.7, 74.5, 74.5};  // Sodium Chloride RH data
    CGFloat Salt_KCl_base[] = {87.7, 86.8, 85.9, 85.1, 84.2, 83.6, 83, 82.3, 81.7, 81.2};     // Potassium Chloride RH data

    // each known value of RH at a specific temperature halso has a known uncertainty associated with it
    // we are also going to be interpolating for the uncertainty for the given temperature and salt.
    // we will use the uncertainty as an allowed difference when determining whether the provided RH is within "spec"
    // since our sensor also has an allowed tolerance/accuracy of +/- 2% RH, we will add that to the salt solution
    // uncertainty to provide an overall allowed offset from measured RH to determine pass/fail result.
    CGFloat Salt_NaBr_delta[] = {0.8, 0.6, 0.6, 0.5, 0.4, 0.4, 0.4, 0.5, 0.5, 0.6};   // Sodium Bromide RH tolerance
    CGFloat Salt_NaCl_delta[] = {0.3, 0.3, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.9};   // Sodium Chloride RH tolerance
    CGFloat Salt_KCl_delta[] = {0.5, 0.4, 0.4, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.4};    // Potassium Chloride RH tolerance

    // load up working arrays of data based on salt specified
    if ([SALT isEqualToString:kSaltSolutionNaBr])
    {
        for (int i = 0; i <= 9; i++) {
            Salt_Base[i] = Salt_NaBr_base[i];
            Salt_delta[i] = Salt_NaBr_delta[i];
        }
        
    }
    else if ([SALT isEqualToString:kSaltSolutionNaCl])
    {
        for (int i = 0; i <= 9; i++) {
            Salt_Base[i] = Salt_NaCl_base[i];
            Salt_delta[i] = Salt_NaCl_delta[i];
        }
    }
    else if ([SALT isEqualToString:kSaltSolutionKCl])
    {
        for (int i = 0; i <= 9; i++) {
            Salt_Base[i] = Salt_KCl_base[i];
            Salt_delta[i] = Salt_KCl_delta[i];
        }
    }
    else
    {
        for (int i = 0; i <= 9; i++) {
            Salt_Base[i] = 0;
            Salt_delta[i] = 0;
        }
    }

    // convert fahrenheit to Celsius
    TEMP_C = (TEMP_F - 32) * (5.f / 9.f);

    // Check input data for valid constraints
    if (TEMP_C < 5 || TEMP_C > 50)
        return CalCheckResultError;

    if (TEMP_C >= 5 && TEMP_C <= 10)
    {
        // interpolate the expected RH value at the given temperature
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:5 Y1:Salt_Base[0] X2:10 Y2:Salt_Base[1] Xi:TEMP_C];
        
        // interpolate the expected allowed RH tolerance at the given temperature
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:5 Y1:Salt_delta[0] X2:10 Y2:Salt_delta[1] Xi:TEMP_C];
    }
    else if (TEMP_C >= 10 && TEMP_C <= 15)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:10 Y1:Salt_Base[1] X2:15 Y2:Salt_Base[2] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:10 Y1:Salt_delta[1] X2:15 Y2:Salt_delta[2] Xi:TEMP_C];
    }
    else if (TEMP_C >= 15 && TEMP_C <= 20)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:15 Y1:Salt_Base[2] X2:20 Y2:Salt_Base[3] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:15 Y1:Salt_delta[2] X2:20 Y2:Salt_delta[3] Xi:TEMP_C];
    }
    else if (TEMP_C >= 20 && TEMP_C <= 25)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:20 Y1:Salt_Base[3] X2:25 Y2:Salt_Base[4] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:20 Y1:Salt_delta[3] X2:25 Y2:Salt_delta[4] Xi:TEMP_C];
    }
    else if (TEMP_C >= 25 && TEMP_C <= 30)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:25 Y1:Salt_Base[4] X2:30 Y2:Salt_Base[5] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:25 Y1:Salt_delta[4] X2:30 Y2:Salt_delta[5] Xi:TEMP_C];
    }
    else if (TEMP_C >= 30 && TEMP_C <= 35)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:30 Y1:Salt_Base[5] X2:35 Y2:Salt_Base[6] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:30 Y1:Salt_delta[5] X2:35 Y2:Salt_delta[6] Xi:TEMP_C];
    }
    else if (TEMP_C >= 35 && TEMP_C <= 40)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:35 Y1:Salt_Base[6] X2:40 Y2:Salt_Base[7] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:35 Y1:Salt_delta[6] X2:40 Y2:Salt_delta[7] Xi:TEMP_C];
    }
    else if (TEMP_C >= 40 && TEMP_C <= 45)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:40 Y1:Salt_Base[7] X2:45 Y2:Salt_Base[8] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:40 Y1:Salt_delta[7] X2:45 Y2:Salt_delta[8] Xi:TEMP_C];
    }
    else if (TEMP_C >= 45 && TEMP_C <= 50)
    {
        RH_interpolated = [OSSaltSolutionManager YInterpWithX1:45 Y1:Salt_Base[8] X2:50 Y2:Salt_Base[9] Xi:TEMP_C];
        Delta_interpolated = [OSSaltSolutionManager YInterpWithX1:45 Y1:Salt_delta[8] X2:50 Y2:Salt_delta[9] Xi:TEMP_C];
    }
    // Debug.Print "entered case statement"
    if (RH >= (RH_interpolated - Delta_interpolated) - 2 && RH <= (RH_interpolated + Delta_interpolated) + 2) // ADJUSTED VALID RH RANGE
        return CalCheckResultPass;
    else
        return CalCheckResultFail;
}

+ (NSString *)nameForSaltSolution:(NSString *)saltSolution
{
    if ([saltSolution caseInsensitiveCompare:kSaltSolutionNaBr] == NSOrderedSame)
        return kSaltSolutionNameNaBr;
    else if ([saltSolution caseInsensitiveCompare:kSaltSolutionNaCl] == NSOrderedSame)
        return kSaltSolutionNameNaCl;
    else if ([saltSolution caseInsensitiveCompare:kSaltSolutionKCl] == NSOrderedSame)
        return kSaltSolutionNameKCl;
    else if ([saltSolution caseInsensitiveCompare:kSaltSolutionInactive] == NSOrderedSame)
        return kSaltSolutionInactive;
    return @"";
}

+ (OSSaltSolutionManager *)sharedInstance
{
    if (_sharedSaltSolutionManager == nil)
        _sharedSaltSolutionManager = [[OSSaltSolutionManager alloc] init];
    return _sharedSaltSolutionManager;
}

- (id)init
{
    self = [super init];
    
    // init saltsolutions
    self.arraySalts = [[NSMutableArray alloc] init];
    [self.arraySalts addObject:[[OSSaltSolution alloc] initWithDesc:kSaltSolutionNameDefault salt_name:kSaltSolutionNone calculable:NO storable:NO]];
    [self.arraySalts addObject:[[OSSaltSolution alloc] initWithDesc:kSaltSolutionNameNaCl salt_name:kSaltSolutionNaCl calculable:YES storable:YES]];
    [self.arraySalts addObject:[[OSSaltSolution alloc] initWithDesc:kSaltSolutionNameNaBr salt_name:kSaltSolutionNaBr calculable:YES storable:YES]];
    [self.arraySalts addObject:[[OSSaltSolution alloc] initWithDesc:kSaltSolutionNameKCl salt_name:kSaltSolutionKCl calculable:YES storable:YES]];
    
    
    // init inactivesolution
    inactiveSolution = [[OSSaltSolution alloc] initWithDesc:kSaltSolutionNameKCl salt_name:kSaltSolutionKCl calculable:YES storable:YES];
    
    return self;
}

- (CalCheckResult)calCheckWithRh:(CGFloat)rh temp_f:(CGFloat)temp_f saltSolution:(OSSaltSolution *)saltSolution
{
    return [OSSaltSolutionManager CAL_CHECK_WITH_RH:rh TEMP_F:temp_f SALT:saltSolution.salt_name];
}

- (OSSaltSolution *)saltSolutionWithSolution:(NSString *)solution
{
    for (OSSaltSolution *saltSolution in self.arraySalts) {
        if ([saltSolution.salt_name caseInsensitiveCompare:solution] == NSOrderedSame)
            return saltSolution;
    }
    if ([solution caseInsensitiveCompare:kSaltSolutionInactive] == NSOrderedSame)
        return inactiveSolution;
    return nil;
}

- (OSSaltSolution *)defaultSolution
{
    return self.arraySalts[0];
}

- (OSSaltSolution *)inactiveSolution
{
    return inactiveSolution;
}

- (BOOL)isDefaultSolution:(NSString *)salt_name
{
    if (salt_name == nil)
        return NO;
    
    if ([salt_name caseInsensitiveCompare:[self defaultSolution].salt_name] == NSOrderedSame)
        return YES;
    return NO;
}

- (BOOL)isInactiveSolution:(NSString *)salt_name
{
    if (salt_name == nil)
        return NO;
    
    if ([salt_name caseInsensitiveCompare:[self inactiveSolution].salt_name] == NSOrderedSame)
        return YES;
    return NO;
}

@end
