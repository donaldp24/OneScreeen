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
#import "ServerManager.h"
#import "NSDate+String.h"
#import "OSSaltsCell.h"
#import "OSSaltSolutionManager.h"
#import "iToast.h"

const int scanDelay = 1;

#define kFontBebasNeue(fSize)           [UIFont fontWithName:@"BebasNeue" size:fSize]
#define kFontMyriadProRegular(fSize)    [UIFont fontWithName:@"MyriadPro-Regular" size:fSize]

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

@interface OSViewController () <ScanManagerDelegate, ServerManagerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, OSSaltsCellDelegate>

{
    NSTimeInterval prevTakenTime;
}

@property (weak, nonatomic) IBOutlet UILabel *labelRh;
@property (weak, nonatomic) IBOutlet UILabel *labelTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelAmbientRh;
@property (weak, nonatomic) IBOutlet UILabel *labelAmbientTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelSensorSerial;
@property (weak, nonatomic) IBOutlet UILabel *labelExpireDate;
@property (weak, nonatomic) IBOutlet UILabel *labelCalibrationDate;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;

@property (weak, nonatomic) IBOutlet UIButton *btnSalts;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

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




@property (retain, nonatomic) ScanManager *scanManager;
@property (nonatomic) BOOL isLoggingIn;

@property (nonatomic, retain) NSMutableDictionary *dicSensorData;
@property (nonatomic, retain) ServerManager *serverManager;
@property (nonatomic, retain) NSMutableDictionary *calibrationDates;
@property (nonatomic, retain) NSMutableArray *arraySensorSerial;
@property (nonatomic, retain) NSString *currSensor;

@property (nonatomic, retain) NSMutableDictionary *dicCurrentSalt;
@property (nonatomic, retain) NSMutableDictionary *dicLastData;

@end

@implementation OSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = @"SCAN";
    
    self.calibrationDates = [[NSMutableDictionary alloc] init];
    self.arraySensorSerial = [[NSMutableArray alloc] init];
    self.currSensor = @"";
    

    self.scanManager = [[ScanManager alloc] initWithDelegate:self];
    //[self.scanManager startScan];
    
    self.serverManager = [[ServerManager alloc] init];
    self.serverManager.delegate = self;
    
    
    
    [self.serverManager setUsername:kGlobalUserName];
    [self.serverManager setUserpassword:kGlobalUserPass];
    
    self.isLoggingIn = [self.serverManager login];
    if (self.isLoggingIn)
    {
        [self didStartLogin];
    }
    else
    {
        [self didAlreadyLoggedIn];
        //[self.serverManager getExpirationDateForSensor:@"asdf"];
    }
    
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
    
    // salts
    self.btnSalts.layer.cornerRadius = 3.0;
    self.btnSalts.clipsToBounds = YES;
    
    self.btnSalts.layer.borderColor = [UIColor colorWithRed:243/255.0 green:143/255.0 blue:29/255.0 alpha:1.0].CGColor;
    self.btnSalts.layer.borderWidth = 1.0;
        
    //CGRect rtFrame = self.tableView.frame;
    //self.tableView.frame = CGRectMake(rtFrame.origin.x, rtFrame.origin.y, rtFrame.size.width, 0);
    
    self.tableView.layer.cornerRadius = 3.0;
    self.tableView.clipsToBounds = YES;
    
    self.tableView.layer.borderColor = [UIColor colorWithRed:243/255.0 green:143/255.0 blue:29/255.0 alpha:1.0].CGColor;
    self.tableView.layer.borderWidth = 1.0;
    
    self.dicCurrentSalt = [[NSMutableDictionary alloc] init];
    
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
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performSelector:@selector(onSaltsSelectCancel:) withObject:nil afterDelay:1];
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
    
    [self performSelector:@selector(onReadSensorData:) withObject:sensorData afterDelay:0.5];
}

