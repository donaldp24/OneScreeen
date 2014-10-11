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

@end

@interface OSSensorCell : UITableViewCell

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic, retain) id<OSSensorCellDelegate> delegate;

@end
