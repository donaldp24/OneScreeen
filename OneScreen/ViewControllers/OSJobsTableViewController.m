//
//  OSJobsTableViewController.m
//  OneScreen
//
//  Created by Xiaoxue Han on 10/19/14.
//  Copyright (c) 2014 wagnermeter. All rights reserved.
//

#import "OSJobsTableViewController.h"
#import "OSJobCell.h"
#import "OSModelManager.h"
#import "OSAppDelegate.h"
#import "OSDummyViewController.h"
#import "OSJobDetailViewController.h"
#import "OSAppContext.h"

#define kHeightForSection       48.0

@interface OSProcessingJob : NSObject

@property (nonatomic, retain) CDJob *job;
@property (nonatomic) BOOL isSelected;
@property (nonatomic) BOOL isNewOne;

@end

@implementation OSProcessingJob
@end


@interface OSJobsTableViewController () <OSJobCellDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
    NSTimer *timer;
    BOOL orientationToLandscape; //should set to NO by default
    UIResponder *currentResponder;
    OSJobCell *editingCell;
    UIButton *btnDelete;
}

@property (nonatomic, retain) UISwipeGestureRecognizer *rightGesture;
@property (nonatomic, retain) NSMutableArray *arrayProcessingJobs;

@end

@implementation OSJobsTableViewController

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
    
    orientationToLandscape = NO;
    [self changeOrientationToLandscape];
       
    // gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    // editing
    editingCell = nil;
}

- (void)loadData
{
    // load array
    self.arrayProcessingJobs = [[NSMutableArray alloc] init];
    NSMutableArray *arrayJobs = [[OSModelManager sharedInstance] retrieveJobs];
    for (CDJob *j in arrayJobs) {
        OSProcessingJob *job = [[OSProcessingJob alloc] init];
        job.job = j;
        job.isSelected = NO;
        job.isNewOne = NO;
        
        [self.arrayProcessingJobs addObject:job];
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

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShowing:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHiding:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
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


static OSJobCell *_prototypeJobCell = nil;
- (OSJobCell *)prototypeJobCell
{
    if (_prototypeJobCell == nil)
        _prototypeJobCell = [self.tableView dequeueReusableCellWithIdentifier:@"jobcell"];
    return _prototypeJobCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self prototypeJobCell].bounds.size.height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.tableView)
        return self.arrayProcessingJobs.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"jobcell";
    OSJobCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    OSProcessingJob *processingJob = [self.arrayProcessingJobs objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell bind:processingJob.job isSelected:processingJob.isSelected isNewOne:processingJob.isNewOne];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSProcessingJob *processingJob = [self.arrayProcessingJobs objectAtIndex:indexPath.row];
    OSJobDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"OSJobDetailViewController"];
    vc.job = processingJob.job;
    [self.navigationController pushViewController:vc animated:YES];
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

- (OSProcessingJob *)findProcessingJob:(CDJob *)job
{
    OSProcessingJob *processingJob = nil;
    for (OSProcessingJob *s in self.arrayProcessingJobs) {
        if (s.job == job)
        {
            processingJob = s;
            break;
        }
    }
    return processingJob;
}


#pragma mark - gesture recognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (currentResponder)
        return YES;
    return NO;
}