- (void)onReadSensorData:(NSDictionary*)sensorData {
    
    if (self.dicSensorData == nil)
        self.dicSensorData = [[NSMutableDictionary alloc] init];
    
    NSString *sensorSerial = [sensorData objectForKey:kSensorDataSerialNumberKey];
    if (sensorSerial == nil)
        return;
    [self.dicSensorData setObject:sensorData forKey:sensorSerial];
    
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
    
    if (![self.arraySensorSerial containsObject:sensorSerial])
        [self.arraySensorSerial addObject:sensorSerial];
    if ([self.currSensor isEqualToString:sensorSerial])
    {
        //
    }
    else
    {
        [self onSensorChanged:sensorSerial];
    }
    self.currSensor = sensorSerial;
    
    NSDate *calibrationDate = [self.calibrationDates objectForKey:sensorSerial];
    if (calibrationDate != nil)
    {
        self.labelCalibrationDate.text = [calibrationDate toStringWithFormat:kDateFormat];
        self.labelExpireDate.text = [[self expireDateWithCalibrationDate:calibrationDate] toStringWithFormat:kDateFormat];
    }
    
    // calculate result
    OSSaltSolution *saltSolution = [self.dicCurrentSalt objectForKey:self.currSensor];
    if (saltSolution)
    {
        if (saltSolution.calculable)
        {
            CalCheckResult result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:rh temp_f:temp_f saltSolution:saltSolution];
            [self showResultForCalResult:result];
        }
    }
    
    // fetch
    if (self.isLoggingIn)
    {
        //
    }
    else
    {
        if ([self.serverManager isUserLoggedIn])
        {
            if (calibrationDate == nil)
            {
                [self didStartFetching];
                [self.serverManager getExpirationDateForSensor:sensorSerial];
            }
        }
        else
        {
            self.isLoggingIn = [self.serverManager login];
            if (self.isLoggingIn)
            {
                [self didStartLogin];
            }
        }
    }
}

- (void)showResultForCalResult:(CalCheckResult)result
{
    NSString *strResult = @"";
    if (result == CalCheckResultError)
    {
        strResult = @"ERROR";
        self.labelResult.textColor = [UIColor redColor];
    }
    else if (result == CalCheckResultPass)
    {
        strResult = @"PASS";
        self.labelResult.textColor = [UIColor greenColor];
    }
    else if (result == CalCheckResultFail)
    {
        strResult = @"FAIL";
        self.labelResult.textColor = [UIColor redColor];
    }
    self.labelResult.text = strResult;
}

- (NSDate *)expireDateWithCalibrationDate:(NSDate *)expireDate
{
    if (expireDate == nil)
        return nil;
    
    NSDate * newDate = [NSDate dateWithTimeInterval:365*24*3600*2 sinceDate:expireDate];
    return newDate;
}

#pragma mark - salt selection
- (IBAction)onSaltsSelectCancel:(id)sender
{
    // show modes
    if (self.tableView.frame.size.height == 0)
    {
        [UIView animateWithDuration:kDropdownAnimateDuration animations:^() {
            CGRect rtFrame = self.tableView.frame;
            self.tableView.frame = CGRectMake(rtFrame.origin.x, rtFrame.origin.y, rtFrame.size.width, kSaltCellHeight * [OSSaltSolutionManager sharedInstance].arraySalts.count);
        } completion:^(BOOL finished) {
            [self.tableView reloadData];
        }];
    }
    else
    {
        [UIView animateWithDuration:kDropdownAnimateDuration animations:^() {
            CGRect rtFrame = self.tableView.frame;
            self.tableView.frame = CGRectMake(rtFrame.origin.x, rtFrame.origin.y, rtFrame.size.width, 0);
        } completion:^(BOOL finished) {
            //[self.tableView reloadData];
            if (self.currSensor == nil)
                return;
            if ([self.dicCurrentSalt objectForKey:self.currSensor] == nil)
            {
                //OSSaltSolution *saltSolution = [[OSSaltSolutionManager sharedInstance] defaultSolution];
                //[self onSaltChanged:saltSolution];
                return;
            }
            //OSSaltSolution *currentSalt = [self.dicCurrentSalt objectForKey:self.currSensor];
            //[self onSaltChanged:currentSalt];
        }];
    }
}

