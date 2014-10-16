//
//  OSReportManager.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/16/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OSReportManagerDelegate <NSObject>

@required
- (void)didFinishGeneratingReport;

@end

@interface OSReportManager : NSObject

@property (nonatomic, retain) id<OSReportManagerDelegate> delegate;

+ (OSReportManager *)sharedInstance;

- (NSString *)createPdfForSensors:(NSArray *)arraySsn;

@end
