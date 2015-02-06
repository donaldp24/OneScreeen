//
//  OSViewController.m
//  OneScreen
//
//  Created by Xiaoxue Han on 9/25/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSViewController.h"
#import "ScanManagerDelegate.h"
#import "ScanManager.h"
#import "OSServerManager.h"
#import "NSDate+String.h"
#import "OSSaltsCell.h"
#import "OSSaltSolutionManager.h"
#import "iToast.h"
#import "OSSensorInventoryTableViewController.h"
#import "UIManager.h"
#import "OSExpirationManager.h"
#import "OSCertificationManager.h"
#import "OSModelManager.h"
#import "OSAppContext.h"
#import "OSSyncManager.h"
#import "SensorInfo.h"
#import "OSCalCheckManager.h"

const int scanDelay = 5;

#define USE_JOBEDITOR_IN_MAIN_SCREEN    0

#define STORE_DUMMY_CAL_CHECK_ON_SERVER 0

#define kRhFontSize             60
#define kTempFontSize           42
#define kAmbientRhFontSize      20
#define kAmbientTempFontSize    20
#define kSensorSerialFontSize   13
#define kDatesFontSize          13

#define kDropdownAnimateDuration    (0.2f)
#define kSaltCellHeight             (44.0f)

#define kLastViewFoldWidth      (40.f)
#define kLastViewFoldAlpha      (0.3f)
#define kLastViewUnfoldAlpha    (1.0f)
#define kLastViewRightMargin    (10.f)

#define kLabelWarningAnimateDuration    (0.5f)

#define kViewJobDownAnimateDuration     (0.25)
#define kViewJobChangeModeAnimateDuration   (0.25)

#define kTopConstantOfCurrentJobNormal  (0)
#define kTopConstantOfCurrentJobEditing (-15)

#define kTopConstantOfNewJobNormal  (30)
#define kTopConstantOfNewJobEditing (15)

#define EVENT_RETRIEVED_DATA_FAILED  @"retrieved data failed"

static OSViewController *_sharedOSViewController = nil;

typedef enum {
    OSJobEditingStatusNormal,
    OSJobEditingStatusCurrJobEditing,
    OSJobEditingStatusNewJobEditing,
    OSJobEditingStatusNewJobCreated
} OSJobEditingStatus;


@interface OSViewController () <ScanManagerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, OSSaltsCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

{
    NSTimeInterval prevTakenTime;
    UIImage *imageBluetooth;
    UIImage *imageBluetooth_blue;
    NSTimeInterval prevLoginTryTime;
    NSTimer *timer;
    UIResponder *currentResponder;
    
    UIImage *imageDownArrow;
    UIImage *imageDownArrowWhite;
    CDJob *newJob;
}

@property (weak, nonatomic) IBOutlet UILabel *labelCurrentJobTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelCurrentJob;

@property (weak, nonatomic) IBOutlet UIImageView *ivBluetoothIcon;

@property (weak, nonatomic) IBOutlet UILabel *labelRh;
@property (weak, nonatomic) IBOutlet UILabel *labelTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelAmbientRh;
@property (weak, nonatomic) IBOutlet UILabel *labelAmbientTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelSensorSerial;
@property (weak, nonatomic) IBOutlet UILabel *labelExpireDate;
@property (weak, nonatomic) IBOutlet UILabel *labelCalibrationDate;

// dropbdown
@property (weak, nonatomic) IBOutlet UIButton *btnSalts;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraintOfDropdown;

@property (weak, nonatomic) IBOutlet UIImageView *ivProgress;
@property (weak, nonatomic) IBOutlet UIImageView *ivBattery;
@property (nonatomic, retain) UIImage *imgProgress;
@property (nonatomic) CGFloat fWidthOfProgress;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraintOfProgress;

@property (weak, nonatomic) IBOutlet UIButton *btnStore;
// cal-check
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *panGesture;
@property (weak, nonatomic) IBOutlet UILabel *labelLastCalCheck;
@property (weak, nonatomic) IBOutlet UILabel *labelLastSaltSolution;
@property (weak, nonatomic) IBOutlet UILabel *labelLastRH;
@property (weak, nonatomic) IBOutlet UILabel *labelLastTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelLastResult;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraintOfViewLast;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraintOfViewLast;
@property (weak, nonatomic) IBOutlet UIView *viewLast;
@property (weak, nonatomic) IBOutlet UILabel *labelForResult;
@property (weak, nonatomic) IBOutlet UILabel *labelResult;

// swipe left
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *leftGesture;

// warning label
@property (weak, nonatomic) IBOutlet UILabel *labelWarning;

// swipe down
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *downGesture;

// swipe up
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *upGesture;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraintOfViewJob;
@property (weak, nonatomic) IBOutlet UIView *viewJob;

@property (weak, nonatomic) IBOutlet UILabel *labelForJobName;
@property (weak, nonatomic) IBOutlet UITextField *tfJobName;
@property (weak, nonatomic) IBOutlet UILabel *labelJobName;
@property (weak, nonatomic) IBOutlet UIButton *btnEditJob;
@property (weak, nonatomic) IBOutlet UIButton *btnPlusNewJob;
@property (weak, nonatomic) IBOutlet UILabel *labelForNewJobName;
@property (weak, nonatomic) IBOutlet UITextField *tfNewJobName;
@property (weak, nonatomic) IBOutlet UIButton *btnCancelNewJob;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraintOfCurrentJob;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraintOfNewJob;

@property (weak, nonatomic) IBOutlet UIButton *btnStartEndJob;

