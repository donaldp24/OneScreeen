//
//  ServerManager.m
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import "ServerManager.h"
#import "LROAuth2Client.h"
#import "ServerGateway.h"
//#import "DMSensor.h"
#import "SFHFKeychainUtils.h"
#import "SBJSON.h"

static NSString * const kServerURL = @"http://f2170reports.com";

static NSString * const kAccessTokenKey = @"access_token";

static NSString * const kOAuthClientID = @"mainapp";
static NSString * const kOAuthClientSecret = @"a5722d862fbb013facf471a4ff6f6893";
static NSString * const kOAuthClientAuthURL = @"http://auth-finished.invalid/";

static NSString * const kServiceNameForKeychain = @"DMIOS";

@interface ServerManager ()<LROAuth2ClientDelegate>

@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) LROAuth2Client *oauthClient;
@property (nonatomic, retain) UIWebView *loginWebView;

@end

@implementation ServerManager

-(void)oauthClientDidRefreshAccessToken:(LROAuth2Client *)client {}
-(void)oauthClientDidReceiveAccessToken:(LROAuth2Client *)client {}

@dynamic accessToken;

- (id)init {
    if (self = [super init]) {
        _oauthClient = [[LROAuth2Client alloc] initWithClientID:kOAuthClientID
                                                        secret:kOAuthClientSecret
                                                    redirectURL:[NSURL URLWithString:kOAuthClientAuthURL]];
        
        _oauthClient.userURL = [NSURL URLWithString:kServerURL];
        _oauthClient.tokenURL = [NSURL URLWithString:kServerURL];
        _oauthClient.delegate = self;
        
        _serverGateway = [[ServerGateway alloc] init];
        _serverGateway.delegate = self;
        
        [self logout];
    }
    
    return self;
}

- (void)getExpirationDateForSensor:(NSString *)sensorSerial {
    [self.serverGateway lookupSSN:sensorSerial accessToken:self.accessToken];
}
//
//- (void)getExpirationDatesForSensorArray:(NSArray *)sensorArray {
//    // should it be here?
//    if (![self isUserLoggedIn]) {
//        [self login];
//    }
//    
//    NSArray *sensors = [sensorArray copy];
//    
//    for (DMSensor *sensor in sensors) {
//        [self.serverGateway lookupSSN:sensor.serial accessToken:[self accessToken]];
//    }
//    
//    [sensors release];
//}

- (BOOL)login {
//    if (![self isUserLoggedIn]) {
//        //Load the OAuth authentication url to the webview.
//        self.loginWebView = [[self delegate] webviewToLoadOAuth];
//        
//        [[self delegate] serverManager:self
//                willLoadOAuthInWebView:self.loginWebView];
//        
//        [[self oauthClient] authorizeUsingWebView:self.loginWebView
//                             additionalParameters:nil];
//    }

    if (![self isUserLoggedIn]) {
        [[self serverGateway] loginWithUsername:self.username password:self.userpassword];
        return YES;
    }
    return NO;

}



- (void)logout {
    [self setAccessToken:nil];
}

- (BOOL)isUserLoggedIn {
    return ([self accessToken] != nil && [self accessToken].length > 0);
}

- (void)cancel {
    
}

- (void)uploadDataFileAtPath:(NSString *)path {
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    
    //if (!fileData) {
    //    if ([[self delegate] respondsToSelector:@selector(serverManagerUploadDidFailed:)] ){
    //        [[self delegate] serverManagerUploadDidFailed:self withError:nil];
    //    }
    //}
    
    [[self serverGateway] uploadDataFileContents:fileData atFilePath:path accessToken:self.accessToken];
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

- (NSString*)accessToken {
    return [SFHFKeychainUtils getPasswordForUsername:kAccessTokenKey
                                      andServiceName:kServiceNameForKeychain
                                               error:nil];
}

- (void)storeData:(NSDictionary *)data
{
    [self.serverGateway storeData:data accessToken:[self accessToken]];
}

- (void)retrieveData:(NSString *)ssn
{
    [self.serverGateway retrieveData:ssn first:NO accessToken:[self accessToken]];
}

- (void)retrieveFirstData:(NSString *)ssn
{
    [self.serverGateway retrieveData:ssn first:YES accessToken:[self accessToken]];
}

#pragma mark LROAuth2ClientDelegate methods

//This delegate function receives the access_token.
-(void)oauthClientDidExtractAccessToken:(NSString *)access_token
{
    [self setAccessToken:access_token];
    [[self delegate] serverManager:self
           didFinishOAuthInWebView:self.loginWebView];
}

#pragma mark -

-(void)serverGateway:(ServerGateway *)serverGateway
     didFinishLookup:(NSDictionary *)result
              forSSN:(NSString *)ssn
{
    NSLog(@"%@", result);
    
    id expirationDate = [result objectForKey:@"date"];

    if (expirationDate && !([expirationDate isKindOfClass:[NSNull class]])) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"YYYY-MM-dd"];
        NSDate * dte = [formatter dateFromString:expirationDate];

        [[self delegate] serverManager:self
              didReceiveExpirationDate:dte
                             forSensor:ssn];
    }
    else {
        if ([[self delegate] respondsToSelector:@selector(serverManager:didFailReceivingExpirationDateForSensor:)]) {
            [[self delegate] serverManager:self didFailReceivingExpirationDateForSensor:ssn];
        }
    }
}