- (void)onSaltChanged:(OSSaltSolution *)saltSolution
{
    self.btnStore.enabled = saltSolution.storable;
    self.labelForResult.hidden = !saltSolution.calculable;
    self.labelResult.hidden = !saltSolution.calculable;
    if (self.currSensor == nil)
    {
        [self.btnStore setEnabled:NO];
        return;
    }
    
    NSDictionary *dicData = [self.dicSensorData objectForKey:self.currSensor];
    if (dicData == nil)
        return;

    [self.dicCurrentSalt setObject:saltSolution forKey:self.currSensor];
    
    if (saltSolution.calculable)
    {
        CGFloat rh = [[dicData objectForKey:kSensorDataRHKey] floatValue];
        CGFloat temp_f = [[dicData objectForKey:kSensorDataTemperatureKey] floatValue];
        
        CalCheckResult result = [[OSSaltSolutionManager sharedInstance] calCheckWithRh:rh temp_f:temp_f saltSolution:saltSolution];
        
        [self showResultForCalResult:result];
    }
}

- (void)onSensorChanged:(NSString *)newSensorSerial
{
    self.currSensor = newSensorSerial;
    
    // fetching information from server
    [self retrieveDataForSensor:newSensorSerial];
}

- (void)retrieveDataForSensor:(NSString *)sensorSerial
{
    [self.serverManager retrieveData:sensorSerial];
}

- (void)onRetrievedData:(NSDictionary *)data
{
    dispatch_async(dispatch_get_main_queue(), ^(){
        NSString *success = data[@"success"];
        if ([success isEqualToString:@"true"])
        {
            NSString *sensorSerial = data[@"ssn"];
            [self.dicLastData setObject:data forKey:sensorSerial];
            [self showLastCalData:sensorSerial];
        }
        else
        {
            [self showLastCalData:nil];
        }
    });
}

- (void)showLastCalData:(NSString *)sensorSerial
{
  
    // init last view controls
    self.labelLastCalCheck.text = @"";
    self.labelLastRH.text = @"";
    self.labelLastTemp.text = @"";
    self.labelLastSaltSolution.text = @"";
    self.labelLastResult.text = @"";
    NSDictionary *data = [self.dicLastData objectForKey:sensorSerial];
    if (data == nil)
        return;
    
    //NSString *success = data[@"success"];

    NSString *strRh = data[@"rh"];
    NSString *strTemp = data[@"temp"];
    NSString *strSaltSolution = data[@"salt_name"];
    NSString *strCalCheck = data[@"date"];
    
    CGFloat rh = [strRh floatValue] / 10.0f;
    CGFloat temp = [strTemp floatValue] / 10.0f;
    NSDate *date = [NSDate dateWithString:strCalCheck withFormat:kUploadDataDateFormat];
    
    self.labelLastCalCheck.text = [date toStringWithFormat:kDateFormat];
    self.labelLastRH.text = [NSString stringWithFormat:@"%.1f", rh];
    self.labelLastTemp.text = [NSString stringWithFormat:@"%.1f", temp];
    self.labelLastSaltSolution.text = strSaltSolution;
}

#pragma mark - server manager delegate
- (void)serverManager:(ServerManager *)serverManager
    didReceiveExpirationDate:(NSDate *)date
    forSensor:(NSString *)sensorSerial
{
    NSLog(@"didReceiveExpirationDate --- %@ : %@", date, sensorSerial);
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (date != nil)
        {
            NSDate * calibrationDate = date;
            NSDate * expireDate = [self expireDateWithCalibrationDate:calibrationDate];
            [self.calibrationDates setObject:calibrationDate forKey:sensorSerial];
            if ([self.currSensor isEqualToString:sensorSerial])
            {
                self.labelCalibrationDate.text = [calibrationDate toStringWithFormat:kDateFormat];
                self.labelExpireDate.text = [expireDate toStringWithFormat:kDateFormat];
            }
        }
        
        [self.indicator stopAnimating];
        [self.labelStatus setText:@"Retrieved success"];
    });
}

- (void)serverManager:(ServerManager *)serverManager didFailReceivingExpirationDateForSensor:(NSString *)sensorSerial
{
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self.indicator stopAnimating];
        [self.labelStatus setText:@"Retrieve failed"];
    });
}

- (void)serverManagerDidFinishUpload:(ServerManager *)serverManager {
    //
}

- (void)serverManagerUploadDidFailed:(ServerManager *)serverManager withError:(NSError *)error {
    //
}

