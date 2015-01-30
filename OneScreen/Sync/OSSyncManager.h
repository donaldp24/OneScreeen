//
//  OSSyncManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 1/28/15.
//  Copyright (c) 2015 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDCalCheck.h"

@interface OSSyncManager : NSObject

+ (OSSyncManager *)sharedInstance;


- (void)addCalcheckToSyncList:(CDCalCheck *)calCheck;


@end
