//
//  OSSensorInventoryTableViewController.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/8/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSSensorInventoryTableViewController.h"
#import "OSServerManager.h"
#import "OSModelManager.h"
#import "OSSensorCell.h"
#import "OSAppDelegate.h"
#import "OSDummyViewController.h"
#import "OSReportManager.h"
#import "ReaderViewController.h"
#import "ForceLandscape.h"
#import "OSSaltSolutionManager.h"

#define USE_SEARCHBAR       0

#define kHeightForSection       48.0


@interface OSProcessingSensor : NSObject

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic) BOOL retrievedLatestCalCheck;
@property (nonatomic) BOOL retrievedFirstCalCheck;
@property (nonatomic) BOOL retrievedCalibrationDate;
@property (nonatomic) BOOL isShownName;
@property (nonatomic) BOOL isSelected;

@end

@implementation OSProcessingSensor
@end


@interface OSSensorInventoryTableViewController () <UIGestureRecognizerDelegate, OSServerManagerDelegate, OSSensorCellDelegate, UITextFieldDelegate, ReaderViewControllerDelegate, UIAlertViewDelegate>
{
    NSTimer *timer;
    BOOL orientationToLandscape; //should set to NO by default
    UIResponder *currentResponder;
    OSSensorCell *editingCell;
    UIButton *btnDelete;
    BOOL refreshPressed;
}

@property (nonatomic, retain) UISwipeGestureRecognizer *rightGesture;
@property (nonatomic, retain) NSMutableArray *arrayProcessingSensors;

@property (nonatomic, retain) NSMutableArray *arrayFilteredSensors;

@end

@implementation OSSensorInventoryTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // right gesture
    /*
    self.rightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRight:)];
    self.rightGesture.delegate = self;
    [self.view addGestureRecognizer:self.rightGesture];
     */
    
    // set background view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];
    [imageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.tableView.backgroundView = imageView;
    
    [OSServerManager sharedInstance].delegate = self;
    
    [self loadData:NO];
    
    // set refresh control
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:kRefreshHintText attributes:@{NSForegroundColorAttributeName:kRefreshTintColor}];
    [refresh addTarget:self action:@selector(refreshMyTable:) forControlEvents:UIControlEventValueChanged];
    refresh.tintColor = kRefreshTintColor;
    self.refreshControl = refresh;
    
    // background view
    self.tableView.backgroundView.layer.zPosition -= 1;
    
    // orientation
    OSAppDelegate *appDelegate = (OSAppDelegate *)([UIApplication sharedApplication].delegate);
    appDelegate.allowRotateToLandscape = YES;
    
    orientationToLandscape = NO;
    //[self performSelector:@selector(changeOrientationToLandscape) withObject:nil afterDelay:0];
    [self changeOrientationToLandscape];
    
#if USE_SEARCHBAR
    [self initSearchBar];
#endif
    
    // gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    // editing
    editingCell = nil;
}

- (void)initSearchBar
{
    // search bar
    [self.searchDisplayController.searchResultsTableView registerClass:[OSSensorCell class] forCellReuseIdentifier:@"sensorcell"];
    self.arrayFilteredSensors = [[NSMutableArray alloc] init];
    // search table background
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];
    [imageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.searchDisplayController.searchResultsTableView.backgroundView = imageView;
    
    // search bar background
    //[self.searchDisplayController.searchBar setBackgroundColor:[UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:0.8]];
    [self.searchDisplayController.searchBar setBackgroundImage:[UIImage imageNamed:@"Background"]];
    [self.searchDisplayController.searchBar setTintColor:[UIColor whiteColor]];
    
    // search bar text color
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor colorWithRed:151/255.0 green:151/255.0 blue:151/255.0 alpha:1.0]];
    
    [self.searchDisplayController.searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
}

