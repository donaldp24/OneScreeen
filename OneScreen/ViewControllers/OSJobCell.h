//
//  OSJobCell.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/19/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDJob.h"

@class OSJobCell;

@protocol OSJobCellDelegate <NSObject>

- (void)didBeginEditingCell:(OSJobCell *)cell;
- (void)didEndEditingCell:(OSJobCell *)cell;
- (void)didDeleteCell:(OSJobCell *)cell;
- (void)didSelectCell:(OSJobCell *)cell isSelected:(BOOL)isSelected;
- (void)didStartEndJob:(OSJobCell *)cell;

- (BOOL)isStarted:(OSJobCell *)cell;
- (BOOL)isStartable:(OSJobCell *)cell;

@end

@interface OSJobCell : UITableViewCell

@property (nonatomic, retain) CDJob *job;
@property (nonatomic, retain) id<OSJobCellDelegate> delegate;

- (void)bind:(CDJob *)job isSelected:(BOOL)isSelected isNewOne:(BOOL)isNewOne;

- (void)endEditing;

@end