- (void)serverGatewaydidFailLookup:(ServerGateway *)serverGateway {
    if ([[self delegate] respondsToSelector:@selector(serverManager:didFailReceivingExpirationDateForSensor:)]) {
        [[self delegate] serverManager:self didFailReceivingExpirationDateForSensor:nil];
    }
}

- (void)serverGateway:(ServerGateway *)serverGateway didFinishUploadingFile:(NSDictionary *)result {
    [[self delegate] serverManagerDidFinishUpload:self];
}

- (void)serverGatewaydidFailUpload:(ServerGateway *)serverGateway withError:(NSError *)error {
    switch ([error code]) {
        case GatewayErrorInvalidGrant:
            [self logout];
            break;
        default:
            break;
    }
    
    [[self delegate] serverManagerUploadDidFailed:self withError:error];
}

-(void) checkServerAvailability {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSURL *url = [NSURL URLWithString:@"http://dev.f2170reports.com/index.php?"];
    [request setURL:url];

    [request setHTTPMethod:@"GET"];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (!response) {
                                   NSLog(@"Server is unavailable");
                                   if ([[self delegate] respondsToSelector:@selector(serverManagerDidFailConnectingToServer:)]) {
                                       [[self delegate] serverManagerDidFailConnectingToServer:nil];
                                   }
                                   //failed
                                   return;
                               }
                               NSLog(@"Server is available");
                               if ([[self delegate] respondsToSelector:@selector(serverManagerDidSuccessfullyConnectToServer:)]) {
                                   [[self delegate] serverManagerDidSuccessfullyConnectToServer:nil];
                               }
                               //good
                           }];


}

-(void)serverGatewayDidExtractAccessToken:(NSString *)accessToken {

    [self setAccessToken:accessToken];
    [self.delegate serverManagerDidSuccessfullyLogin];
}

-(void)serverGatewayDidFailExtractAccessToken:(NSString *)accessToken {
    [self.delegate serverManagerDidFailLogin];
}

- (void)serverGatewayDidStore:(NSDictionary *)data withResponse:(NSDictionary *)response
{
    if (response == nil)
        [self.delegate serverManager:self didStoreData:data success:NO];
    else
    {
        NSNumber *success = response[kDataSuccessKey];
        if ([success boolValue])
            [self.delegate serverManager:self didStoreData:data success:YES];
        else
            [self.delegate serverManager:self didStoreData:data success:NO];
    }
}

- (void)serverGatewayDidRetrieve:(NSString *)ssn data:(NSDictionary *)data
{
    if (data == nil)
        [self.delegate serverManager:self didRetrieveData:ssn data:nil success:NO];
    else
    {
        NSNumber *success = data[kDataSuccessKey];
        if ([success boolValue])
            [self.delegate serverManager:self didRetrieveData:ssn data:data success:YES];
        else
            [self.delegate serverManager:self didRetrieveData:ssn data:data success:NO];
    }
}

- (void)serverGatewayDidRetrieveFirst:(NSString *)ssn data:(NSDictionary *)data
{
    if (data == nil)
        [self.delegate serverManager:self didRetrieveFirstData:ssn data:nil success:NO];
    else
    {
        NSNumber *success = data[kDataSuccessKey];
        if ([success boolValue])
            [self.delegate serverManager:self didRetrieveFirstData:ssn data:data success:YES];
        else
            [self.delegate serverManager:self didRetrieveFirstData:ssn data:data success:NO];
    }
}
@end
