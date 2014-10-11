//
//  OSServerManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/1/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSServerManager.h"

#import "ServerManager.h"
#import "OSModelManager.h"
#import "NSDate+String.h"

static OSServerManager *_sharedOSServerManager = nil;

@interface OSServerManager () <ServerManagerDelegate>

@property (nonatomic, retain) ServerManager *serverManager;
@property (nonatomic, retain) OSModelManager *modelManager;

@property (nonatomic) BOOL isLoggingIn;

@end

@implementation OSServerManager

+ (OSServerManager *)sharedInstance
{
    if (_sharedOSServerManager == nil)
        _sharedOSServerManager = [[OSServerManager alloc] init];
    return _sharedOSServerManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.serverManager = [[ServerManager alloc] init];
        self.serverManager.delegate = self;
        
        self.modelManager = [OSModelManager sharedInstance];
        
        self.isLoggingIn = NO;
    }
    return self;
}

- (void)storeCalCheck:(NSDictionary *)calCheck
{
    [self.serverManager storeData:calCheck];
}

- (void)retrieveCalCheckForSensor:(NSString *)sensor oldest:(BOOL)oldest
{
    if (!oldest)
        [self.serverManager retrieveData:sensor];
    else
        [self.serverManager retrieveOldestData:sensor];
}

- (void)retrieveCalibrationDateForSensor:(NSString *)sensor
{
    [self.serverManager getExpirationDateForSensor:sensor];
}

- (void)loginWithUserName:(NSString *)userName password:(NSString *)password
{
    if (self.serverManager.isUserLoggedIn)
        return;
    if (self.isLoggingIn)
        return;
    self.isLoggingIn = YES;
    
    self.serverManager.username = userName;
    self.serverManager.userpassword = password;
    
    [self.serverManager login];
}

- (void)logout
{
    [self.serverManager logout];
}

#pragma mark - server manager delegate
- (void)serverManager:(ServerManager *)serverManager didReceiveExpirationDate:(NSDate *)date forSensor:(NSString *)sensorSerial
{
    NSLog(@"didReceiveExpirationDate --- %@ : %@", date, sensorSerial);
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (date != nil)
        {
            // save it
            [self.modelManager setCalibrationDate:date sensorSerial:sensorSerial];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalibrationDate:success:)])
                [self.delegate didRetrieveCalibrationDate:sensorSerial success:YES];
            
            // notification it
            [[NSNotificationCenter defaultCenter] postNotificationName:kCalibrationDateChanged object:sensorSerial];
        }
        else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalibrationDate:success:)])
                [self.delegate didRetrieveCalibrationDate:sensorSerial success:NO];
        }
    });
}

- (void)serverManager:(ServerManager *)serverManager didFailReceivingExpirationDateForSensor:(NSString *)sensorSerial
{
    NSLog(@"didFailReceivingExpirationDateForSensor : %@", sensorSerial);
    if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalibrationDate:success:)])
        [self.delegate didRetrieveCalibrationDate:sensorSerial success:NO];
}

- (void)serverManagerDidFinishUpload:(ServerManager *)serverManager {
    //
}

- (void)serverManagerUploadDidFailed:(ServerManager *)serverManager withError:(NSError *)error {
    //
}

-(void)serverManagerDidFailConnectingToServer:(ServerManager *)serverManager {
    NSLog(@"serverManagerDidFailConnectingToServer ---");
}

-(void)serverManagerDidSuccessfullyConnectToServer:(ServerManager *)serverManager {
    // fetch expire dates
    NSLog(@"serverManagerDidSuccessfullyConnectToServer ---");
}

-(void)serverManagerDidSuccessfullyLogin
{
    NSLog(@"serverManagerDidSuccessfullyLogin ---");
    self.isLoggingIn = NO;
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(didLogin:)])
        [self.delegate didLogin:YES];
}

-(void)serverManagerDidFailLogin
{
    NSLog(@"serverManagerDidFailLogin ---");

    self.isLoggingIn = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(didLogin:)])
        [self.delegate didLogin:NO];
}

