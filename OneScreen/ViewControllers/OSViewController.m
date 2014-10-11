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

const int scanDelay = 5;

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

static OSViewController *_sharedOSViewController = nil;

@interface OSViewController () <ScanManagerDelegate, OSServerManagerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, OSSaltsCellDelegate>

{
    NSTimeInterval prevTakenTime;
    UIImage *imageBluetooth;
    UIImage *imageBluetooth_blue;
    NSTimeInterval prevLoginTryTime;
    NSTimer *timer;
}

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

@property (retain, nonatomic) ScanManager *scanManager;
@property (nonatomic, retain) OSServerManager *serverManager;

@property (nonatomic, retain) NSMutableDictionary *dicSensorData;
@property (nonatomic, retain) NSString *currSensor;
@property (nonatomic, retain) OSSaltSolution *currSalt;

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
    
    self.currSensor = @"";
    
    // start scan
    self.scanManager = [[ScanManager alloc] initWithDelegate:self];
    //[self.scanManager startScan];
    
    self.serverManager = [OSServerManager sharedInstance];
    self.serverManager.delegate = self;
    [self.serverManager loginWithUserName:kGlobalUserName password:kGlobalUserPass];
    
    // initialize fonts
    [self.labelRh setFont:kFontBebasNeue(kRhFontSize)];
    [self.labelTemp setFont:kFontBebasNeue(kTempFontSize)];
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
    
    self.currSalt = [[OSSaltSolutionManager sharedInstance] defaultSolution];
    
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
    
    // warning label
    self.labelWarning.alpha = 0;
    self.labelWarning.text = @"";
    self.labelWarning.layer.borderColor = self.labelWarning.textColor.CGColor;
    self.labelWarning.layer.cornerRadius = 2.0;
    self.labelWarning.clipsToBounds = YES;

    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRetrievedData:) name:kLastCalCheckChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRetrievedOldestData:) name:kOldestCalCheckChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRetrievedCalibrationDate:) name:kCalibrationDateChanged object:nil];
    
    prevLoginTryTime = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    self.serverManager.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - scan manager delegate
- (void)scanManager:(ScanManager *)scanManager didFindSensor:(NSDictionary *)sensorData
{
    SEL aSelector = NSSelectorFromString(@"startScan");
    [self.scanManager stopScan];
    [self.scanManager performSelector:aSelector withObject:nil afterDelay:scanDelay];
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (![self compareData:sensorData] || (now - prevTakenTime >= 5.0))
    {
        prevTakenTime = now;
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self displayData:sensorData];
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
- (BOOL)compareData:(NSDictionary *)sensorData
{
    if (self.dicSensorData == nil)
        return NO;
    
    NSString *sensorSerial = [sensorData objectForKey:kSensorDataSerialNumberKey];
    NSDictionary *lastSensorData = [self.dicSensorData objectForKey:sensorSerial];
    if (lastSensorData == nil)
        return NO;
    
    if ([lastSensorData[kSensorDataBatteryKey] isEqual:sensorData[kSensorDataBatteryKey]] &&
        [lastSensorData[kSensorDataRHKey] isEqual:sensorData[kSensorDataRHKey]] &&
        [lastSensorData[kSensorDataTemperatureKey] isEqual:sensorData[kSensorDataTemperatureKey]] &&
        [lastSensorData[kSensorDataRHAmbientKey] isEqual:sensorData[kSensorDataRHAmbientKey]] &&
        [lastSensorData[kSensorDataTemperatureAmbientKey] isEqual:sensorData[kSensorDataTemperatureAmbientKey]])
    {
        return YES;
    }
    return NO;
}

#pragma mark - Data To UI Processing
- (void) displayData:(NSDictionary *)sensorData {
    
    self.labelRh.text = @"--.--";
    self.labelTemp.text = @"--.--";
    self.labelResult.text = @"----";
    
    self.ivBluetoothIcon.image = imageBluetooth_blue;
    
    [self performSelector:@selector(onReadSensorData:) withObject:sensorData afterDelay:0.5];
}

// called when read data from sensor
- (void)onReadSensorData:(NSDictionary*)sensorData {
    
    if (self.dicSensorData == nil)
        self.dicSensorData = [[NSMutableDictionary alloc] init];
    
    NSString *sensorSerial = [sensorData objectForKey:kSensorDataSerialNumberKey];
    if (sensorSerial == nil)
        return;
    [self.dicSensorData setObject:sensorData forKey:sensorSerial];
    
    // change bluetooth icon
    self.ivBluetoothIcon.image = imageBluetooth;
    
    ///since we recieved 3 2-bytes packages of serialNumber in little endian format we'll have to transform it so the string has appropriate look
    [self setProgress:[[sensorData objectForKey:kSensorDataBatteryKey] floatValue]];
    
    CGFloat rh = [[sensorData objectForKey:kSensorDataRHKey] floatValue];
    CGFloat temp_f = [[sensorData objectForKey:kSensorDataTemperatureKey] floatValue];
    
    self.labelRh.text = [NSString stringWithFormat:@"%3.1f", rh];
    self.labelAmbientRh.text = [NSString stringWithFormat:@"%3.1f",[[sensorData objectForKey:kSensorDataRHAmbientKey] floatValue]];
    self.labelTemp.text = [NSString stringWithFormat:@"%3.1f", temp_f];
    self.labelAmbientTemp.text = [NSString stringWithFormat:@"%3.1f",[[sensorData objectForKey:kSensorDataTemperatureAmbientKey] floatValue]];
    
    // sensor serial
    self.labelSensorSerial.text = sensorSerial;
    
    if ([self.currSensor isEqualToString:sensorSerial])
    {
        // same sensor
    }
    else
    {
        [self onSensorChanged:sensorSerial];
    }
    self.currSensor = sensorSerial;
    
    // calculate result
    OSSaltSolution *saltSolution = self.currSalt;
    if (saltSolution)
    {
        if (saltSolution.calculable)
        {
            CalCheckResult result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:rh temp_f:temp_f saltSolution:saltSolution];
            [self showResultForCalResult:result];
        }
    }
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

- (void)showResultForCalResult:(CalCheckResult)result
{
    NSString *strResult = [self resultForCalcResult:result];
    UIColor *labelColor = [self colorForCalcResult:result];
    self.labelResult.textColor = labelColor;
    self.labelResult.text = strResult;
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
    self.btnStore.enabled = NO;
    self.labelResult.hidden = YES;
    self.labelForResult.hidden = YES;
    if (self.currSensor == nil || self.currSensor.length == 0)
        return;
    
    NSDictionary *dicData = [self.dicSensorData objectForKey:self.currSensor];
    if (dicData == nil)
        return;
    
    self.btnStore.enabled = saltSolution.storable;
    self.labelForResult.hidden = !saltSolution.calculable;
    self.labelResult.hidden = !saltSolution.calculable;
   
    
    self.currSalt = saltSolution;
    
    // re-calc result
    if (saltSolution.calculable)
    {
        CGFloat rh = [[dicData objectForKey:kSensorDataRHKey] floatValue];
        CGFloat temp_f = [[dicData objectForKey:kSensorDataTemperatureKey] floatValue];
        
        CalCheckResult result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:rh temp_f:temp_f saltSolution:saltSolution];
        
        [self showResultForCalResult:result];
    }
}


