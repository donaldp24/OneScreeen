//
//  OSReadingCell.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/18/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSReadingCell.h"
#import "OSModelManager.h"
#import "NSDate+String.h"

#define kBackgroundColorForSelected     [UIColor colorWithRed:1 green:1 blue:1 alpha:0.1]
#define kBackgroundColorForNonSelected  [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]

@interface OSReadingCell () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *labelSsn;
@property (weak, nonatomic) IBOutlet UILabel *labelLastCalDate;
@property (weak, nonatomic) IBOutlet UILabel *labelRh;
@property (weak, nonatomic) IBOutlet UILabel *labelTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelAmbRh;
@property (weak, nonatomic) IBOutlet UILabel *labelAmbTemp;

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

@implementation OSReadingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
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

- (void)bind:(CDReading *)reading isShownName:(BOOL)isShownName isSelected:(BOOL)isSelected
{
    _reading = reading;
    
    self.labelSsn.text = reading.ssn;
    self.labelLastCalDate.text = @"";
    self.labelRh.text = @"";
    self.labelTemp.text = @"";
    self.labelAmbRh.text = @"";
    self.labelAmbTemp.text = @"";
    
    //[self.labelSsn setFont:kFontBebasNeue(17)];
    [self.labelSsn setFont:kFontMyriadProRegular(17)];
    [self.labelLastCalDate setFont:kFontMyriadProRegular(17)];
    [self.labelRh setFont:kFontMyriadProRegular(17)];
    [self.labelTemp setFont:kFontMyriadProRegular(17)];
    [self.labelAmbRh setFont:kFontMyriadProRegular(17)];
    [self.labelAmbTemp setFont:kFontMyriadProRegular(17)];
    
    CDCalCheck *calCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:reading.ssn];
    CDCalCheck *oldestCalCheck = [[OSModelManager sharedInstance] getOldestCalCheckForSensor:reading.ssn];
    CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:reading.ssn];
    CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:reading.ssn];
    
    self.lastCalCheck = calCheck;
    self.oldestCalCheck = oldestCalCheck;
    self.cdCalibrationDate = cdCalibrationDate;
    self.sensor = sensor;
    
    // show data
    if (calCheck)
    {
        self.labelLastCalDate.text = [calCheck.date toStringWithFormat:kShortDateFormat];
    }
    else
    {
        // if there is no last cal date, show calibration date
        if (cdCalibrationDate != nil && cdCalibrationDate.calibrationDate != nil)
            self.labelLastCalDate.text = [cdCalibrationDate.calibrationDate toStringWithFormat:kShortDateFormat];
    }
    
    // values
    self.labelRh.text = [NSString stringWithFormat:kFormatForRh, [self.reading.rh floatValue]];
    self.labelTemp.text = [NSString stringWithFormat:kFormatForTemp, [self.reading.temp floatValue]];
    self.labelAmbRh.text = [NSString stringWithFormat:kFormatForAmbRh, [self.reading.ambRh floatValue]];
    self.labelAmbTemp.text = [NSString stringWithFormat:kFormatForAmbTemp, [self.reading.ambTemp floatValue]];
    
    // show name or sensor
    self.isShownName = isShownName;
    if (self.sensor == nil)
    {
        NSLog(@"error binding ssn to cell : sensor = nil with ssn : %@", reading.ssn);
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
    
    // hide delete button
    self.leftConstraintOfBtnDelete.constant = -self.btnDelete.bounds.size.width;
    
    // select
    self.btnSelect.selected = isSelected;
    if (isSelected)
        self.contentView.backgroundColor = kBackgroundColorForSelected;
    else
        self.contentView.backgroundColor = kBackgroundColorForNonSelected;
    
    [self layoutIfNeeded];

}

- (IBAction)onTapSensor:(id)sender
{
    if (self.sensor == nil)
        return;
    
    if (self.sensor.name == nil || self.sensor.name.length == 0)
    {
        return;
    }
    
    if (self.isShownName)
        [self showSensorSerial];
    else
        [self showName];
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
    if (self.btnSelect.selected)
        self.contentView.backgroundColor = kBackgroundColorForSelected;
    else
        self.contentView.backgroundColor = kBackgroundColorForNonSelected;
    if (self.delegate)
        [self.delegate didSelectCell:self isSelected:self.btnSelect.selected];
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


@end
