//
//  OSJobDetailViewController.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/19/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSJobDetailViewController.h"
#import "OSReadingCell.h"
#import "OSAppDelegate.h"
#import "OSModelManager.h"
#import "ReaderViewController.h"
#import "OSDummyViewController.h"
#import "OSReportManager.h"

#define kHeightForSection       48.0


@interface OSProcessingReading : NSObject

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic, retain) CDReading *reading;
@property (nonatomic) BOOL isShownName;
@property (nonatomic) BOOL isSelected;

@end

@implementation OSProcessingReading
@end

@interface OSJobDetailViewController () <UIAlertViewDelegate, OSReadingCellDelegate, UIGestureRecognizerDelegate, ReaderViewControllerDelegate>
{
    NSTimer *timer;
    BOOL orientationToLandscape; //should set to NO by default
    UIResponder *currentResponder;
    UIButton *btnDelete;
}

@property (nonatomic, retain) UISwipeGestureRecognizer *rightGesture;
@property (nonatomic, retain) NSMutableArray *arrayProcessingReadings;

@end

@implementation OSJobDetailViewController

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
    
    // set background view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];
    [imageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.tableView.backgroundView = imageView;
    
    [self loadData];
    
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
    
    //orientationToLandscape = NO;
    //[self changeOrientationToLandscape];
    
    
    // gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
}


- (void)loadData
{
    // load array
    self.arrayProcessingReadings = [[NSMutableArray alloc] init];
    NSMutableArray *arraySensors = [[OSModelManager sharedInstance] getSensorSerialsForJob:self.job.uid];
    for (NSString *ssn in arraySensors) {
        OSProcessingReading *reading = [[OSProcessingReading alloc] init];
        reading .ssn = ssn;
        reading.reading = [[OSModelManager sharedInstance] getLastReadingForSensor:ssn ofJob:self.job.uid];
        reading.isShownName = YES;
        [self.arrayProcessingReadings addObject:reading];
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

static OSReadingCell *_prototypeReadingCell = nil;
- (OSReadingCell *)prototypeReadingCell
{
    if (_prototypeReadingCell == nil)
        _prototypeReadingCell = [self.tableView dequeueReusableCellWithIdentifier:@"readingcell"];
    return _prototypeReadingCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self prototypeReadingCell].bounds.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView)
        return self.arrayProcessingReadings.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"readingcell";
    OSReadingCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    OSProcessingReading *processingReading = [self.arrayProcessingReadings objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell bind:processingReading.reading isShownName:processingReading.isShownName isSelected:processingReading.isSelected];
    
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
    if (self.arrayProcessingReadings.count == 0)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"There is no data for report" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
    }

    // report
    NSString *pdfFullPath = [[OSReportManager sharedInstance] createPdfForJob:self.job.uid];
    
    if (pdfFullPath == nil)
        return;
    
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

#pragma mark - ServerManagerDelegate
- (OSProcessingReading *)findProcessingReading:(NSString *)ssn
{
    OSProcessingReading *reading = nil;
    for (OSProcessingReading *s in self.arrayProcessingReadings) {
        if ([s.ssn isEqualToString:ssn])
        {
            reading = s;
            break;
        }
    }
    return reading;
}

#pragma mark - cell delegate

- (void)didShownName:(OSReadingCell *)cell
{
    OSProcessingReading *sensor = [self findProcessingReading:cell.reading.ssn];
    if (sensor)
        sensor.isShownName = YES;
}

- (void)didShownSerial:(OSReadingCell *)cell
{
    OSProcessingReading *reading = [self findProcessingReading:cell.reading.ssn];
    if (reading)
        reading.isShownName = NO;
}

- (void)didDeleteCell:(OSReadingCell *)cell
{
    OSProcessingReading *processingReading = [self findProcessingReading:cell.reading.ssn];
    if (processingReading) {
        // remove sensor
        [self.arrayProcessingReadings removeObject:processingReading];
        
        [self.tableView beginUpdates];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath)
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void)didSelectCell:(OSReadingCell *)cell isSelected:(BOOL)isSelected
{
    OSProcessingReading *processingReading = [self findProcessingReading:cell.reading.ssn];
    if (processingReading) {
        // change selected
        processingReading.isSelected = isSelected;
    }
    
    [self refreshDeleteButton];
}

- (void)refreshDeleteButton
{
    int count = 0;
    for (OSProcessingReading *s in self.arrayProcessingReadings) {
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
    OSProcessingReading *oneReading = nil;
    int nSelected = 0;
    for (int i = 0; i < self.arrayProcessingReadings.count; i++) {
        OSProcessingReading *processingReading = [self.arrayProcessingReadings objectAtIndex:i];
        if (!processingReading.isSelected)
            continue;
        
        nSelected++;
        oneReading = processingReading;
    }
    
    if (nSelected > 0)
    {
        NSString *msg;
        if (nSelected == 1)
        {
            NSString *strSensor = @"";
            if (oneReading)
            {
                CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:oneReading.ssn];
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
        for (int i = 0; i < self.arrayProcessingReadings.count; i++) {
            OSProcessingReading *processingReading = [self.arrayProcessingReadings objectAtIndex:i];
            if (!processingReading.isSelected)
                continue;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [indexPathArray addObject:indexPath];
            [removeSensors addObject:processingReading];
        }
        
        if (indexPathArray.count > 0)
        {
            for (OSProcessingReading *processingReading in removeSensors) {
                [self.arrayProcessingReadings removeObject:processingReading];
                
                CDSensor *sensor = [[OSModelManager sharedInstance] getSensorForSerial:processingReading.ssn];
                
                if (sensor)
                    [[OSModelManager sharedInstance] removeSensorFromJob:self.job sensor:sensor];
            }
            
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
    
    [self loadData];
    [self.tableView reloadData];
    
    [self endRefresh];
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(onTimer:) userInfo:Nil repeats:NO];
}

- (void)onTimer:(id)sender
{
    //timer = nil;
    //[self endRefresh];
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
