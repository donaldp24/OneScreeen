//
//  OSServerManager.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/1/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSServerManager.h"

#import "OSModelManager.h"
#import "NSDate+String.h"
#import "Reachability.h"

#import "LROAuth2Client.h"
#import "SFHFKeychainUtils.h"
#import "SBJSON.h"
#import "ServerGateway.h"

static OSServerManager *_sharedOSServerManager = nil;

static NSString * const kServerURL = @"http://f2170reports.com";

static NSString * const kAccessTokenKey = @"access_token";

static NSString * const kOAuthClientID = @"mainapp";
static NSString * const kOAuthClientSecret = @"a5722d862fbb013facf471a4ff6f6893";
static NSString * const kOAuthClientAuthURL = @"http://auth-finished.invalid/";

static NSString * const kServiceNameForKeychain = @"DMIOS";



@interface OSServerManager ()<LROAuth2ClientDelegate>

@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) LROAuth2Client *oauthClient;

@property (nonatomic, retain) ServerGateway *serverGateway;
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

- (BOOL)hasConnectivity
{
    // test reachability
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    Reachability *reachability = [Reachability reachabilityWithAddress:&zeroAddress];
    if (reachability != nil)
    {
        if ([reachability isReachable])
            return YES;
        return NO;
    }
    return NO;
}


- (id)init
{
    self = [super init];
    if (self) {
        
        self.modelManager = [OSModelManager sharedInstance];
        
        self.isLoggingIn = NO;
        self.isLoggedIn = NO;
        
        _oauthClient = [[LROAuth2Client alloc] initWithClientID:kOAuthClientID
                                                         secret:kOAuthClientSecret
                                                    redirectURL:[NSURL URLWithString:kOAuthClientAuthURL]];
        
        _oauthClient.userURL = [NSURL URLWithString:kServerURL];
        _oauthClient.tokenURL = [NSURL URLWithString:kServerURL];
        _oauthClient.delegate = self;
        
        self.serverGateway = [[ServerGateway alloc] init];
        
        [self logout];
    }
    return self;
}

- (void)setAccessToken:(NSString *)accessToken {
    // if non-nil value was provided, save it in the KeyChain, otherwise delete existing record in the KeyChain
    if (accessToken) {
        [SFHFKeychainUtils storeUsername:kAccessTokenKey
                             andPassword:accessToken
                          forServiceName:kServiceNameForKeychain
                          updateExisting:YES
                                   error:nil];
    }
    else {
        [SFHFKeychainUtils deleteItemForUsername:kAccessTokenKey
                                  andServiceName:kServiceNameForKeychain
                                           error:nil];
    }
}

- (NSString *)accessToken {
    return [SFHFKeychainUtils getPasswordForUsername:kAccessTokenKey
                                      andServiceName:kServiceNameForKeychain
                                               error:nil];
}

#pragma mark LROAuth2ClientDelegate methods

//This delegate function receives the access_token.
-(void)oauthClientDidExtractAccessToken:(NSString *)access_token
{
    [self setAccessToken:access_token];
}

-(void)oauthClientDidRefreshAccessToken:(LROAuth2Client *)client {}
-(void)oauthClientDidReceiveAccessToken:(LROAuth2Client *)client {}

- (void)storeCalCheck:(NSString *)ssn
                   rh:(float)rh
                 temp:(float)temp
            salt_name:(NSString *)salt_name
                 date:(NSDate *)date
             complete:(void(^)(BOOL success, ErrorType errorType))block
{
    int int_rh = (int)(rh * 10);
    int int_temp = (int)(temp *10);
    NSString *strDate = [date toStringWithFormat:kUploadDataDateFormat];
    [self.serverGateway storeCalCheck:ssn
                                   rh:int_rh
                                 temp:int_temp
                            salt_name:salt_name
                                 date:strDate
                          accessToken:[self accessToken]
                             complete:block];

}