@property (weak, nonatomic) IBOutlet UIButton *btnUpDownArrowForViewJob;
@property (nonatomic) OSJobEditingStatus statusJobEditing;
//////////////////////

@property (retain, nonatomic) ScanManager *scanManager;
@property (nonatomic, retain) OSServerManager *serverManager;
@property (nonatomic, retain) OSSyncManager *syncManager;

@property (nonatomic, retain) UIAlertView *alertForFaildMessage;

@end

@implementation OSViewController

+ (OSViewController *)sharedInstance
{
    return _sharedOSViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // start scan
    self.scanManager = [[ScanManager alloc] initWithDelegate:self];
    //[self.scanManager startScan];
    
    self.serverManager = [OSServerManager sharedInstance];
    [self.serverManager loginWithUserName:kGlobalUserName password:kGlobalUserPass complete:^(BOOL success) {
        if (success)
            [self showToastMessage:@"Logged in"];
        else
            [self showToastMessage:@"Login failed"];
    }];
    
    // sync manager
    self.syncManager = [OSSyncManager sharedInstance];
        
    // initialize fonts
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        [self.labelRh setFont:kFontBebasNeue(kRhFontSize - 10)];
        [self.labelTemp setFont:kFontBebasNeue(kTempFontSize - 10)];
    }
    else {
        [self.labelRh setFont:kFontBebasNeue(kRhFontSize)];
        [self.labelTemp setFont:kFontBebasNeue(kTempFontSize)];
    }
    [self.labelAmbientRh setFont:kFontBebasNeue(kAmbientRhFontSize)];
    [self.labelAmbientTemp setFont:kFontBebasNeue(kAmbientTempFontSize)];
    
    [self.labelSensorSerial setFont:kFontMyriadProRegular(kSensorSerialFontSize)];
    [self.labelCalibrationDate setFont:kFontMyriadProRegular(kDatesFontSize)];
    [self.labelExpireDate setFont:kFontMyriadProRegular(kDatesFontSize)];
    
    self.labelRh.text = @"--.--";
    self.labelTemp.text = @"--.--";
    self.labelAmbientRh.text = @"--";
    self.labelAmbientTemp.text = @"--";
    self.labelSensorSerial.text = @"";
    self.labelCalibrationDate.text = @"";
    self.labelExpireDate.text = @"";
    
    self.imgProgress = [[UIImage imageNamed:@"progressbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)];
    self.ivProgress.image = self.imgProgress;
    self.fWidthOfProgress = self.widthConstraintOfProgress.constant;
    
    // drop down
    self.btnSalts.layer.cornerRadius = 3.0;
    self.btnSalts.clipsToBounds = YES;
    
    self.btnSalts.layer.borderColor = [UIColor colorWithRed:243/255.0 green:143/255.0 blue:29/255.0 alpha:1.0].CGColor;
    self.btnSalts.layer.borderWidth = 1.0;

    self.tableView.layer.cornerRadius = 3.0;
    self.tableView.clipsToBounds = YES;
    
    self.tableView.layer.borderColor = [UIColor colorWithRed:243/255.0 green:143/255.0 blue:29/255.0 alpha:1.0].CGColor;
    self.tableView.layer.borderWidth = 1.0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    [self.view addGestureRecognizer:tap];
    
    
    prevTakenTime = 0;
    
    self.ivProgress.hidden = YES;
    
    self.btnStore.enabled = NO;
    
    
    // last view
    self.viewLast.layer.cornerRadius = 10.0;
    self.viewLast.clipsToBounds = YES;
    self.viewLast.layer.borderColor = [UIColor colorWithRed:243/255.0 green:143/255.0 blue:29/255.0 alpha:1.0].CGColor;
    self.viewLast.layer.borderWidth = 1.0;
    self.leftConstraintOfViewLast.constant = self.view.frame.size.width - kLastViewFoldWidth;
    self.viewLast.alpha = kLastViewFoldAlpha;
    
    [self showLastCalData:nil];
    
    _sharedOSViewController = self;
    
    // bluetooth icon
    imageBluetooth = [UIImage imageNamed:@"Bluetooth"];
    imageBluetooth_blue = [UIImage imageNamed:@"Bluetooth_blue"];
    self.ivBluetoothIcon.image = imageBluetooth;
    
    // left gesture
    [self.view addGestureRecognizer:self.leftGesture];
    self.leftGesture.enabled = NO;
    
    // warning label
    self.labelWarning.alpha = 0;
    self.labelWarning.text = @"";
    self.labelWarning.layer.borderColor = self.labelWarning.textColor.CGColor;
    self.labelWarning.layer.cornerRadius = 2.0;
    self.labelWarning.clipsToBounds = YES;

    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDataChangedFromManager:) name:kDataChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGetReadingFromManager:) name:kReadingTaken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSaltChangedFromManager:) name:kSaltChanged object:nil];
    
    
    prevLoginTryTime = 0;
    
    // view job
    self.topConstraintOfViewJob.constant = -self.viewJob.bounds.size.height;
    self.tfJobName.layer.borderColor = [UIColor colorWithRed:235.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0].CGColor;
    self.tfJobName.layer.borderWidth = 1.0;
    self.tfJobName.layer.cornerRadius = 2.0;
    
    imageDownArrow = [UIImage imageNamed:@"icon_downarrow"];
    imageDownArrowWhite = nil; //[UIImage imageNamed:@"icon_downarrow_white"];
    
    // new job
    newJob = nil;
    