// called when reading new sensor's data.
- (void)onSensorChanged:(NSString *)newSensorSerial
{
    self.currSensor = newSensorSerial;
    
    // calibration and cal check due
    [self showCalibrationAndCalDue];
    
    // show last data locally
    [self showLastCalData:self.currSensor];
    
    // check certification
    [self setLabelWarningCalibrationChecking:NO];
    
    // fetching information from server
    [self retrieveDataForSensor:newSensorSerial];
    
    // fetching calibration date
    [self.serverManager retrieveCalibrationDateForSensor:newSensorSerial];
}

// check calibration due and will represent it on UIs
- (BOOL)setLabelWarningCalibrationChecking:(BOOL)bShowAlert
{
    // check certification
    CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:self.currSensor];
    NSDate *calibrationDate = (cdCalibrationDate == nil) ? nil : cdCalibrationDate.calibrationDate;
    CDCalCheck *oldestData = [[OSModelManager sharedInstance] getOldestCalCheckForSensor:self.currSensor];
    NSDate *firstCalCheckDate;
    if (oldestData == nil)
        firstCalCheckDate = nil;
    else
        firstCalCheckDate = oldestData.date;
    if ([OSCertificationManager shouldRecertificationWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate])
    {
        if (bShowAlert)
        {
            // alert message
            [self showMessageForRecertification];
        }
        
        // show warning label
        self.labelWarning.text = [OSCertificationManager messageForDueRecertification];
        if (self.labelWarning.alpha < 1)
        {
            [UIView animateWithDuration:0.5 animations:^() {
                self.labelWarning.alpha = 1.0;
            }];
        }
        
        return NO;
    }
    else
    {
        // show warning label
        int days = [OSCertificationManager isInWarningPeriodWithCalibrationDate:calibrationDate firstCalCheckDate:firstCalCheckDate];
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
        
        return YES;
    }
}

- (void)retrieveDataForSensor:(NSString *)sensorSerial
{
    [self.serverManager retrieveCalCheckForSensor:sensorSerial oldest:NO];
    [self.serverManager retrieveCalCheckForSensor:sensorSerial oldest:YES];
}

- (void)onRetrievedData:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(){
       [self showLastCalData:self.currSensor];
    });
}

- (void)onRetrievedOldestData:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        // check calibration due
        [self setLabelWarningCalibrationChecking:NO];
    });
}

