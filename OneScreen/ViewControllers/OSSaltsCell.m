//
//  OSSaltsCell.m
//  OneScreen
//
//  Created by Xiaoxue Han on 9/29/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSSaltsCell.h"

@interface OSSaltsCell ()

@property (nonatomic, weak) IBOutlet UILabel *labelName;

@end

@implementation OSSaltsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)bind:(OSSaltSolution *)saltSolution
{
    self.saltSolution = saltSolution;
    self.labelName.text = saltSolution.desc;
    
    [self layoutIfNeeded];
}

- (IBAction)onCell:(id)sender
{
    if (self.delegate)
        [self.delegate didCellTap:self];
}

@end
