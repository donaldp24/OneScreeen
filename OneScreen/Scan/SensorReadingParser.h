//
//  SensorReadingParser.h
//  WagnerDMiOS
//
//  Created by Igor Ishchenko on 12/20/13.
//
//

#import <Foundation/Foundation.h>
#import "SensorData.h"

@interface SensorReadingParser : NSObject

- (SensorData *)parseData:(NSData*)manufactureData withOffset:(NSInteger)offset;

@end
