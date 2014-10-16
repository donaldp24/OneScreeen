//
//  OSSensorCell.h
//  OneScreen
//
//  Created by Xiaoxue Han on 10/11/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDCalCheck.h"

@class OSSensorCell;

@protocol OSSensorCellDelegate <NSObject>

- (BOOL)retrievedData:(OSSensorCell *)cell;
- (void)didBeginEditingCell:(OSSensorCell *)cell;
- (void)didEndEditingCell:(OSSensorCell *)cell;
- (void)didShownName:(OSSensorCell *)cell;
- (void)didShownSerial:(OSSensorCell *)cell;
- (void)didDeleteCell:(OSSensorCell *)cell;
- (void)didSelectCell:(OSSensorCell *)cell isSelected:(BOOL)isSelected;

@end

@interface OSSensorCell : UITableViewCell

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic, retain) id<OSSensorCellDelegate> delegate;

- (void)bind:(NSString *)ssn isShownName:(BOOL)isShownName isSelected:(BOOL)isSelected;

- (void)showName;
- (void)showSensorSerial;
- (void)endEditing;

@end
