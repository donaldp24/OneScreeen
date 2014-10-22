//
//  OSAppContext.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/17/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDJob.h"

@interface OSAppContext : NSObject

+ (OSAppContext *)sharedInstance;

@property (nonatomic, retain) CDJob *currentJob;
@property (nonatomic) BOOL isJobStarted;

@end
