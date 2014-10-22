//
//  OSJobCell.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/19/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSJobCell.h"
#import "NSDate+String.h"
#import "OSModelManager.h"

@interface OSJobCell ()

@property (weak, nonatomic) IBOutlet UILabel *labelJobName;
@property (weak, nonatomic) IBOutlet UILabel *labelStartDate;
@property (weak, nonatomic) IBOutlet UILabel *labelEndDate;

@property (weak, nonatomic) IBOutlet UITextField *tfJobName;

@property (weak, nonatomic) IBOutlet UIButton *btnDelete;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraintOfBtnDelete;
@property (weak, nonatomic) IBOutlet UIView *viewMain;
@property (weak, nonatomic) IBOutlet UIButton *btnSelect;

@property (weak, nonatomic) IBOutlet UIButton *btnStartEndJob;

@property (retain, nonatomic) UISwipeGestureRecognizer *rightGesture;
@property (retain, nonatomic) UISwipeGestureRecognizer *leftGesture;

@property (nonatomic) BOOL isNewOne;


@end

@implementation OSJobCell

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

- (void)bind:(CDJob *)job isSelected:(BOOL)isSelected isNewOne:(BOOL)isNewOne
{
    _job = job;
    
    [self.labelJobName setFont:kFontMyriadProRegular(17)];
    [self.labelStartDate setFont:kFontMyriadProRegular(17)];
    [self.labelEndDate setFont:kFontMyriadProRegular(17)];
    
    // job name
    self.labelJobName.text = job.name;
    
    // start date
    if (job.starttime != nil)
        self.labelStartDate.text = [job.starttime toStringWithFormat:kShortDateFormat];
    else
        self.labelStartDate.text = @"";
    
    // end date
    if (job.endtime != nil)
        self.labelEndDate.text = [job.endtime toStringWithFormat:kShortDateFormat];
    else
        self.labelEndDate.text = @"";
    
    
    // hide editing
    self.tfJobName.hidden = YES;
    
    // decoration for editing text
    self.tfJobName.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    self.tfJobName.layer.borderWidth = 1;
    self.tfJobName.textColor = kNameTextColor;
    
    // hide delete button
    self.leftConstraintOfBtnDelete.constant = -self.btnDelete.bounds.size.width;
    
    // select
    self.btnSelect.selected = isSelected;
    
    self.isNewOne = isNewOne;
    
    // start / end job
    if (self.delegate)
    {
        if ([self.delegate isStarted:self])
        {
            [self.btnStartEndJob setTitle:@"End Job" forState:UIControlStateNormal];
            [self.btnStartEndJob setEnabled:YES];
            
            self.btnSelect.selected = NO;
            [self.delegate didSelectCell:self isSelected:NO];
            
            [self.btnSelect setEnabled:NO];
            [self.btnSelect setHidden:YES];
        }
        else
        {
            [self.btnStartEndJob setTitle:@"Start Job" forState:UIControlStateNormal];
            if ([self.delegate isStartable:self])
                [self.btnStartEndJob setEnabled:YES];
            else
                [self.btnStartEndJob setEnabled:NO];
            
            [self.btnSelect setEnabled:YES];
            [self.btnSelect setHidden:NO];
        }
    }
    
    if (self.isNewOne)
    {
        [self onEditJobName:nil];
    }
    
    [self layoutIfNeeded];
}

- (IBAction)onEditJobName:(id)sender
{
    self.labelJobName.hidden = YES;
    self.tfJobName.hidden = NO;
    self.tfJobName.text = self.job.name;
    
    // show keyboard
    [self.tfJobName becomeFirstResponder];
    
    if (self.delegate)
        [self.delegate didBeginEditingCell:self];
}


- (void)endEditing
{
    if (self.delegate)
        [self.delegate didEndEditingCell:self];
    
    if (self.tfJobName.text.length > 0)
    {
        if (![self.job.name isEqualToString:self.tfJobName.text])
        {
            [[OSModelManager sharedInstance] setNameForJob:self.job jobName:self.tfJobName.text];
        }
    }
    else
    {
        // remove this cell if new one
    }
    
    self.tfJobName.hidden = YES;
    self.labelJobName.hidden = NO;
    [self.tfJobName resignFirstResponder];
    
    self.labelJobName.text = self.tfJobName.text;
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

- (IBAction)onStartEndJob:(id)sender
{
    if (self.delegate)
        [self.delegate didStartEndJob:self];
}


@end