- (void)retrieveCalCheckForSensor:(NSString *)sensor
                            first:(BOOL)first
                         complete:(void (^)(BOOL, NSString *, float, float, NSString *, NSDate *, ErrorType))block
{
    [self.serverGateway retrieveCalCheck:sensor
                                   first:first
                             accessToken:[self accessToken]
                                complete:^(NSDictionary *data, ErrorType errorType) {
                                    if (data == nil ||
                                        ![data isKindOfClass:[NSDictionary class]]) {
                                        block(NO, sensor, 0.f, 0.f, nil, nil, errorType);
                                    }
                                    else {
                                        NSNumber *SUCCESS = [data objectForKey:@"success"];
                                        if (SUCCESS == nil) {
                                            block(NO, sensor, 0.f, 0.f, nil, nil, errorType);
                                        }
                                        else {
                                            bool success = [SUCCESS boolValue];
                                            if (success) {
                                                NSString *ssn = [data objectForKey:@"ssn"];
                                                NSNumber *RH = [data objectForKey:@"rh"];
                                                NSNumber *TEMP = [data objectForKey:@"temp"];
                                                NSString *salt_name = [data objectForKey:@"salt_name"];
                                                NSString *strDate = [data objectForKey:@"date"];
                                                
                                                
                                                
                                                float rh = [RH intValue] / 10.f;
                                                float temp = [TEMP intValue] / 10.f;
                                                NSDate *date = [NSDate dateWithString:strDate withFormat:kUploadDataDateFormat];
                                                
                                                // store cal check
                                                //[self.modelManager setCalCheckForSensor:ssn date:date rh:rh temp:temp salt_name:salt_name first:first stored_on_server:YES];
                                                
                                                // notification calcheck changed
                                                // [[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:ssn];
                                               
                                                block(YES, ssn, rh, temp, salt_name, date, errorType);
                                            }
                                        
                                            else {
                                                block(NO, sensor, 0.f, 0.f, nil, nil, errorType);
                                            }
                                        }
                                    }
                                }];
}

- (void)retrieveCalibrationDateForSensor:(NSString *)sensor
                                complete:(void (^)(BOOL, NSDate *, ErrorType))block
{
    [self.serverGateway lookupSSN:sensor
                      accessToken:self.accessToken
                         complete:^(NSDictionary *dic, NSString *ssn, ErrorType errorType) {
        if (dic == nil ||
            ![dic isKindOfClass:[NSDictionary class]])
        {
            block(NO, nil, errorType);
        }
        else
        {
            id expirationDate = [dic objectForKey:@"date"];
            if (expirationDate == nil)
            {
                block(NO, nil, errorType);
            }
            else
            {
                if (expirationDate && !([expirationDate isKindOfClass:[NSNull class]]))
                {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"YYYY-MM-dd"];
                    NSDate * dte = [formatter dateFromString:expirationDate];
                    
                    // store calibration date
                    [self.modelManager setCalibrationDate:dte sensorSerial:ssn];
                    
                    // notification calibration date changted
                    //[[NSNotificationCenter defaultCenter] postNotificationName:kDataChanged object:ssn];
                    
                    block(YES, dte, errorType);
                }
                else
                {
                    block(NO, nil, errorType);
                }
            }
        }
    }];
}

- (BOOL)loginWithUserName:(NSString *)userName
                 password:(NSString *)password
                 complete:(void (^)(BOOL))block

{
    if (self.isLoggingIn)
        return NO;
    
    self.isLoggingIn = YES;
    
    [self.serverGateway loginWithUsername:userName password:password
                                 complete:^(NSString *accessToken) {
                                     
                                     self.isLoggingIn = NO;
                                     
                                     if (accessToken != nil) {
                                         [self setAccessToken:accessToken];
                                         self.isLoggedIn = YES;
                                         block(YES);
                                     }
                                     else {
                                         [self setAccessToken:nil];
                                         self.isLoggedIn = NO;
                                         block(NO);
                                     }
                                 }];
    return YES;
}

- (void)logout
{
    [self setAccessToken:nil];
    self.isLoggedIn = NO;
}

@end
