//
//  ScanManagerDelegate.h
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SensorData.h"

@class ScanManager;

@protocol ScanManagerDelegate <NSObject>

@required
- (void)scanManager:(ScanManager*)scanManager didFindSensor:(SensorData *)sensorData;
- (void)scanManager:(ScanManager*)scanManager didFindElseDevice:(id)sender;

@optional
- (void)scanManagerDidStartScanning:(ScanManager*)scanManager;

@end
