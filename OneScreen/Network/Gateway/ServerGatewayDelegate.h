//
//  ServerGatewayDelegate.h
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    GatewayErrorNoError,
    GatewayErrorInvalidGrant
} GatewayError;

@class ServerGateway;

@protocol ServerGatewayDelegate <NSObject>

- (void)serverGateway:(ServerGateway*)serverGateway didFinishLookup:(NSDictionary*)result forSSN:(NSString*)ssn;
- (void)serverGatewaydidFailLookup:(ServerGateway *)serverGateway;

- (void)serverGateway:(ServerGateway *)serverGateway didFinishUploadingFile:(NSDictionary *)result;
- (void)serverGatewaydidFailUpload:(ServerGateway *)serverGateway withError:(NSError*)error;
-(void)serverGatewayDidExtractAccessToken:(NSString *)accessToken;
-(void)serverGatewayDidFailExtractAccessToken:(NSString *)accessToken;

- (void)serverGatewayDidStore:(NSDictionary *)data withResponse:(NSDictionary *)response;
- (void)serverGatewayDidRetrieve:(NSString *)ssn data:(NSDictionary *)data;
- (void)serverGatewayDidRetrieveFirst:(NSString *)ssn data:(NSDictionary *)data;
@end
