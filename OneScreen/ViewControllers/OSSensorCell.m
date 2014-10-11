//
//  OSSensorCell.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/11/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSSensorCell.h"
#import "OSModelManager.h"
#import "NSDate+String.h"
#import "OSCertificationManager.h"

#define kDefaultBackgroundColor     [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0]
#define kReadingBackgroundColor     [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]

#define kDefaultDueDateColor        [UIColor colorWithRed:0 green:255 blue:0 alpha:0.8]
#define kBeforeDueDateColor         [UIColor colorWithRed:1 green:1 blue:0 alpha:0.8]
#define kDuedDueDateColor           [UIColor colorWithRed:1 green:0 blue:0 alpha:0.8]


@interface OSSensorCell ()

@property (weak, nonatomic) IBOutlet UILabel *labelSsn;
@property (weak, nonatomic) IBOutlet UILabel *labelLastCalDate;
@property (weak, nonatomic) IBOutlet UILabel *labelSaltName;
@property (weak, nonatomic) IBOutlet UILabel *labelRh;
@property (weak, nonatomic) IBOutlet UILabel *labelTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelCalCertDue;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;


@end

@implementation OSSensorCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
    
    self.contentView.backgroundColor = kDefaultBackgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setSsn:(NSString *)ssn
{
    _ssn = ssn;
    
    self.labelSsn.text = ssn;
    self.labelRh.text = @"";
    self.labelTemp.text = @"";
    self.labelLastCalDate.text = @"";
    self.labelCalCertDue.text = @"";
    self.labelSaltName.text = @"";
    
    CDCalCheck *calCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:ssn];
    CDCalCheck *oldestCalCheck = [[OSModelManager sharedInstance] getOldestCalCheckForSensor:ssn];
    CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:ssn];
    NSDate *calibrationDate = nil;
    if (cdCalibrationDate)
        calibrationDate = cdCalibrationDate.calibrationDate;
    NSDate *firstCalCheckDate = nil;
    if (oldestCalCheck)
        firstCalCheckDate = oldestCalCheck.date;
    if (calCheck)
    {
        self.labelRh.text = [NSString stringWithFormat:@"%.1f", [calCheck.rh floatValue]];
        self.labelTemp.text = [NSString stringWithFormat:@"%.1f", [calCheck.temp floatValue]];
        self.labelLastCalDate.text = [calCheck.date toStringWithFormat:kShortDateFormat];
        self.labelSaltName.text = calCheck.salt_name;
    }
    
    NSDate *dueDate = [OSCertificationManager earlierRecertificationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
    
    if (dueDate != nil)
    {
        self.labelCalCertDue.text = [dueDate toStringWithFormat:kShortDateFormat];
    }
    
    if ([OSCertificationManager shouldRecertificationWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate])
    {
        self.labelCalCertDue.textColor = kDuedDueDateColor;
    }
    else if ([OSCertificationManager isInWarningPeriodWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate])
    {
        self.labelCalCertDue.textColor = kBeforeDueDateColor;
    }
    else
        self.labelCalCertDue.textColor = kDefaultDueDateColor;
    
    if (self.delegate)
    {
        if ([self.delegate retrievedData:self])
        {
            self.contentView.backgroundColor = kDefaultBackgroundColor;
            [self.indicator stopAnimating];
        }
        else
        {
            self.contentView.backgroundColor = kReadingBackgroundColor;
            [self.indicator startAnimating];
        }
    }
    else
    {
        self.contentView.backgroundColor = kDefaultBackgroundColor;
        [self.indicator stopAnimating];
    }
    
    [self layoutIfNeeded];
}

@end
