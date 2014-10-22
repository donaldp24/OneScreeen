//
//  OSReadingCell.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/18/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDReading.h"

@class OSReadingCell;

@protocol OSReadingCellDelegate <NSObject>

- (void)didShownName:(OSReadingCell *)cell;
- (void)didShownSerial:(OSReadingCell *)cell;
- (void)didDeleteCell:(OSReadingCell *)cell;
- (void)didSelectCell:(OSReadingCell *)cell isSelected:(BOOL)isSelected;

@end

@interface OSReadingCell : UITableViewCell

@property (nonatomic, retain) CDReading *reading;
@property (nonatomic, retain) id<OSReadingCellDelegate> delegate;

- (void)bind:(CDReading *)reading isShownName:(BOOL)isShownName isSelected:(BOOL)isSelected;

- (void)showName;
- (void)showSensorSerial;

@end
