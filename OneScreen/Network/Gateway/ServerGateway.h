//
//  ServerGateway.h
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    GatewayErrorNoError,
    GatewayErrorInvalidGrant
} GatewayError;

@interface ServerGateway : NSObject

- (void)lookupSSN:(NSString*)ssn accessToken:(NSString*)access complete:(void(^)(NSDictionary *ret, NSString *ssn))block;

- (void)uploadDataFileContents:(NSData*)data atFilePath:(NSString*)filePath accessToken:(NSString*)accessToken complete:(void(^)(NSError *error))block;

- (void)loginWithUsername:(NSString *)username password: (NSString*)password complete:(void(^)(NSString *accessToken))block;

- (void)storeCalCheck:(NSString *)ssn rh:(int)rh temp:(int)temp salt_name:(NSString *)salt_name date:(NSString *)date accessToken:(NSString*)access complete:(void(^)(BOOL success))block;

- (void)retrieveCalCheck:(NSString *)ssn
                   first:(BOOL)first
             accessToken:(NSString*)access
                complete:(void(^)(NSDictionary *data))block;

@end