#if USE_JOBEDITOR_IN_MAIN_SCREEN
    if (kUseJobsFunction == 1) {
        self.btnUpDownArrowForViewJob.hidden = NO;
        [self initViewJob];
    }
#endif
    
    if (kUseJobsFunction == 1) {
        self.labelCurrentJob.hidden = NO;
        self.labelCurrentJobTitle.hidden = NO;
    } else {
        self.labelCurrentJob.hidden = YES;
        self.labelCurrentJobTitle.hidden = YES;
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShowing:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHiding:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self refreshCurrentJob];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
    
    // keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - scan manager delegate
- (void)scanManager:(ScanManager *)scanManager didFindSensor:(SensorData *)sensorData
{
    SEL aSelector = NSSelectorFromString(@"startScan");
    [self.scanManager stopScan];
    [self.scanManager performSelector:aSelector withObject:nil afterDelay:scanDelay];
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (![self compareData:sensorData] || (now - prevTakenTime >= 5.0))
    {
        prevTakenTime = now;
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self onGetData:sensorData];
        });
    }
}

- (void)scanManager:(ScanManager *)scanManager didFindElseDevice:(id)sender
{
//    SEL aSelector = NSSelectorFromString(@"startScan");
//    [self.scanManager stopScan];
//    [self.scanManager performSelector:aSelector withObject:nil afterDelay:scanDelay];
}

#pragma mark - data compare
- (BOOL)compareData:(SensorData *)sensorData
{
    if (sensorData == nil)
        return NO;
    
    NSString *sensorSerial = sensorData.ssn;
    SensorInfo *sensorInfo = [[OSCalCheckManager sharedInstance] getSensorInfo:sensorSerial];
    if (sensorInfo == nil)
        return NO;
    
    SensorData *lastSensorData = sensorInfo.lastSensorData;
    if (lastSensorData == nil)
        return NO;
    
    return [lastSensorData isEqual:sensorData];
}

#pragma mark - Data To UI Processing
- (void)onGetData:(SensorData *)sensorData {
    
    NSString *sensorSerial = sensorData.ssn;
    if (sensorSerial == nil)
        return;
    
    self.labelRh.text = @"--.--";
    self.labelTemp.text = @"--.--";
    self.labelResult.text = @"----";
    
    self.ivBluetoothIcon.image = imageBluetooth_blue;
    
    [[OSCalCheckManager sharedInstance] onGetReading:sensorData];
}

// handlers for events -------------

- (void)onGetReadingFromManager:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ssn = (NSString *)notification.object;
        SensorInfo *sensorInfo = [[OSCalCheckManager sharedInstance] getSensorInfo:ssn];
        if (sensorInfo != [OSCalCheckManager sharedInstance].currSensorInfo)
            return;
        
        [self performSelector:@selector(_showSensorInfo:) withObject:sensorInfo afterDelay:0.5];
    });
}

- (void)onSaltChangedFromManager:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ssn = (NSString *)notification.object;
        SensorInfo *sensorInfo = [[OSCalCheckManager sharedInstance] getSensorInfo:ssn];
        if (sensorInfo != [OSCalCheckManager sharedInstance].currSensorInfo)
            return;
        [self _showSensorInfo:sensorInfo fromReading:NO calcChanged:YES];
    });
}

- (void)onDataChangedFromManager:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ssn = (NSString *)notification.object;
        SensorInfo *sensorInfo = [[OSCalCheckManager sharedInstance] getSensorInfo:ssn];
        if (sensorInfo != [OSCalCheckManager sharedInstance].currSensorInfo)
            return;
        [self _showSensorInfo:sensorInfo fromReading:NO calcChanged:NO];
    });
    
}

//------------------------------------------------------------

- (void)_showSensorInfo:(SensorInfo *)sensorInfo {
    [self _showSensorInfo:sensorInfo fromReading:YES calcChanged:NO];
}

- (void)_showSensorInfo:(SensorInfo *)sensorInfo fromReading:(BOOL)fromReading calcChanged:(BOOL)calcChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (sensorInfo == nil)
            return;
        
        if (sensorInfo != [OSCalCheckManager sharedInstance].currSensorInfo)
            return;
        
        
        // change bluetooth icon
        self.ivBluetoothIcon.image = imageBluetooth;
        
        ///since we recieved 3 2-bytes packages of serialNumber in little endian format we'll have to transform it so the string has appropriate look
        SensorData *sensorData = sensorInfo.lastSensorData;
        [self setProgress:(float)sensorData.batteryLevel];
        
        CGFloat rh = sensorData.rh;
        CGFloat temp_f = sensorData.temp;
        CGFloat ambRh = sensorData.ambientRh;
        CGFloat ambTemp = sensorData.ambientTemp;
        
        self.labelRh.text = [NSString stringWithFormat:@"%3.1f", rh];
        self.labelAmbientRh.text = [NSString stringWithFormat:@"%3.1f", ambRh];
        self.labelTemp.text = [NSString stringWithFormat:@"%3.1f", temp_f];
        self.labelAmbientTemp.text = [NSString stringWithFormat:@"%3.1f", ambTemp];
        
        // sensor serial
        self.labelSensorSerial.text = sensorData.ssn;
        
        // calculate result
        OSSaltSolution *saltSolution = sensorInfo.saltSolution;
        if (saltSolution)
        {
            if (saltSolution.calculable)
            {
                [self showResultForCalResult:sensorInfo.result showAlert:(fromReading||calcChanged)?true:false];
            }
            else
            {
                self.labelResult.hidden = YES;
                self.labelForResult.hidden = YES;
            }
            
            if (saltSolution.storable)
                self.btnStore.enabled = YES;
            else
                self.btnStore.enabled = NO;
        }
        else
        {
            self.btnStore.enabled = NO;
            
            self.labelResult.hidden = YES;
            self.labelForResult.hidden = YES;
        }
        
        // calibration date, cal cert due date
        [self showCalibrationAndCalDue:sensorInfo];
        
        // last cal data
        [self showLastCalData:sensorInfo];
        
        // warning label
        [self _showLabelWarning:sensorInfo];
    });
}

