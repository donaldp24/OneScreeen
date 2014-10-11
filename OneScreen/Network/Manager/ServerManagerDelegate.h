//
//  ServerManagerDelegate.h
//  WagnerDMiOS
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Mobiona Software Solutions Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ServerManager;

@protocol ServerManagerDelegate <NSObject>

- (UIWebView*)webviewToLoadOAuth;
- (void)serverManager:(ServerManager*)serverManager willLoadOAuthInWebView:(UIWebView*)webView;
- (void)serverManager:(ServerManager *)serverManager didFinishOAuthInWebView:(UIWebView *)webView;

- (void)serverManager:(ServerManager *)serverManager
    didReceiveExpirationDate:(NSDate*)date
    forSensor:(NSString*)sensorSerial;

- (void)serverManager:(ServerManager *)serverManager didFailReceivingExpirationDateForSensor:(NSString *)sensorSerial;

- (void)serverManagerDidFailConnectingToServer:(ServerManager *)serverManager;
- (void)serverManagerDidSuccessfullyConnectToServer:(ServerManager *)serverManager;

- (void)serverManagerDidFinishUpload:(ServerManager *)serverManager;
- (void)serverManagerUploadDidFailed:(ServerManager *)serverManager withError:(NSError*)error;
-(void)serverManagerDidSuccessfullyLogin;
-(void)serverManagerDidFailLogin;

- (void)serverManager:(ServerManager *)serverManager didStoreData:(NSDictionary *)data success:(BOOL)success;
- (void)serverManager:(ServerManager *)serverManager didRetrieveData:(NSString *)ssn data:(NSDictionary *)data success:(BOOL)success;
- (void)serverManager:(ServerManager *)serverManager didRetrieveOldestData:(NSString *)ssn data:(NSDictionary *)data success:(BOOL)success;

@end
