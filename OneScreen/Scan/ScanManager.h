//
//  ScanManager.h
//
//  Created by Igor Ishchenko on 12/20/13.
//  Copyright (c) 2013 Igor Ishchenko All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "ScanManagerDelegate.h"
#import "SensorReadingParser.h"
#import "EmulatorReadingParser.h"

@interface ScanManager : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, assign) id<ScanManagerDelegate> delegate;

- (id)initWithDelegate:(id<ScanManagerDelegate>)delegate;

- (void)startScan;
- (void)stopScan;
- (void)restartScan;

@end