- (void)loadData:(BOOL)bRefreshData
{
    refreshPressed = bRefreshData;
    
    // load array
    self.arrayProcessingSensors = [[NSMutableArray alloc] init];
    NSMutableArray *arraySensors = [[OSModelManager sharedInstance] retrieveSensors];
    for (CDSensor *s in arraySensors) {
        if ([s.deletedInv boolValue])
            continue;
        OSProcessingSensor *sensor = [[OSProcessingSensor alloc] init];
        sensor.ssn = s.ssn;
        sensor.retrievedCalibrationDate = NO;
        sensor.retrievedLatestCalCheck = NO;
        sensor.retrievedFirstCalCheck = NO;
        sensor.isShownName = YES;
        
        [self.arrayProcessingSensors addObject:sensor];
    }
    
    for (OSProcessingSensor *sensor in self.arrayProcessingSensors) {
        NSString *ssn = sensor.ssn;
        
        // retrieve data
        if (bRefreshData)
        {
            [[OSServerManager sharedInstance] retrieveCalCheckForSensor:ssn first:NO];
            [[OSServerManager sharedInstance] retrieveCalCheckForSensor:ssn first:YES];
            [[OSServerManager sharedInstance] retrieveCalibrationDateForSensor:ssn];
        }
        else
        {
            // check is existing
            CDCalCheck *firstCalCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:ssn];
            if (!firstCalCheck)
                [[OSServerManager sharedInstance] retrieveCalCheckForSensor:ssn first:YES];
            else
                sensor.retrievedFirstCalCheck = YES;
            
            CDCalCheck *lastCalCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:ssn];
            
            // check dummy one
            if (lastCalCheck != nil && [[OSSaltSolutionManager sharedInstance] isDefaultSolution:lastCalCheck.salt_name])
                lastCalCheck = nil;
            
            if (!lastCalCheck)
                [[OSServerManager sharedInstance] retrieveCalCheckForSensor:ssn first:NO];
            else
                sensor.retrievedLatestCalCheck = YES;
            
            CDCalibrationDate *cdCalibrationDate = [[OSModelManager sharedInstance] getCalibrationDateForSensor:ssn];
            if (!cdCalibrationDate)
                [[OSServerManager sharedInstance] retrieveCalibrationDateForSensor:ssn];
            else
                sensor.retrievedCalibrationDate = YES;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
    
    // orientation
    OSAppDelegate *appDelegate = (OSAppDelegate *)([UIApplication sharedApplication].delegate);
    appDelegate.allowRotateToLandscape = NO;
    
    // keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
#if USE_SEARCHBAR
    [self performSelector:@selector(hideSearchBar) withObject:nil afterDelay:0];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShowing:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHiding:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)hideSearchBar
{
    self.tableView.contentOffset = CGPointMake(0, 0);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHeightForSection;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewCell *sectionHeader = [self.tableView dequeueReusableCellWithIdentifier:@"sectionheader"];
    btnDelete = (UIButton *)[sectionHeader viewWithTag:100];
    [btnDelete removeTarget:self action:@selector(onDeleteSelectedCells:) forControlEvents:UIControlEventTouchUpInside];
    [btnDelete addTarget:self action:@selector(onDeleteSelectedCells:) forControlEvents:UIControlEventTouchUpInside];
    
    [self refreshDeleteButton];
    
    return sectionHeader;
}

static OSSensorCell *_prototypeSensorCell = nil;
- (OSSensorCell *)prototypeSensorCell
{
    if (_prototypeSensorCell == nil)
        _prototypeSensorCell = [self.tableView dequeueReusableCellWithIdentifier:@"sensorcell"];
    return _prototypeSensorCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self prototypeSensorCell].bounds.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView)
        return self.arrayProcessingSensors.count;
    else if (tableView == self.searchDisplayController.searchResultsTableView)
        return self.arrayFilteredSensors.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"sensorcell";
    OSSensorCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    OSProcessingSensor *sensor = [self.arrayProcessingSensors objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell bind:sensor.ssn isShownName:sensor.isShownName isSelected:sensor.isSelected];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - gesture recognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