- (void)serverManager:(ServerManager *)serverManager willLoadOAuthInWebView:(UIWebView *)webView
{
    //
}

- (void)serverManager:(ServerManager *)serverManager didFinishOAuthInWebView:(UIWebView *)webView
{
    //
}

- (UIWebView *)webviewToLoadOAuth
{
    return nil;
}

- (void)serverManager:(ServerManager *)serverManager didStoreData:(NSDictionary *)data success:(BOOL)success
{
    NSString *ssn = [data objectForKey:kDataSensorSerialKey];
    if (success)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didStoreCalCheck:success:)])
            [self.delegate didStoreCalCheck:ssn success:YES];
#if 0
        // save data
        NSString *ssn = [data objectForKey:kDataSensorSerialKey];
        CGFloat rh = [[data objectForKey:kDataRhKey] intValue] / 10.f;
        CGFloat temp = [[data objectForKey:kDataTempKey] intValue] / 10.f;
        NSString *salt_name = [data objectForKey:kDataSaltSolutionKey];
        NSDate *date = [NSDate dateWithString:[data objectForKey:kDataDateKey] withFormat:kUploadDataDateFormat];
        
        [self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name oldest:NO];
        
        // notification it
        [[NSNotificationCenter defaultCenter] postNotificationName:kLastCalCheckChanged object:nil];
#endif
        // retrieve data
        [self.serverManager retrieveData:[data objectForKey:kDataSensorSerialKey]];
        
        // oldest data
        [self.serverManager retrieveOldestData:[data objectForKey:kDataSensorSerialKey]];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didStoreCalCheck:success:)])
            [self.delegate didStoreCalCheck:ssn success:NO];
    }
}

- (void)serverManager:(ServerManager *)serverManager didRetrieveData:(NSString *)ssn data:(NSDictionary *)data success:(BOOL)success
{
    if (success)
    {
        // save data
        NSString *ssn = [data objectForKey:kDataSensorSerialKey];
        CGFloat rh = [[data objectForKey:kDataRhKey] intValue] / 10.f;
        CGFloat temp = [[data objectForKey:kDataTempKey] intValue] / 10.f;
        NSString *salt_name = [data objectForKey:kDataSaltSolutionKey];
        NSDate *date = [NSDate dateWithString:[data objectForKey:kDataDateKey] withFormat:kUploadDataDateFormat];
        
        [self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name oldest:NO];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalCheck:success:oldest:)])
            [self.delegate didRetrieveCalCheck:ssn success:YES oldest:NO];
        
        // notification calcheck changed
        [[NSNotificationCenter defaultCenter] postNotificationName:kLastCalCheckChanged object:ssn];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalCheck:success:oldest:)])
            [self.delegate didRetrieveCalCheck:ssn success:NO oldest:NO];
    }
}

- (void)serverManager:(ServerManager *)serverManager didRetrieveOldestData:(NSString *)ssn data:(NSDictionary *)data success:(BOOL)success
{
    if (success)
    {
        // store data
        NSString *ssn = [data objectForKey:kDataSensorSerialKey];
        CGFloat rh = [[data objectForKey:kDataRhKey] intValue] / 10.f;
        CGFloat temp = [[data objectForKey:kDataTempKey] intValue] / 10.f;
        NSString *salt_name = [data objectForKey:kDataSaltSolutionKey];
        NSDate *date = [NSDate dateWithString:[data objectForKey:kDataDateKey] withFormat:kUploadDataDateFormat];
        
        [self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name oldest:YES];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalCheck:success:oldest:)])
            [self.delegate didRetrieveCalCheck:ssn success:YES oldest:YES];
        
        // notification calcheck changed
        [[NSNotificationCenter defaultCenter] postNotificationName:kOldestCalCheckChanged object:ssn];
    }
    else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didRetrieveCalCheck:success:oldest:)])
            [self.delegate didRetrieveCalCheck:ssn success:NO oldest:YES];
    }
    
}

@end