- (IBAction)onBack:(id)sender
{
    //[self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPlus:(id)sender
{
    // add a cell
    CDJob *j = [[OSModelManager sharedInstance] createNewJob:@""];
    OSProcessingJob *job = [[OSProcessingJob alloc] init];
    job.job = j;
    job.isSelected = NO;
    job.isNewOne = YES;
    [self.arrayProcessingJobs addObject:job];
   
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.arrayProcessingJobs.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    
    [self performSelector:@selector(scrollToLastRow) withObject:nil afterDelay:0.1];
    
}

- (void)scrollToLastRow
{
    if (self.arrayProcessingJobs.count >= 1)
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.arrayProcessingJobs.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - cell delegate

- (void)didBeginEditingCell:(OSJobCell *)cell
{
    editingCell = cell;
}

- (void)didEndEditingCell:(OSJobCell *)cell
{
    OSProcessingJob *processingJob = [self findProcessingJob:cell.job];
    if (processingJob)
        processingJob.isNewOne = NO;
    editingCell = nil;
}

- (void)didDeleteCell:(OSJobCell *)cell
{
    OSProcessingJob *processingJob = [self findProcessingJob:cell.job];
    if (processingJob) {
        // remove job from array
        [self.arrayProcessingJobs removeObject:processingJob];
        
        // remove job from db
        [[OSModelManager sharedInstance] removeJob:processingJob.job];
        
        [self.tableView beginUpdates];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath)
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (void)didSelectCell:(OSJobCell *)cell isSelected:(BOOL)isSelected
{
    OSProcessingJob *processingJob = [self findProcessingJob:cell.job];
    if (processingJob) {
        // change selected
        processingJob.isSelected = isSelected;
    }
    
    [self refreshDeleteButton];
}

- (void)refreshDeleteButton
{
    int count = 0;
    for (OSProcessingJob *processingJob in self.arrayProcessingJobs) {
        if (processingJob.isSelected)
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
    int nSelected = 0;
    for (int i = 0; i < self.arrayProcessingJobs.count; i++) {
        OSProcessingJob *processingJob = [self.arrayProcessingJobs objectAtIndex:i];
        if (!processingJob.isSelected)
            continue;
        
        nSelected++;
    }
    
    if (nSelected > 0)
    {
        NSString *msg;
        if (nSelected == 1)
            msg = [NSString stringWithFormat:@"Selected %d job! \nPlease confirm to delete.", nSelected];
        else
            msg = [NSString stringWithFormat:@"Selected %d jobs! \nPlease confirm to delete.", nSelected];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Confirm" message:msg delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alertView show];
    }
    
}

- (void)didStartEndJob:(OSJobCell *)cell
{
    if ([OSAppContext sharedInstance].isJobStarted)
    {
        CDJob *currJob = [OSAppContext sharedInstance].currentJob;
        if (cell.job == currJob)
        {
            [OSAppContext sharedInstance].isJobStarted = NO;
            [[OSModelManager sharedInstance] endJob:currJob];
        }
    }
    else
    {
        [OSAppContext sharedInstance].isJobStarted = YES;
        [OSAppContext sharedInstance].currentJob = cell.job;
        [[OSModelManager sharedInstance] startJob:cell.job];
    }
#if 0
    // update that row
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath == nil)
    {
        //
    }
    else
    {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
#else
    [self.tableView reloadData];
#endif
}

- (BOOL)isStarted:(OSJobCell *)cell
{
    if ([OSAppContext sharedInstance].currentJob == cell.job &&
        [OSAppContext sharedInstance].isJobStarted)
        return YES;
    return NO;
}

- (BOOL)isStartable:(OSJobCell *)cell
{
    if (![OSAppContext sharedInstance].isJobStarted)
        return YES;
    return NO;
}


#pragma mark - uialertview delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) //yes
    {
        NSMutableArray *indexPathArray = [[NSMutableArray alloc] init];
        NSMutableArray *removeSensors = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.arrayProcessingJobs.count; i++) {
            OSProcessingJob *processingJob = [self.arrayProcessingJobs objectAtIndex:i];
            if (!processingJob.isSelected)
                continue;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            [indexPathArray addObject:indexPath];
            [removeSensors addObject:processingJob];
        }
        
        if (indexPathArray.count > 0)
        {
            for (OSProcessingJob *processingJob in removeSensors) {
                [self.arrayProcessingJobs removeObject:processingJob];
                
                [[OSModelManager sharedInstance] removeJob:processingJob.job];
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
    
    //[self checkEndRefresh];
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(onTimer:) userInfo:Nil repeats:NO];
    
    [self endRefresh];
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


@end