//- (void)onSwipeRight:(id)sender
//{
//    [self onBack:sender];
//}

- (IBAction)onBack:(id)sender
{
    //[self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onReport:(id)sender
{
    if (self.arrayProcessingSensors.count == 0)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"There is no sensors for report" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    // report
    NSMutableArray *arraySsn = [[NSMutableArray alloc] init];
    for (OSProcessingSensor *sensor in self.arrayProcessingSensors) {
        [arraySsn addObject:sensor.ssn];
    }
    NSString *pdfFullPath = [[OSReportManager sharedInstance] createPdfForSensors:arraySsn];
    
    if (pdfFullPath == nil)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Creating pdf file failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];

        return;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:pdfFullPath]) {
        ReaderDocument *document = [ReaderDocument withDocumentFilePath:pdfFullPath password:nil];
        
        if (document) {
            ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
            readerViewController.delegate = self;
            readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:readerViewController animated:YES completion:nil];
        }
    }
}

- (void)checkEndRefresh
{
    BOOL bEnd = YES;
    for (OSProcessingSensor *s in self.arrayProcessingSensors) {
        if (s.retrievedCalibrationDate && s.retrievedLatestCalCheck && s.retrievedFirstCalCheck)
        {
            //
        }
        else
        {
            bEnd = NO;
            break;
        }
    }
    
    if (bEnd)
        [self endRefresh];
}

#pragma mark - ServerManagerDelegate
- (OSProcessingSensor *)findProcessingSensor:(NSString *)ssn
{
    OSProcessingSensor *sensor = nil;
    for (OSProcessingSensor *s in self.arrayProcessingSensors) {
        if ([s.ssn isEqualToString:ssn])
        {
            sensor = s;
            break;
        }
    }
    return sensor;
}

- (void)didRetrieveCalibrationDate:(NSString *)ssn success:(BOOL)success
{
    dispatch_async(dispatch_get_main_queue(), ^() {
        OSProcessingSensor *sensor = nil;
        for (OSProcessingSensor *s in self.arrayProcessingSensors) {
            if ([s.ssn isEqualToString:ssn])
            {
                sensor = s;
                break;
            }
        }
        
        if (sensor)
            sensor.retrievedCalibrationDate = YES;
        
        [self checkEndRefresh];
        
        [self.tableView reloadData];
    });
}

- (void)didRetrieveCalCheck:(NSString *)ssn success:(BOOL)success first:(BOOL)first
{
    dispatch_async(dispatch_get_main_queue(), ^() {
        OSProcessingSensor *sensor = nil;
        for (OSProcessingSensor *s in self.arrayProcessingSensors) {
            if ([s.ssn isEqualToString:ssn])
            {
                sensor = s;
                break;
            }
        }
        
        BOOL shouldBeRemoved = NO;
        if (sensor)
        {
            if (first) {
                sensor.retrievedFirstCalCheck = YES;
                
                // check "inactive" salt solution
                CDCalCheck *calCheck = [[OSModelManager sharedInstance] getFirstCalCheckForSensor:ssn];
                
                [[OSModelManager sharedInstance] printCalCheckForSensor:ssn];
                
                if (calCheck != nil) {
                    if ([[OSSaltSolutionManager sharedInstance] isInactiveSolution:calCheck.salt_name]) {
                        shouldBeRemoved = YES;
                    }
                }
            }
            else {
                sensor.retrievedLatestCalCheck = YES;
                
                // check "inactive" salt solution
                CDCalCheck *calCheck = [[OSModelManager sharedInstance] getLatestCalCheckForSensor:ssn];
                
                [[OSModelManager sharedInstance] printCalCheckForSensor:ssn];
                
                if (calCheck != nil) {
                    if ([[OSSaltSolutionManager sharedInstance] isInactiveSolution:calCheck.salt_name]) {
                        shouldBeRemoved = YES;
                    }
                }
            }
        }
        
        // when refreshing manually, check "inactive" and remove
        //if (refreshPressed) {
            
            if (shouldBeRemoved) {
                // remove from db
                CDSensor *s = [[OSModelManager sharedInstance] getSensorForSerial:sensor.ssn];
                [[OSModelManager sharedInstance] removeSensorFromInventory:s];
                
                // remove from array
                [self.arrayProcessingSensors removeObject:sensor];
            }
        //}
        
        [self checkEndRefresh];
        
        [self.tableView reloadData];
    });
}

