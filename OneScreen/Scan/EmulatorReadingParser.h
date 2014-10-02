//
//  SensorReadingParser.h
//  WagnerDMiOS
//
//  Created by Igor Ishchenko on 12/20/13.
//
//

#import <Foundation/Foundation.h>

//extern NSString * const kSensorDataBatteryKey;
//extern NSString * const kSensorDataRHKey;
//extern NSString * const kSensorDataRHAmbientKey;
//extern NSString * const kSensorDataTemperatureKey;
//extern NSString * const kSensorDataTemperatureAmbientKey;
//extern NSString * const kSensorDataReadingTimestampKey;
//extern NSString * const kSensorDataSerialNumberKey;

@interface EmulatorReadingParser : NSObject

- (NSDictionary*)parseData:(NSData*)manufactureData withOffset:(NSInteger)offset;

@end
