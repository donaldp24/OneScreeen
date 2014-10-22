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



@interface OSSensorCell () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *labelSsn;
@property (weak, nonatomic) IBOutlet UILabel *labelLastCalDate;
@property (weak, nonatomic) IBOutlet UILabel *labelSaltName;
@property (weak, nonatomic) IBOutlet UILabel *labelRh;
@property (weak, nonatomic) IBOutlet UILabel *labelTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelCalCertDue;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UITextField *tfSensorName;
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraintOfBtnDelete;
@property (weak, nonatomic) IBOutlet UIView *viewMain;
@property (weak, nonatomic) IBOutlet UIButton *btnSelect;

@property (retain, nonatomic) IBOutlet UISwipeGestureRecognizer *rightGesture;
@property (retain, nonatomic) IBOutlet UISwipeGestureRecognizer *leftGesture;

@property (retain, nonatomic) CDCalCheck *lastCalCheck;
@property (retain, nonatomic) CDCalCheck *oldestCalCheck;
@property (retain, nonatomic) CDCalibrationDate *cdCalibrationDate;
@property (retain, nonatomic) CDSensor *sensor;

@property (nonatomic) BOOL isShownName;


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

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        //
    }
    
    
    
    // create gestures
    self.leftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeLeft:)];
    self.leftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    self.leftGesture.delegate = self;
    [self addGestureRecognizer:self.leftGesture];
    
    self.rightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRight:)];
    self.rightGesture.direction = UISwipeGestureRecognizerDirectionRight;
    self.rightGesture.delegate = self;
    [self addGestureRecognizer:self.rightGesture];
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)bind:(NSString *)ssn isShownName:(BOOL)isShownName isSelected:(BOOL)isSelected
{
    _ssn = ssn;
    
    self.labelSsn.text = ssn;
    self.labelRh.text = @"";
    self.labelTemp.text = @"";
    self.labelLastCalDate.text = @"";
    self.labelCalCertDue.text = @"";
    self.labelSaltName.text = @"";
    
    //[self.labelSsn setFont:kFontBebasNeue(17)];
    [self.labelSsn setFont:kFontMyriadProRegular(17)];
    [self.labelLastCalDate setFont:kFontMyriadProRegular(17)];
    [self.labelCalCertDue setFont:kFontMyriadProRegular(17)];
    [self.labelRh setFont:kFontMyriadProRegular(17)];
    [self.labelTemp setFont:kFontMyriadProRegular(17)];
    [self.labelSaltName setFont:kFontMyriadProRegular(17)];
    
    CDCalCheck *calCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:ssn];
    CDCalCheck *oldestCalCheck = [[OSModelManager sharedInstance] getOldestCalCheckForSensor:ssn];
    CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:ssn];
    CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:ssn];
    
    self.lastCalCheck = calCheck;
    self.oldestCalCheck = oldestCalCheck;
    self.cdCalibrationDate = cdCalibrationDate;
    self.sensor = sensor;
    
    // show data
    if (calCheck)
    {
        self.labelRh.text = [NSString stringWithFormat:@"%.1f", [calCheck.rh floatValue]];
        self.labelTemp.text = [NSString stringWithFormat:@"%.1f", [calCheck.temp floatValue]];
        self.labelLastCalDate.text = [calCheck.date toStringWithFormat:kShortDateFormat];
        self.labelSaltName.text = calCheck.salt_name;
    }
    
    // calculate due date
    NSDate *calibrationDate = nil;
    if (cdCalibrationDate)
        calibrationDate = cdCalibrationDate.calibrationDate;
    NSDate *firstCalCheckDate = nil;
    if (oldestCalCheck)
        firstCalCheckDate = oldestCalCheck.date;
    
    
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
    
    // show name or sensor
    self.isShownName = isShownName;
    if (self.sensor == nil)
    {
        NSLog(@"error binding ssn to cell : sensor = nil with ssn : %@", ssn);
        [self showSensorSerial];
    }
    else
    {
        if (self.sensor.name != nil && self.sensor.name.length > 0)
        {
            [self showName];
        }
        else
        {
            [self showSensorSerial];
        }
    }
    
    // retrieve data from server
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
    
    // hide editing
    self.tfSensorName.hidden = YES;
    
    // decoration for editing text
    self.tfSensorName.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    self.tfSensorName.layer.borderWidth = 1;
    self.tfSensorName.textColor = kNameTextColor;
    
    // hide delete button
    self.leftConstraintOfBtnDelete.constant = -self.btnDelete.bounds.size.width;
    
    // select
    self.btnSelect.selected = isSelected;
    
    [self layoutIfNeeded];
}

- (IBAction)onEditSensor:(id)sender
{
    self.labelSsn.hidden = YES;
    self.tfSensorName.hidden = NO;
    self.tfSensorName.text = self.sensor.name;
    
    // show keyboard
    [self.tfSensorName becomeFirstResponder];
    
    if (self.delegate)
        [self.delegate didBeginEditingCell:self];
}

- (IBAction)onTapSensor:(id)sender
{
    if (self.sensor == nil)
        return;
    
    if (self.sensor.name == nil || self.sensor.name.length == 0)
    {
        // editing mode
        [self onEditSensor:sender];
        return;
    }
    
    if (self.isShownName)
        [self showSensorSerial];
    else
        [self showName];
}

- (void)showName
{
    self.labelSsn.text = self.sensor.name;
    self.labelSsn.textColor = kNameTextColor;
    self.isShownName = YES;
    
    if (self.delegate)
        [self.delegate didShownName:self];
}

- (void)showSensorSerial
{
    self.labelSsn.text = self.sensor.ssn;
    self.labelSsn.textColor = kSerialTextColor;
    self.isShownName = NO;
    
    if (self.delegate)
        [self.delegate didShownSerial:self];
}

- (void)endEditing
{
    if (![self.sensor.name isEqualToString:self.tfSensorName.text])
    {
        [[OSModelManager sharedInstance] setSensor:self.sensor name:self.tfSensorName.text];
    }
    
    self.tfSensorName.hidden = YES;
    self.labelSsn.hidden = NO;
    [self.tfSensorName resignFirstResponder];
    
    if (self.tfSensorName.text.length == 0)
    {
        [self showSensorSerial];
    }
    else
    {
        [self showName];
    }

    
    if (self.delegate)
        [self.delegate didEndEditingCell:self];
}

#pragma mark - gesture for delete
- (IBAction)onSwipeRight:(id)sender
{
    self.leftConstraintOfBtnDelete.constant = 0;
    [UIView animateWithDuration:kSwipeAnimateDuration animations:^() {
        [self layoutIfNeeded];
    }];
}

- (IBAction)onSwipeLeft:(id)sender
{
    self.leftConstraintOfBtnDelete.constant = -self.btnDelete.bounds.size.width;
    [UIView animateWithDuration:kSwipeAnimateDuration animations:^() {
        [self layoutIfNeeded];
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

#pragma mark - delete row
- (IBAction)onDelete:(id)sender
{
    if (self.delegate)
        [self.delegate didDeleteCell:self];
}

- (IBAction)onTapCheck:(id)sender
{
    self.btnSelect.selected = !self.btnSelect.selected;
    if (self.delegate)
        [self.delegate didSelectCell:self isSelected:self.btnSelect.selected];
}


@end
