//
//  SensorReadingParser.h
//  WagnerDMiOS
//
//  Created by Igor Ishchenko on 12/20/13.
//
//

#import <Foundation/Foundation.h>

@interface SensorReadingParser : NSObject

- (NSDictionary*)parseData:(NSData*)manufactureData withOffset:(NSInteger)offset;

@end
