//
//  SensorReadingParser.m
//  WagnerDMiOS
//
//  Created by Igor Ishchenko on 12/20/13.
//
//

#import "EmulatorReadingParser.h"
#import "SensorReadingParser.h"

static int const kRHValueOffset = 4;
static int const kTempValueOffset = 6;
static int const kRHAmbientValueOffset = 8;
static int const kTempAmbientValueOffset = 10;
static int const kBatteryLevelValueOffset = 18;
static int const kSerialNumberValueOffset = 12;

@interface EmulatorReadingParser ()

- (float)RHFromBytes:(const void*)bytes;
- (float)temperatureFromBytes:(const void*)bytes;
- (NSString*)serialNumberFromData:(NSData*)data withOffset:(NSInteger) offset;

@end

@implementation EmulatorReadingParser

- (NSDictionary*)parseData:(NSData *)manufactureData withOffset:(NSInteger)offset {

    int batteryLevelValueOffset = kBatteryLevelValueOffset + offset;
    int rhValueOffset = kRHValueOffset + offset;
    int rhAmbientValueOffset = kRHAmbientValueOffset + offset;
    int tempValueOffset = kTempValueOffset + offset;
    int tempAmbientValueOffset = kTempAmbientValueOffset + offset;

    NSMutableDictionary *sensorData = [NSMutableDictionary dictionary];
    
    NSString* serialNumberString = [self serialNumberFromData:manufactureData withOffset:offset];
    
    UInt8 batteryLevel = *(UInt8*)[[manufactureData subdataWithRange:NSMakeRange(batteryLevelValueOffset, 1)] bytes];
    
    float sensorRH = [self RHFromBytes:[[manufactureData subdataWithRange:NSMakeRange(rhValueOffset, 2)] bytes]];
    float ambientSensorRH = [self RHFromBytes:[[manufactureData subdataWithRange:NSMakeRange(rhAmbientValueOffset, 2)] bytes]];
    
    float sensorTemp = [self temperatureFromBytes:[[manufactureData subdataWithRange:NSMakeRange(tempValueOffset, 2)] bytes]];
    float ambientSensorTemp = [self temperatureFromBytes:[[manufactureData subdataWithRange:NSMakeRange(tempAmbientValueOffset, 2)] bytes]];
 
    NSDateFormatter * dFormatter = [[NSDateFormatter alloc] init];
    [dFormatter setDateFormat:@"yyyy-mm-dd-HH-MM"];
    NSString * readingTimeStamp = [dFormatter stringFromDate:[NSDate date]];
    
    [sensorData setObject:@(batteryLevel) forKey:kSensorDataBatteryKey];
    [sensorData setObject:@(sensorRH) forKey:kSensorDataRHKey];
    [sensorData setObject:@(ambientSensorRH) forKey:kSensorDataRHAmbientKey];
    [sensorData setObject:@(sensorTemp) forKey:kSensorDataTemperatureKey];
    [sensorData setObject:@(ambientSensorTemp) forKey:kSensorDataTemperatureAmbientKey];
    [sensorData setObject:readingTimeStamp forKey:kSensorDataReadingTimestampKey];
    [sensorData setObject:[serialNumberString uppercaseString] forKey:kSensorDataSerialNumberKey];
    
    // return immutable dictionary
    return [NSDictionary dictionaryWithDictionary:sensorData];
}

- (float)RHFromBytes:(const void *)bytes {
    float rh = *(UInt16*)bytes;
    
    int measurement = (int)((rh + 6.0) / 125.0 * 65536.0);
    int b1 = measurement & 0xFF;
    int b2 = measurement & 0xFF00;
    
    rh = (-6.0f + (125.0f * (b1 + b2)/65536.0f));
    return rh;
}


- (float)temperatureFromBytes:(const void *)bytes {

    float temperature = *(UInt16*)bytes;
    
    int measurement = (int)((((temperature*1.0-32.f)/1.8f)+46.85f)/175.72f*65536.f);
    int b1 = measurement & 0xFF;
    int b2 = measurement & 0xFF00;
    
    temperature = roundf((-46.85f + (175.72f * (b1 + b2)/65536.0f))*1.8f+32.0f);
    return temperature;
}

- (NSString*)serialNumberFromData:(NSData*)data withOffset:(NSInteger) offset {

    NSMutableString* serialNumberString = [NSMutableString string];

    int serialNumberValueOffset = kSerialNumberValueOffset + offset;

    for(int i=0;i<3;++i)
    {
        UInt16 temp;
        [data getBytes:&temp range:NSMakeRange((i*2)+serialNumberValueOffset, 2)];
        [serialNumberString appendString:[NSString stringWithFormat:@"%04X",temp]];
    }
    // return immutable string
    return [NSString stringWithString:serialNumberString];
}

@end