#pragma mark - cell delegate
- (BOOL)retrievedData:(OSSensorCell *)cell
{
    OSProcessingSensor *sensor = nil;
    for (OSProcessingSensor *s in self.arrayProcessingSensors) {
        if ([s.ssn isEqualToString:cell.ssn])
        {
            sensor = s;
            break;
        }
    }
    
    if (!sensor)
        return YES;
    
    if (sensor.retrievedCalibrationDate && sensor.retrievedLatestCalCheck && sensor.retrievedFirstCalCheck)
        return YES;
    return NO;
}

- (void)didBeginEditingCell:(OSSensorCell *)cell
{
    editingCell = cell;
}

- (void)didEndEditingCell:(OSSensorCell *)cell
{
    editingCell = nil;
}

- (void)didShownName:(OSSensorCell *)cell
{
    OSProcessingSensor *sensor = [self findProcessingSensor:cell.ssn];
    if (sensor)
        sensor.isShownName = YES;
}

- (void)didShownSerial:(OSSensorCell *)cell
{
    OSProcessingSensor *sensor = [self findProcessingSensor:cell.ssn];
    if (sensor)
        sensor.isShownName = NO;
}

- (void)didDeleteCell:(OSSensorCell *)cell
{
    OSProcessingSensor *sensor = [self findProcessingSensor:cell.ssn];
    if (sensor) {
        // remove sensor from array
        [self.arrayProcessingSensors removeObject:sensor];
        
        // remove sensor on db
        CDSensor *s = [[OSModelManager sharedInstance] getSensorForSerial:sensor.ssn];
        [[OSModelManager sharedInstance] removeSensorFromInventory:s];
        
        // update table
        [self.tableView beginUpdates];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath)
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void)didSelectCell:(OSSensorCell *)cell isSelected:(BOOL)isSelected
{
    OSProcessingSensor *sensor = [self findProcessingSensor:cell.ssn];
    if (sensor) {
        // change selected
        sensor.isSelected = isSelected;
    }
    
    [self refreshDeleteButton];
}

- (void)refreshDeleteButton
{
    int count = 0;
    for (OSProcessingSensor *s in self.arrayProcessingSensors) {
        if (s.isSelected)
            count++;
    }
    
    if (btnDelete == nil)
        return;
    
    if (count > 0)
        btnDelete.enabled = YES;
    else
        btnDelete.enabled = NO;
}

- (IBAction)onDeleteSelectedCells:(id)sender
{
    OSProcessingSensor *oneSensor = nil;
    int nSelected = 0;
    for (int i = 0; i < self.arrayProcessingSensors.count; i++) {
        OSProcessingSensor *sensor = [self.arrayProcessingSensors objectAtIndex:i];
        if (!sensor.isSelected)
            continue;
        
        nSelected++;
        oneSensor = sensor;
    }
    
    if (nSelected > 0)
    {
        NSString *msg;
        if (nSelected == 1)
        {
            NSString *strSensor = @"";
            if (oneSensor)
            {
                CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:oneSensor.ssn];
                if (sensor.name != nil && sensor.name.length > 0)
                    strSensor = sensor.name;
                else
                    strSensor = sensor.ssn;
            }
            msg = [NSString stringWithFormat:@"Selected sensor \"%@\"! \nPlease confirm to delete.", strSensor];
        }
        else
            msg = [NSString stringWithFormat:@"Selected %d sensors! \nPlease confirm to delete.", nSelected];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm" message:msg delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alertView show];
    }

}