- (NSString *)resultForCalcResult:(CalCheckResult)result
{
    NSString *strResult = @"";
    if (result == CalCheckResultError)
    {
        strResult = @"ERROR";
    }
    else if (result == CalCheckResultPass)
    {
        strResult = @"PASSED";
    }
    else if (result == CalCheckResultFail)
    {
        strResult = @"FAILED";
    }
    return strResult;
}

- (UIColor *)colorForCalcResult:(CalCheckResult)result
{
    UIColor *labelColor = [UIColor redColor];
    if (result == CalCheckResultError)
    {
        labelColor = [UIColor redColor];
    }
    else if (result == CalCheckResultPass)
    {
        labelColor = [UIColor greenColor];
    }
    else if (result == CalCheckResultFail)
    {
        labelColor = [UIColor redColor];
    }
    return labelColor;
}

- (void)showResultForCalResult:(CalCheckResult)result showAlert:(BOOL)showAlert
{
    NSString *strResult = [self resultForCalcResult:result];
    UIColor *labelColor = [self colorForCalcResult:result];
    self.labelResult.textColor = labelColor;
    self.labelResult.text = strResult;
    
    self.labelResult.hidden = NO;
    self.labelForResult.hidden = NO;
    
    // show alert when cal check result is not "PASSED"
    
    if (result != CalCheckResultPass)
    {
        if (showAlert)
        {
            if (self.alertForFaildMessage != nil)
                return;
            
            self.alertForFaildMessage = [[UIAlertView alloc] initWithTitle:@"Calibration Checking Failed"
                                                                   message:@"Be sure to allow enough time for the Cal Check and Sensor to come to equilibrium before checking again. Ambient temperature fluctuations may require additional equilibration time."
                                                                  delegate:self
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
            [self.alertForFaildMessage show];
        }
    }
    else
    {
        if (self.alertForFaildMessage != nil)
        {
            [self.alertForFaildMessage dismissWithClickedButtonIndex:0 animated:YES];
            self.alertForFaildMessage = nil;
        }
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.alertForFaildMessage = nil;
}

// calculate expiration date from calibration date
- (NSDate *)expireDateWithCalibrationDate:(NSDate *)calibrationDate
{
    return [OSExpirationManager expirationDateWithCalibrationDate:calibrationDate];
}

#pragma mark - salt selection

// salt selection canceled
// called when user tap dropdown again or tap background
- (IBAction)onSaltsSelectCancel:(id)sender
{
    // show modes
    if (self.heightConstraintOfDropdown.constant == 0)
    {
        self.heightConstraintOfDropdown.constant = kSaltCellHeight * [OSSaltSolutionManager sharedInstance].arraySalts.count;
        [UIView animateWithDuration:kDropdownAnimateDuration animations:^() {
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self.tableView reloadData];
            [self.view bringSubviewToFront:self.tableView];
        }];
    }
    else
    {
        self.heightConstraintOfDropdown.constant = 0;
        [UIView animateWithDuration:kDropdownAnimateDuration animations:^() {
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            //
        }];
    }
}

// called when user changed salt solution on combobox(salt solution table view)
- (void)onSaltChanged:(OSSaltSolution *)saltSolution
{
    [[OSCalCheckManager sharedInstance] onSaltSolutionChanged:saltSolution];
}


// check calibration due and will represent it on UIs
- (void)_showLabelWarning:(SensorInfo *)sensorInfo
{
    // check certification

    if (sensorInfo.shouldRecertification)
    {
        // show warning label
        self.labelWarning.text = [OSCertificationManager messageForDueRecertification];
        if (self.labelWarning.alpha < 1)
        {
            [UIView animateWithDuration:0.5 animations:^() {
                self.labelWarning.alpha = 1.0;
            }];
        }
    }
    else
    {
        // show warning label
        int days = sensorInfo.isInWarningPeriodWithCalibrationDate;
        if (days > 0)
        {
            // show appropriate spot
            self.labelWarning.text = [OSCertificationManager messageForBeforeRecertification:days];
            
            if (self.labelWarning.alpha < 1)
            {
                [UIView animateWithDuration:kLabelWarningAnimateDuration animations:^() {
                    self.labelWarning.alpha = 1.0;
                }];
            }
        }
        else
        {
            if (self.labelWarning.alpha > 0)
            {
                [UIView animateWithDuration:kLabelWarningAnimateDuration animations:^() {
                    self.labelWarning.alpha = 0;
                }];
            }
        }
    }
}

- (void)showCalibrationAndCalDue:(SensorInfo *)sensorInfo
{
    if (sensorInfo == nil)
        return;
    
    // show calibration date
    CDCalibrationDate *cdCalibrationDate = sensorInfo.calibrationDate;
    CDCalCheck *firstCalCheck = sensorInfo.firstCalCheck;
    
    NSDate *calibrationDate = nil;
    if (cdCalibrationDate != nil)
        calibrationDate = cdCalibrationDate.calibrationDate;
    
    NSDate *firstCalCheckDate = nil;
    if (firstCalCheck != nil) {
        firstCalCheckDate = firstCalCheck.date;
        if ([[OSSaltSolutionManager sharedInstance] isInactiveSolution:firstCalCheck.salt_name]) {
            //
        }
    }
    
    if (calibrationDate != nil)
    {
        self.labelCalibrationDate.text = [calibrationDate toStringWithFormat:kDateFormat];
    }
    else
    {
        self.labelCalibrationDate.text = @"";
    }
    
    // cal cert due
    NSDate *caldue = [OSCertificationManager earlierRecertificationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
    if (caldue)
        self.labelExpireDate.text = [caldue toStringWithFormat:kDateFormat];
    else
        self.labelExpireDate.text = @"";
    
    if ([OSCertificationManager shouldRecertificationWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate])
    {
        self.labelExpireDate.textColor = kDuedDueDateColor;
    }
    else if ([OSCertificationManager isInWarningPeriodWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate])
    {
        self.labelExpireDate.textColor = kBeforeDueDateColor;
    }
    else
        self.labelExpireDate.textColor = kDefaultDueDateColor;
}

- (void)showLastCalData:(SensorInfo *)sensorInfo
{
    // init last view controls
    self.labelLastCalCheck.text = @"";
    self.labelLastRH.text = @"";
    self.labelLastTemp.text = @"";
    self.labelLastSaltSolution.text = @"";
    self.labelLastResult.text = @"";
    if (sensorInfo == nil)
        return;
    
    CDCalCheck *calCheck = sensorInfo.lastCalCheck;
    
    // check dummy one
    if (calCheck != nil && [[OSSaltSolutionManager sharedInstance] isDefaultSolution:calCheck.salt_name])
        calCheck = nil;
    
    if (calCheck == nil)
        return;
    
    // check dummy calcheck
    if ([[OSSaltSolutionManager sharedInstance] isDefaultSolution:calCheck.salt_name])
        return;
    
    OSSaltSolution *saltSoltion = [[OSSaltSolutionManager sharedInstance] saltSolutionWithSolution:calCheck.salt_name];
    
    // check "inactive" 
    if (saltSoltion == nil || [[OSSaltSolutionManager sharedInstance] isInactiveSolution:saltSoltion.salt_name]) {
        return;
    }
    
    if (saltSoltion.calculable)
    {
        CalCheckResult result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:[calCheck.rh floatValue] temp_f:[calCheck.temp floatValue] saltSolution:saltSoltion];
        NSString *strResult = [self resultForCalcResult:result];
        UIColor *labelColor = [self colorForCalcResult:result];
        self.labelLastResult.textColor = labelColor;
        self.labelLastResult.text = strResult;
    }
    
    self.labelLastCalCheck.text = [calCheck.date toStringWithFormat:kDateFormat];
    self.labelLastRH.text = [NSString stringWithFormat:@"%.1f", [calCheck.rh floatValue]];
    self.labelLastTemp.text = [NSString stringWithFormat:@"%.1f", [calCheck.temp floatValue]];
    //self.labelLastSaltSolution.text = saltSoltion.name;
    self.labelLastSaltSolution.text = saltSoltion.salt_name;
}

- (void)setProgress:(CGFloat)percentage
{
    self.ivProgress.hidden = NO;
    self.widthConstraintOfProgress.constant = self.fWidthOfProgress * percentage / 100.0;
    [UIView animateWithDuration:0.3f animations:^() {
        [self.view layoutIfNeeded];
    }];
}

#pragma mark table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [OSSaltSolutionManager sharedInstance].arraySalts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSSaltsCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"saltcell"];
    [cell bind:[[OSSaltSolutionManager sharedInstance].arraySalts objectAtIndex:indexPath.row]];
    [cell setDelegate:self];
    return cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if 0
    NSString *name = [self.arraySalts objectAtIndex:indexPath.row];
    [self.btnSalts setTitle:name forState:UIControlStateNormal];
    
    [UIView animateWithDuration:kDropdownAnimateDuration animations:^{
        CGRect rtFrame = self.tableView.frame;
        self.tableView.frame = CGRectMake(rtFrame.origin.x, rtFrame.origin.y, rtFrame.size.width, 0);
    }];
#endif
}

