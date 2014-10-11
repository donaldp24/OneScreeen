//
//  OSSaltsCell.h
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSSaltSolution.h"

@class OSSaltsCell;

@protocol OSSaltsCellDelegate <NSObject>

@required
- (void)didCellTap:(OSSaltsCell *)cell;

@end

@interface OSSaltsCell : UITableViewCell

@property (nonatomic, retain) OSSaltSolution *saltSolution;
@property (nonatomic, retain) id<OSSaltsCellDelegate> delegate;

- (void)bind:(OSSaltSolution *)saltSolution;

@end
