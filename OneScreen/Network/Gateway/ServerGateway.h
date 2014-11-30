//
//  ServerGateway.h
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerGatewayDelegate.h"

@interface ServerGateway : NSObject

- (void)lookupSSN:(NSString*)ssn accessToken:(NSString*)access;
- (void)uploadDataFileContents:(NSData*)data atFilePath:(NSString*)filePath accessToken:(NSString*)accessToken;
- (void)loginWithUsername:(NSString *)username password: (NSString*)password;

@property (nonatomic, assign) id<ServerGatewayDelegate> delegate;

- (void)storeData:(NSDictionary *)data accessToken:(NSString*)access;
- (void)retrieveData:(NSString *)ssn first:(BOOL)first accessToken:(NSString*)access;

@end
