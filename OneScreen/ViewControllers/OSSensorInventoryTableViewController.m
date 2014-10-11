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

#define kHeightForSection       48.0

#define kRefreshHintText        @"Pull to refresh"
#define kRefreshTintColor       [UIColor colorWithWhite:1 alpha:1]
#define kRefreshProcessingText  @"Updating..."

@interface OSProcessingSensor : NSObject

@property (nonatomic, retain) NSString *ssn;
@property (nonatomic) BOOL retrievedLatestCalCheck;
@property (nonatomic) BOOL retrievedOldestCalCheck;
@property (nonatomic) BOOL retrievedCalibrationDate;

@end


@implementation OSProcessingSensor

//

@end

@interface OSSensorInventoryTableViewController () <UIGestureRecognizerDelegate, OSServerManagerDelegate, OSSensorCellDelegate>
{
    NSTimer *timer;
}

@property (nonatomic, retain) UISwipeGestureRecognizer *rightGesture;
@property (nonatomic, retain) NSMutableArray *arrayProcessingSensors;

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
    self.rightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeRight:)];
    self.rightGesture.delegate = self;
    [self.view addGestureRecognizer:self.rightGesture];
    
    // set background view
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background"]];
    [imageView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.tableView.backgroundView = imageView;
    
    [OSServerManager sharedInstance].delegate = self;
    
    [self loadData];
    
    // set refresh control
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:kRefreshHintText attributes:@{NSForegroundColorAttributeName:kRefreshTintColor}];
    [refresh addTarget:self action:@selector(refreshMyTable:) forControlEvents:UIControlEventValueChanged];
    refresh.tintColor = kRefreshTintColor;
    self.refreshControl = refresh;
    
    // background view
    self.tableView.backgroundView.layer.zPosition -= 1;

}

- (void)loadData
{
    // load array
    self.arrayProcessingSensors = [[NSMutableArray alloc] init];
    NSMutableArray *arraySensors = [[OSModelManager sharedInstance] retrieveSensors];
    for (NSString *ssn in arraySensors) {
        OSProcessingSensor *sensor = [[OSProcessingSensor alloc] init];
        sensor.ssn = ssn;
        sensor.retrievedCalibrationDate = NO;
        sensor.retrievedLatestCalCheck = NO;
        sensor.retrievedOldestCalCheck = NO;
        
        [self.arrayProcessingSensors addObject:sensor];
    }
    
    for (OSProcessingSensor *sensor in self.arrayProcessingSensors) {
        NSString *ssn = sensor.ssn;
        
        // retrieve data
        [[OSServerManager sharedInstance] retrieveCalCheckForSensor:ssn oldest:NO];
        [[OSServerManager sharedInstance] retrieveCalCheckForSensor:ssn oldest:YES];
        [[OSServerManager sharedInstance] retrieveCalibrationDateForSensor:ssn];
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
    return sectionHeader;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.arrayProcessingSensors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"sensorcell";
    OSSensorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    OSProcessingSensor *sensor = [self.arrayProcessingSensors objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell setSsn:sensor.ssn];
    
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

- (void)onSwipeRight:(id)sender
{
    [self onBack:sender];
}

- (IBAction)onBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)checkEndRefresh
{
    BOOL bEnd = YES;
    for (OSProcessingSensor *s in self.arrayProcessingSensors) {
        if (s.retrievedCalibrationDate && s.retrievedLatestCalCheck && s.retrievedOldestCalCheck)
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

- (void)didRetrieveCalCheck:(NSString *)ssn success:(BOOL)success oldest:(BOOL)oldest
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
        {
            if (oldest)
                sensor.retrievedOldestCalCheck = YES;
            else
                sensor.retrievedLatestCalCheck = YES;
        }
        
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
    
    if (sensor.retrievedCalibrationDate && sensor.retrievedLatestCalCheck && sensor.retrievedOldestCalCheck)
        return YES;
    return NO;
}

- (void)refreshMyTable:(UIRefreshControl *)refreshControl
{
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:kRefreshProcessingText attributes:@{NSForegroundColorAttributeName:kRefreshTintColor}];
    
    [self loadData];
    [self.tableView reloadData];
    
    [self checkEndRefresh];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(onTimer:) userInfo:Nil repeats:NO];
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

@end
