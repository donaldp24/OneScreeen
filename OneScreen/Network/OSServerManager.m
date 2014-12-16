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
        self.isLoggedIn = NO;
    }
    return self;
}

- (void)storeCalCheck:(NSDictionary *)calCheck
{
    [self.serverManager storeData:calCheck];
}

- (void)retrieveCalCheckForSensor:(NSString *)sensor first:(BOOL)first
{
    if (!first)
        [self.serverManager retrieveData:sensor];
    else
        [self.serverManager retrieveFirstData:sensor];
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
    self.isLoggedIn = NO;
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
            //[[NSNotificationCenter defaultCenter] postNotificationName:kCalibrationDateChanged object:sensorSerial];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:sensorSerial];
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
    self.isLoggedIn = YES;
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(didLogin:)])
        [self.delegate didLogin:YES];
}

-(void)serverManagerDidFailLogin
{
    NSLog(@"serverManagerDidFailLogin ---");

    self.isLoggingIn = NO;
    self.isLoggedIn = NO;

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
#if 1
        // save data
        NSString *ssn = [data objectForKey:kDataSensorSerialKey];
        CGFloat rh = [[data objectForKey:kDataRhKey] intValue] / 10.f;
        CGFloat temp = [[data objectForKey:kDataTempKey] intValue] / 10.f;
        NSString *salt_name = [data objectForKey:kDataSaltSolutionKey];
        NSDate *date = [NSDate dateWithString:[data objectForKey:kDataDateKey] withFormat:kUploadDataDateFormat];
        
        [self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name first:NO];
        
        // notification calcheck changed
        //[[NSNotificationCenter defaultCenter] postNotificationName:kFirstCalCheckChanged object:ssn];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kLastCalCheckChanged object:ssn];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:ssn];
#else

        // retrieve data
        [self.serverManager retrieveData:[data objectForKey:kDataSensorSerialKey]];
        
        // first data
        [self.serverManager retrieveFirstData:[data objectForKey:kDataSensorSerialKey]];
#endif
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
        
        [self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name first:NO];
        
        if (self.delegate)
            [self.delegate didRetrieveCalCheck:ssn success:YES first:NO];
        
        // notification calcheck changed
        //[[NSNotificationCenter defaultCenter] postNotificationName:kLastCalCheckChanged object:ssn];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kFirstCalCheckChanged object:ssn];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:ssn];
    }
    else
    {
        if (self.delegate)
            [self.delegate didRetrieveCalCheck:ssn success:NO first:NO];
    }
}

- (void)serverManager:(ServerManager *)serverManager didRetrieveFirstData:(NSString *)ssn data:(NSDictionary *)data success:(BOOL)success
{
    if (success)
    {
        // store data
        NSString *ssn = [data objectForKey:kDataSensorSerialKey];
        CGFloat rh = [[data objectForKey:kDataRhKey] intValue] / 10.f;
        CGFloat temp = [[data objectForKey:kDataTempKey] intValue] / 10.f;
        NSString *salt_name = [data objectForKey:kDataSaltSolutionKey];
        NSDate *date = [NSDate dateWithString:[data objectForKey:kDataDateKey] withFormat:kUploadDataDateFormat];
        
        [self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name first:YES];
        
        if (self.delegate)
            [self.delegate didRetrieveCalCheck:ssn success:YES first:YES];
        
        // notification calcheck changed
        //[[NSNotificationCenter defaultCenter] postNotificationName:kFirstCalCheckChanged object:ssn];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kLastCalCheckChanged object:ssn];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:ssn];
    }
    else
    {
        if (self.delegate)
            [self.delegate didRetrieveCalCheck:ssn success:NO first:YES];
    }
    
}

@end