#pragma mark - uialertview delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) //yes
    {
        NSMutableArray *indexPathArray = [[NSMutableArray alloc] init];
        NSMutableArray *removeSensors = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.arrayProcessingSensors.count; i++) {
            OSProcessingSensor *sensor = [self.arrayProcessingSensors objectAtIndex:i];
            if (!sensor.isSelected)
                continue;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [indexPathArray addObject:indexPath];
            [removeSensors addObject:sensor];
        }
        
        if (indexPathArray.count > 0)
        {
            // delete sensors from array / db
            for (OSProcessingSensor *sensor in removeSensors) {
                [self.arrayProcessingSensors removeObject:sensor];
                CDSensor *s = [[OSModelManager sharedInstance] getSensorForSerial:sensor.ssn];
                [[OSModelManager sharedInstance] removeSensorFromInventory:s];
            }
            
            // delete a cell for sensor
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    }
}


#pragma mark - refreshing
- (void)refreshMyTable:(UIRefreshControl *)refreshControl
{
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:kRefreshProcessingText attributes:@{NSForegroundColorAttributeName:kRefreshTintColor}];
    
    [self loadData:YES];
    [self.tableView reloadData];
    
    [self checkEndRefresh];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(onTimer:) userInfo:Nil repeats:NO];
}

- (void)onTimer:(id)sender
{
    timer = nil;
    [self endRefresh];
}

- (void)endRefresh
{
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:kRefreshHintText attributes:@{NSForegroundColorAttributeName:kRefreshTintColor}];
    [self.refreshControl endRefreshing];
}

#pragma mark - interface orientation
- (BOOL)shouldAutorotate
{
    return !orientationToLandscape;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if(orientationToLandscape)
    {
        //when we manually changed, show in Landscape
        return UIInterfaceOrientationLandscapeLeft;
    }
    else
    {
        //before manual orientation change, we allow any orientation
        return self.interfaceOrientation;
    }
}

-(void) changeOrientationToLandscape
{
    //Sample method to change the orientation
    //when called, will show (and hide) the temporary view
    //Original.preferredInterfaceOrientationForPresentation will be called again after this method
    
    //flag this to ensure that we tell system we prefer Portrait, whenever it asked again
    orientationToLandscape = YES;
    
#if 0
    //presenting the following VC will cause the orientation to temporary change
    //when the new VC is dismissed, system will ask what is our (Original) orientation preference again
    ForceLandscape* forceLandscape = [[ForceLandscape alloc] init];
    forceLandscape.view = [[UIView alloc] init];
    forceLandscape.view.backgroundColor = [UIColor clearColor];
    [self presentViewController:forceLandscape animated:NO completion:^{
        [self performSelector:@selector(closeForceLandscape:) withObject:forceLandscape afterDelay:0];
    }];
#else
    OSDummyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OSDummyViewController"];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:NO completion:^{
        [self performSelector:@selector(closeForceLandscape:) withObject:vc afterDelay:0];
    }];
#endif
}

- (void)closeForceLandscape:(UIViewController *)forceLandscape
{
    [forceLandscape dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark Keyboard Methods

- (void)keyboardShowing:(NSNotification *)note
{
    //[keyboardStrategy doKeyboardWillBeShown:note];
}

- (void)keyboardHiding:(NSNotification *)note
{
    //[keyboardStrategy doKeyboardWillBeHidden:note];
    
    if (editingCell != nil)
        [editingCell endEditing];
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

# pragma mark Gesture selector
- (void)backgroundTap:(UITapGestureRecognizer *)backgroundTap {
    if(currentResponder){
        [currentResponder resignFirstResponder];
    }
}

#pragma mark - ReaderViewControllerDelegate
- (void)dismissReaderViewController:(ReaderViewController *)viewController {
    
    if (viewController) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end