// user tap a salt solution
- (void)didCellTap:(OSSaltsCell *)cell
{
    [self.btnSalts setTitle:cell.saltSolution.desc forState:UIControlStateNormal];
    [self onSaltChanged:cell.saltSolution];
    
    self.heightConstraintOfDropdown.constant = 0;
    [UIView animateWithDuration:kDropdownAnimateDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - save action
- (IBAction)onStoreCalCheck:(id)sender
{
    SensorInfo *sensorInfo = [OSCalCheckManager sharedInstance].currSensorInfo;
    if (sensorInfo == nil)
        return;
    
    OSSaltSolution *saltSolution = sensorInfo.saltSolution;
    if (saltSolution == nil)
        return;
    
    // check certification
    if (sensorInfo.shouldRecertification) {
        [self showMessageForRecertification];
        return;
    }
    
    SensorData *sensorData = sensorInfo.lastSensorData;
    
    [[OSCalCheckManager sharedInstance] onStoreCalCheck:sensorInfo sensorData:sensorData];
}

- (void)showMessageForRecertification
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:[OSCertificationManager messageForRecertification]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - tap gesture
- (void)backgroundTap:(UITapGestureRecognizer *)backgroundTap {
    if (self.tableView.frame.size.height != 0)
    {
        [self onSaltsSelectCancel:nil];
    }
    
    if(currentResponder){
        [currentResponder resignFirstResponder];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.panGesture)
    {
        if (gestureRecognizer.view != self.tableView)
            return YES;
        return NO;
    }
    else if (gestureRecognizer == self.leftGesture)
    {
        if (gestureRecognizer.view != self.tableView && gestureRecognizer.view != self.viewLast)
            return YES;
        return NO;
    }
    return YES;
}

CGFloat firstX = 0, firstY = 0;

#pragma mark - pan gesture
- (IBAction)moveViewLast:(id)sender
{
    [self.view bringSubviewToFront:[(UIPanGestureRecognizer*)sender view]];
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        firstX = [sender view].frame.origin.x;
        firstY = [sender view].frame.origin.y;
    }
    
    CGRect rtFrame = self.viewLast.frame;
    CGFloat startX = self.view.frame.size.width - (rtFrame.size.width - kLastViewRightMargin);
    CGFloat lastX = self.view.frame.size.width - kLastViewFoldWidth;
    
    translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY);
    
    //[[sender view] setCenter:translatedPoint];
    
    
    if (translatedPoint.x < startX)
        translatedPoint.x = startX;
    else if (translatedPoint.x > lastX)
        translatedPoint.x = lastX;
    self.leftConstraintOfViewLast.constant = translatedPoint.x;
    self.viewLast.alpha = kLastViewFoldAlpha + (lastX - translatedPoint.x) / (lastX - startX) * (kLastViewUnfoldAlpha - kLastViewFoldAlpha);
    [self.view layoutIfNeeded];
    
    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = (0.2*[(UIPanGestureRecognizer*)sender velocityInView:self.view].x);
        
        
        CGFloat finalX = translatedPoint.x + velocityX;
        //CGFloat finalY = firstY;// translatedPoint.y + (.35*[(UIPanGestureRecognizer*)sender velocityInView:self.view].y);
        
        BOOL bFolding;
        if (finalX >= startX + rtFrame.size.width / 2.0)
        {
            finalX = self.view.frame.size.width - kLastViewFoldWidth;
            bFolding = YES;
        }
        else
        {
            finalX = startX;
            bFolding = NO;
        }
        
        self.leftConstraintOfViewLast.constant = finalX;
        
        CGFloat animationDuration = (ABS(velocityX)*.0002)+.2;
        //NSLog(@"the duration is: %f", animationDuration);
        
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^() {
                             [self.view layoutIfNeeded];
                             if (bFolding)
                                 self.viewLast.alpha = kLastViewFoldAlpha;
                             else
                                 self.viewLast.alpha = kLastViewUnfoldAlpha;
                         } completion:^(BOOL finished) {
                             //
                         }];
        
