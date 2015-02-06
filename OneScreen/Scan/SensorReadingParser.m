//
//  SensorReadingParser.m
//  WagnerDMiOS
//
//  Created by Igor Ishchenko on 12/20/13.
//
//

#import "SensorReadingParser.h"

static int const kRHValueOffset = 8;
static int const kTempValueOffset = 10;
static int const kRHAmbientValueOffset = 4;
static int const kTempAmbientValueOffset = 6;
static int const kBatteryLevelValueOffset = 24;
static int const kSerialNumberValueOffset = 12;

@interface SensorReadingParser ()

- (float)RHFromBytes:(const void*)bytes;
- (float)temperatureFromBytes:(const void*)bytes;
- (NSString*)serialNumberFromData:(NSData*)data withOffset:(NSInteger) offset;

@end

@implementation SensorReadingParser

- (SensorData *)parseData:(NSData *)manufactureData withOffset:(NSInteger)offset {

    int batteryLevelValueOffset = kBatteryLevelValueOffset + (int)offset;
    int rhValueOffset = kRHValueOffset + (int)offset;
    int rhAmbientValueOffset = kRHAmbientValueOffset + (int)offset;
    int tempValueOffset = kTempValueOffset + (int)offset;
    int tempAmbientValueOffset = kTempAmbientValueOffset + (int)offset;

    SensorData *sensorData = [[SensorData alloc] init];
    
    NSString* serialNumberString = [self serialNumberFromData:manufactureData withOffset:offset];
    //if (serialNumberString == nil || serialNumberString.length != 12)
    //    return nil;
    
    UInt8 batteryLevel = *(UInt8*)[[manufactureData subdataWithRange:NSMakeRange(batteryLevelValueOffset, 1)] bytes];
    
    float sensorRH = [self RHFromBytes:[[manufactureData subdataWithRange:NSMakeRange(rhValueOffset, 2)] bytes]];
    float ambientSensorRH = [self RHFromBytes:[[manufactureData subdataWithRange:NSMakeRange(rhAmbientValueOffset, 2)] bytes]];
    
    float sensorTemp = [self temperatureFromBytes:[[manufactureData subdataWithRange:NSMakeRange(tempValueOffset, 2)] bytes]];
    float ambientSensorTemp = [self temperatureFromBytes:[[manufactureData subdataWithRange:NSMakeRange(tempAmbientValueOffset, 2)] bytes]];
    
    sensorData.batteryLevel = batteryLevel;
    sensorData.rh = sensorRH;
    sensorData.ambientRh = ambientSensorRH;
    sensorData.temp = sensorTemp;
    sensorData.ambientTemp = ambientSensorTemp;
    sensorData.readingTimeStamp = [NSDate date];
    sensorData.ssn = [serialNumberString uppercaseString];
    
    return sensorData;
}

- (float)RHFromBytes:(const void *)bytes {
    // There is a problem with this method and the temperature method;
    // The value calculated should be to 0.1 precision, so the calculation and return value
    // should be a floating point (float) value, and when displayed on screen the
    // value should be something like 72.4, etc...
    // as it is, since you are casting to a UInt16 value, the "tenths" place gets rounded to nearest "ones" unit
    // with no 0.1 precision (i.e. precision = 0 in your case, but should equal 1
    float rh = *(UInt16*)bytes;
    // bytes need to be swapped
    if(CFByteOrderGetCurrent() == CFByteOrderLittleEndian) {
        rh = CFSwapInt16BigToHost(rh);
    }
    rh = (-6.0f + (125.0f * rh / 65536.0f));
    //  rh = (UInt16)roundf(-6.0f + (125.0f * (rh/256 + (rh & 0xff) * 256) / 65536.0f));
    
    //[12/19/14, 6:11:21 AM] Tim: // adjust caluclated RH value to support coinciding with Easy Reader readings.
    //[12/19/14, 6:12:14 AM] Tim: RH += 0.5; // adjust for all readings
    //[12/19/14, 6:13:03 AM] Tim: RH > 100? RH = 100, RH = RH;  // enforce 100 as max possible RH reading.
    rh += 0.5;
    if (rh > 100)
        rh = 100;
    
    return rh;
}

- (float)temperatureFromBytes:(const void *)bytes {
    float temperature = *(UInt16*)bytes;
    // bytes need to be swapped
    if(CFByteOrderGetCurrent() == CFByteOrderLittleEndian) {
        temperature = CFSwapInt16BigToHost(temperature);
    }
    temperature = (-46.85f + (175.72f * temperature / 65536.0f));  // celsius
    temperature = temperature * 1.8f + 32.0f;  // convert to fahrenheit
    return temperature;
}

- (NSString*)serialNumberFromData:(NSData*)data withOffset:(NSInteger) offset {

    int serialNumberValueOffset = kSerialNumberValueOffset + (int)offset;

    NSString *out2String = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(serialNumberValueOffset, 12)] encoding:NSASCIIStringEncoding];


    // return immutable string
    return out2String;
}

@end