- (void)onRetrievedCalibrationDate:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^() {
        // show calibration/expiration date
        [self showCalibrationAndCalDue];
        
        // check calibration due
        [self setLabelWarningCalibrationChecking:NO];
    });
}

- (void)showCalibrationAndCalDue
{
    // show calibration date
    CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:self.currSensor];
    CDCalCheck *firstCalCheck = [[OSModelManager sharedInstance] getOldestCalCheckForSensor:self.currSensor];
    
    NSDate *calibrationDate = nil;
    if (cdCalibrationDate != nil)
        calibrationDate = cdCalibrationDate.calibrationDate;
    
    NSDate *firstCalCheckDate = nil;
    if (firstCalCheck != nil)
        firstCalCheckDate = firstCalCheck.date;
    
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

- (void)showLastCalData:(NSString *)sensorSerial
{
  
    // init last view controls
    self.labelLastCalCheck.text = @"";
    self.labelLastRH.text = @"";
    self.labelLastTemp.text = @"";
    self.labelLastSaltSolution.text = @"";
    self.labelLastResult.text = @"";
    if (sensorSerial == nil || sensorSerial.length == 0)
        return;
    
    CDCalCheck *calCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:sensorSerial];
    if (calCheck == nil)
        return;
    
    OSSaltSolution *saltSoltion = [[OSSaltSolutionManager sharedInstance] saltSolutionWithSolution:calCheck.salt_name];
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
    self.labelLastSaltSolution.text = saltSoltion.solution;
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
    [self.btnSalts setTitle:cell.saltSolution.name forState:UIControlStateNormal];
    [self onSaltChanged:cell.saltSolution];
    
    self.heightConstraintOfDropdown.constant = 0;
    [UIView animateWithDuration:kDropdownAnimateDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - save action
- (IBAction)onStoreCalCheck:(id)sender
{
    if (self.currSensor == nil || self.currSensor.length == 0)
        return;
    
    OSSaltSolution *saltSolution = self.currSalt;
    if (saltSolution == nil)
        return;
    
    // check certification
    BOOL storable = [self setLabelWarningCalibrationChecking:YES];
    if (!storable)
        return;
    
    NSDictionary *sensorData = [self.dicSensorData objectForKey:self.currSensor];
    if (sensorData == nil)
        return;
    
    //CGFloat progress = [[sensorData objectForKey:kSensorDataBatteryKey] floatValue];
    float rh = [[sensorData objectForKey:kSensorDataRHKey] floatValue];
    float temp = [[sensorData objectForKey:kSensorDataTemperatureKey] floatValue];
   
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    
    [data setObject:self.currSensor forKey:kDataSensorSerialKey];
    [data setObject:@((int)((rh + 0.05) * 10)) forKey:kDataRhKey];
    [data setObject:@((int)((temp + 0.05) * 10)) forKey:kDataTempKey];
    [data setObject:saltSolution.solution forKey:kDataSaltSolutionKey];
    [data setObject:[[NSDate date] toStringWithFormat:kUploadDataDateFormat] forKey:kDataDateKey];
    
    [self.serverManager storeCalCheck:data];
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
    [self onInventory:sender];
}

- (IBAction)onInventory:(id)sender
{
    // show table view
    [self performSegueWithIdentifier:@"gotoInventory" sender:self];
}


#pragma mark - Server delegate
- (void)didLogin:(BOOL)success
{
    if (success)
    {
        [self showToastMessage:@"Logged in"];
    }
    else
    {
        [self showToastMessage:@"Login failed"];
    }
}

- (void)didRetrieveCalibrationDate:(NSString *)ssn success:(BOOL)success
{
    if (success)
    {
        [self showToastMessage:@"Retrieved calibration date"];
    }
    else
    {
        [self showToastMessage:@"Retrieve calibration date failed"];
    }
}

- (void)didRetrieveCalCheck:(NSString *)ssn success:(BOOL)success oldest:(BOOL)oldest
{
    if (success)
    {
        [self showToastMessage:@"Retrieved cal check"];
    }
    else
    {
        [self showToastMessage:@"Retrieve cal check failed"];
    }
}

- (void)didStoreCalCheck:(NSString *)ssn success:(BOOL)success
{
    if (success)
    {
        [self showToastMessage:@"Stored successfully"];
    }
    else
    {
        [self showToastMessage:@"Store failed"];
    }
}

- (void)showToastMessage:(NSString *)msg
{
    [[[[iToast makeText:msg] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
}

#pragma mark - timer proc
- (void)onTimer:(id)sender
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - prevLoginTryTime > 5)
    {
        dispatch_async(dispatch_get_main_queue(), ^() {
            prevLoginTryTime = 5;
            [self.serverManager loginWithUserName:kGlobalUserName password:kGlobalUserPass];
        });
    }
}

@end