#if 0
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:animationDuration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidFinish)];
        [[sender view] setCenter:CGPointMake(finalX, finalY)];
        [UIView commitAnimations];
#endif
    }
}

#pragma mark - swipe left
- (IBAction)onSwipeLeft:(id)sender
{
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
}

- (IBAction)onMenu:(id)sender
{
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
    
    if (kUseJobsFunction == 1) {
        // show action sheet
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Menu" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Sensor Inventory", @"Jobs", nil];
        [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        [self performSegueWithIdentifier:@"gotoInventory" sender:self];
    }
}

#pragma mark - action sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //
    if (buttonIndex == 0)
        [self performSegueWithIdentifier:@"gotoInventory" sender:self];
    else if (buttonIndex == 1)
        [self performSegueWithIdentifier:@"gotoJobs" sender:self];
}


- (void)showToastMessage:(NSString *)msg
{
    [[[[iToast makeText:msg] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
}

#pragma mark - timer proc
- (void)onTimer:(id)sender
{
    /*
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - prevLoginTryTime > 10)
    {
        dispatch_async(dispatch_get_main_queue(), ^() {
            prevLoginTryTime = now;
            [self.serverManager loginWithUserName:kGlobalUserName password:kGlobalUserPass complete:^(BOOL success) {
                //
            }];
        });
    }
    */
    
#if USE_JOBEDITOR_IN_MAIN_SCREEN
    if (![OSAppContext sharedInstance].isJobStarted)
    {
        if (self.topConstraintOfViewJob.constant < 0)
        {
            if ([self.btnUpDownArrowForViewJob imageForState:UIControlStateNormal] != imageDownArrowWhite)
                [self.btnUpDownArrowForViewJob setImage:imageDownArrowWhite forState:UIControlStateNormal];
            else
                [self.btnUpDownArrowForViewJob setImage:imageDownArrow forState:UIControlStateNormal];
        }
    }
#endif
}

#pragma mark - interface orientation
- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - job management
#pragma mark - swipe down & up
- (IBAction)onSwipeDown:(id)sender
{
#if USE_JOBEDITOR_IN_MAIN_SCREEN
    if (kUseJobsFunction == 1)
        [self showViewJob];
#endif
}

- (void)showViewJob
{
    CDJob *currJob = [OSAppContext sharedInstance].currentJob;
    if (currJob)
    {
        self.labelJobName.text = currJob.name;
        self.tfJobName.text = currJob.name;
    }
    else
    {
        self.labelJobName.text = @"";
        self.tfJobName.text = @"";
    }
    
    self.topConstraintOfViewJob.constant = 0;
    [UIView animateWithDuration:kViewJobDownAnimateDuration animations:^() {
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.btnUpDownArrowForViewJob setImage:[UIImage imageNamed:@"icon_uparrow"] forState:UIControlStateNormal];
    }];
    
    if (self.statusJobEditing == OSJobEditingStatusNormal)
    {
        if (newJob == nil && [OSAppContext sharedInstance].currentJob == nil)
        {
            [self onEditJob:nil];
        }
    }
    else
    {
        if (self.statusJobEditing == OSJobEditingStatusNewJobEditing)
            [self.tfNewJobName becomeFirstResponder];
        else if (self.statusJobEditing == OSJobEditingStatusNewJobCreated)
            [self.tfNewJobName becomeFirstResponder];
    }
}

- (void)hideViewJob
{
    if(currentResponder){
        [currentResponder resignFirstResponder];
    }
    
    self.topConstraintOfViewJob.constant = -self.viewJob.bounds.size.height;
    [UIView animateWithDuration:kViewJobDownAnimateDuration animations:^() {
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.btnUpDownArrowForViewJob setImage:[UIImage imageNamed:@"icon_downarrow"] forState:UIControlStateNormal];
    }];
}

- (IBAction)onStartEndJob:(id)sender
{
    if ([OSAppContext sharedInstance].isJobStarted)
    {
        CDJob *currJob = [OSAppContext sharedInstance].currentJob;
        NSString *strButtonName;
        BOOL hideView;

        if (currJob == nil)
        {
            hideView = YES;
            strButtonName = @"Start Job";
        }
        else
        {
            switch (self.statusJobEditing) {
                case OSJobEditingStatusNormal:
                    hideView = YES;
                    strButtonName = @"Start Job";
                    break;
                    
                case OSJobEditingStatusCurrJobEditing:
                    hideView = NO;
                    strButtonName = @"Start Job";
                    break;
                    
                case OSJobEditingStatusNewJobCreated:
                case OSJobEditingStatusNewJobEditing:
                    hideView = NO;
                    strButtonName = @"Start New Job";

                    break;
                    
                default:
                    break;
            }
        }

        if (hideView)
            [self hideViewJob];
        
        [self.btnStartEndJob setTitle:strButtonName forState:UIControlStateNormal];
        
        [self showToastMessage:@"Job Ended"];
        
        [OSAppContext sharedInstance].isJobStarted = NO;
        
        [[OSModelManager sharedInstance] endJob:currJob];
    }
    else
    {
        CDJob *currJob = [OSAppContext sharedInstance].currentJob;
        BOOL hideView;
        
        switch (self.statusJobEditing) {
            case OSJobEditingStatusNormal:
            case OSJobEditingStatusCurrJobEditing:
                if (self.tfJobName.text == nil || self.tfJobName.text.length == 0)
                {
                    // warning
                    return;
                }
                if (currJob == nil)
                {
                    currJob = [[OSModelManager sharedInstance] createNewJob:self.tfJobName.text];
                    [OSAppContext sharedInstance].currentJob = currJob;
                }
                else
                {
                    [[OSModelManager sharedInstance] setNameForJob:currJob jobName:self.tfJobName.text];
                }
                hideView = YES;
                break;
            case OSJobEditingStatusNewJobCreated:
            case OSJobEditingStatusNewJobEditing:
                if (self.tfNewJobName.text == nil || self.tfNewJobName.text.length == 0)
                {
                    // warning
                    return;
                }
                else
                {
                    newJob = [[OSModelManager sharedInstance] createNewJob:self.tfNewJobName.text];
                    [OSAppContext sharedInstance].currentJob = newJob;
                    currJob = newJob;
                    
                    // change status
                    [self onCancelNewJob:nil];
                    
                    hideView = YES;
                }
                break;
                
            default:
                break;
        }
        
        [OSAppContext sharedInstance].isJobStarted = YES;
        [self.btnStartEndJob setTitle:@"End Job" forState:UIControlStateNormal];
        
        [self showToastMessage:@"Job Started"];
        
        if (hideView)
            [self hideViewJob];
        
        [[OSModelManager sharedInstance] startJob:currJob];
    }
}

- (IBAction)onDownArrowForViewJob:(id)sender
{
    if (self.topConstraintOfViewJob.constant < 0)
        [self showViewJob];
    else
        [self hideViewJob];
}

#pragma mark - swipe up
- (IBAction)onSwipeUp:(id)sender
{
    [self hideViewJob];
}

#pragma mark Keyboard Methods

- (void)keyboardShowing:(NSNotification *)note
{
    //[keyboardStrategy doKeyboardWillBeShown:note];
    if (self.statusJobEditing == OSJobEditingStatusNewJobCreated)
        self.statusJobEditing = OSJobEditingStatusNewJobEditing;
}

- (void)keyboardHiding:(NSNotification *)note
{
    //[keyboardStrategy doKeyboardWillBeHidden:note];
    switch (self.statusJobEditing) {
        case OSJobEditingStatusNormal:
            break;
        case OSJobEditingStatusCurrJobEditing:
            [self onJobEditingEnd];
            break;
        case OSJobEditingStatusNewJobEditing:
            [self onNewJobEditingEnd];
            break;
        case OSJobEditingStatusNewJobCreated:
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentResponder = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    currentResponder = nil;
}

#pragma mark - view job actions
- (IBAction)onEditJob:(id)sender
{
    self.labelJobName.hidden = YES;
    self.tfJobName.hidden = NO;
    self.tfJobName.text = self.labelJobName.text;
    self.btnPlusNewJob.hidden = YES;
    self.btnEditJob.hidden = YES;
    
    [self.tfJobName becomeFirstResponder];
    
    self.statusJobEditing = OSJobEditingStatusCurrJobEditing;
    
}

- (IBAction)onPlusNewJob:(id)sender
{
    self.topConstraintOfCurrentJob.constant = kTopConstantOfCurrentJobEditing;
    self.topConstraintOfNewJob.constant = kTopConstantOfNewJobEditing;
    
    self.labelForNewJobName.hidden = NO;
    self.tfNewJobName.text = @"";
    self.tfNewJobName.hidden = NO;
    self.btnCancelNewJob.hidden = NO;
    
    self.statusJobEditing = OSJobEditingStatusNewJobEditing;
    
    [self.tfNewJobName becomeFirstResponder];
    
    [UIView animateWithDuration:kViewJobChangeModeAnimateDuration animations:^() {
        self.labelForJobName.alpha = 0;
        self.labelJobName.alpha = 0;
        self.btnEditJob.alpha = 0;
        self.btnPlusNewJob.alpha = 0;
        
        [self.view layoutIfNeeded];
        
        self.labelForNewJobName.alpha = 1;
        self.tfNewJobName.alpha = 1;
        self.btnCancelNewJob.alpha = 1;
        
        if (![OSAppContext sharedInstance].isJobStarted)
            [self.btnStartEndJob setTitle:@"Start New Job" forState:UIControlStateNormal];
        
    } completion:^(BOOL finished) {
        self.labelForJobName.hidden = YES;
        self.labelJobName.hidden = YES;
        
        self.btnEditJob.hidden = YES;
        self.btnPlusNewJob.hidden = YES;
    }];
}

- (IBAction)onCancelNewJob:(id)sender
{
    self.statusJobEditing = OSJobEditingStatusNormal;
    if (currentResponder)
        [currentResponder resignFirstResponder];
    
    self.topConstraintOfCurrentJob.constant = kTopConstantOfCurrentJobNormal;
    self.topConstraintOfNewJob.constant = kTopConstantOfNewJobNormal;
    
    self.labelForJobName.hidden = NO;
    self.labelJobName.hidden = NO;
    self.btnEditJob.hidden = NO;
    self.btnPlusNewJob.hidden = NO;
    
    [UIView animateWithDuration:kViewJobChangeModeAnimateDuration animations:^() {
        self.labelForJobName.alpha = 1;
        self.labelJobName.alpha = 1;
        self.btnEditJob.alpha = 1;
        self.btnPlusNewJob.alpha = 1;
        
        [self.view layoutIfNeeded];
        
        self.labelForNewJobName.alpha = 0;
        self.tfNewJobName.alpha = 0;
        self.btnCancelNewJob.alpha = 0;
        
        if (![OSAppContext sharedInstance].isJobStarted)
            [self.btnStartEndJob setTitle:@"Start Job" forState:UIControlStateNormal];
        
    } completion:^(BOOL finished) {
        self.labelForNewJobName.hidden = YES;
        self.tfNewJobName.hidden = YES;
        self.btnCancelNewJob.hidden = YES;
    }];
}

- (void)onJobEditingEnd
{
    CDJob *currJob = [OSAppContext sharedInstance].currentJob;
    if (currJob)
    {
        if (self.tfJobName.text != nil && self.tfJobName.text.length > 0)
        {
            [[OSModelManager sharedInstance] setNameForJob:currJob jobName:self.tfJobName.text];
        }
    }
    self.labelJobName.hidden = NO;
    if (currJob)
        self.labelJobName.text = currJob.name;
    else
        self.labelJobName.text = self.tfJobName.text;
    
    self.tfJobName.hidden = YES;
    
    self.btnEditJob.hidden = NO;
    self.btnPlusNewJob.hidden = NO;
    
    self.statusJobEditing = OSJobEditingStatusNormal;
}

- (void)onNewJobEditingEnd
{
    self.statusJobEditing = OSJobEditingStatusNewJobCreated;
}

- (void)initViewJob
{
    self.labelForNewJobName.alpha = 0;
    self.labelForNewJobName.hidden = YES;
    
    self.tfJobName.text = @"";
    self.tfJobName.hidden = YES;
    
    self.tfNewJobName.text = @"";
    self.tfNewJobName.alpha = 0;
    self.tfNewJobName.hidden = YES;
    
    self.btnCancelNewJob.alpha = 0;
    self.btnCancelNewJob.hidden = YES;
    
    self.topConstraintOfCurrentJob.constant = kTopConstantOfCurrentJobNormal;
    self.topConstraintOfNewJob.constant = kTopConstantOfNewJobNormal;
    
    self.labelJobName.text = @"";
    if ([OSAppContext sharedInstance].currentJob != nil)
        self.labelJobName.text = [OSAppContext sharedInstance].currentJob.name;
    
    if ([OSAppContext sharedInstance].isJobStarted)
    {
        [self.btnStartEndJob setTitle:@"End Job" forState:UIControlStateNormal];
    }
    else
    {
        [self.btnStartEndJob setTitle:@"Start Job" forState:UIControlStateNormal];
    }
}

- (void)refreshCurrentJob
{
    if ([OSAppContext sharedInstance].isJobStarted)
    {
        if ([OSAppContext sharedInstance].currentJob)
        {
            self.labelCurrentJob.text = [OSAppContext sharedInstance].currentJob.name;
            [self.labelCurrentJob setTextColor:[UIColor whiteColor]];
        }
        else
            self.labelCurrentJob.text = @"(Not started)";
    }
    else
    {
        self.labelCurrentJob.text = @"(Not started)";
        [self.labelCurrentJob setTextColor:[UIColor lightGrayColor]];
    }
}

@end