-(void)serverManagerDidFailConnectingToServer:(ServerManager *)serverManager {
    NSLog(@"serverManagerDidFailConnectingToServer ---");
}

-(void)serverManagerDidSuccessfullyConnectToServer:(ServerManager *)serverManager {
    // fetch expire dates
    NSLog(@"serverManagerDidSuccessfullyConnectToServer ---");
}

-(void)serverManagerDidSuccessfullyLogin
{
    NSLog(@"serverManagerDidSuccessfullyLogin ---");
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        self.isLoggingIn = NO;
        self.labelStatus.text = @"Logged in successfully!";
        [self.indicator stopAnimating];
    });
}

-(void)serverManagerDidFailLogin
{
    NSLog(@"serverManagerDidFailLogin ---");
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        self.isLoggingIn = NO;
        [self.indicator stopAnimating];
        self.labelStatus.text = @"error - Log in failed";
    });
}

- (void)serverManager:(ServerManager *)serverManager willLoadOAuthInWebView:(UIWebView *)webView
{
    //
}

- (void)serverManager:(ServerManager *)serverManager didFinishOAuthInWebView:(UIWebView *)webView
{
    //
}

- (UIWebView *)webviewToLoadOAuth
{
    return nil;
}

- (void)serverManager:(ServerManager *)serverManager didStoreData:(BOOL)success
{
    if (success)
    {
        NSString *message = [NSString stringWithFormat:@"stored successfully!"];
        [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
    }
    else
    {
        NSString *message = [NSString stringWithFormat:@"store failed"];
        [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
    }
}

- (void)serverManager:(ServerManager *)serverManager didRetrieveData:(NSDictionary *)data success:(BOOL)success
{
    NSString *message;
    if (success)
    {
        [self onRetrievedData:data];
        message = [NSString stringWithFormat:@"Retrieved data"];
        [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
    }
    else
    {
        //message = [NSString stringWithFormat:@"Retrieve failed"];
    }
    
}

#pragma mark - status utilities
- (void)didStartLogin
{
    [self.indicator startAnimating];
    [self.labelStatus setText:@"Logging in..."];
}

- (void)didAlreadyLoggedIn
{
    [self.indicator stopAnimating];
    [self.labelStatus setText:@"Logged in"];
}

- (void)didStartFetching
{
    [self.indicator startAnimating];
    [self.labelStatus setText:@"Retrieving expiration date..."];
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


- (void)didCellTap:(OSSaltsCell *)cell
{
    [self.btnSalts setTitle:cell.saltSolution.name forState:UIControlStateNormal];
    [self onSaltChanged:cell.saltSolution];
    
    [UIView animateWithDuration:kDropdownAnimateDuration animations:^{
        CGRect rtFrame = self.tableView.frame;
        self.tableView.frame = CGRectMake(rtFrame.origin.x, rtFrame.origin.y, rtFrame.size.width, 0);
    }];
}

#pragma mark - save action
- (IBAction)onStoreCalCheck:(id)sender
{
    if (self.currSensor == nil)
        return;
    OSSaltSolution *saltSolution = [self.dicCurrentSalt objectForKey:self.currSensor];
    if (saltSolution == nil)
        return;
    
    NSDictionary *sensorData = [self.dicSensorData objectForKey:self.currSensor];
    if (sensorData == nil)
        return;
    
    //CGFloat progress = [[sensorData objectForKey:kSensorDataBatteryKey] floatValue];
    float rh = [[sensorData objectForKey:kSensorDataRHKey] floatValue];
    float temp = [[sensorData objectForKey:kSensorDataTemperatureKey] floatValue];
   
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    
    [data setObject:self.currSensor forKey:@"ssn"];
    [data setObject:@((int)(rh * 10)) forKey:@"rh"];
    [data setObject:@((int)(temp * 10)) forKey:@"temp"];
    [data setObject:saltSolution.solution forKey:@"salt_name"];
    [data setObject:[[NSDate date] toStringWithFormat:kUploadDataDateFormat] forKey:@"date"];
    
    [self.serverManager storeData:data];
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
    if (gestureRecognizer.view != self.tableView)
        return YES;
    return NO;
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
        NSLog(@"the duration is: %f", animationDuration);
        
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
@end
