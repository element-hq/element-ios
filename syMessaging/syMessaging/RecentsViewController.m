/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "RecentsViewController.h"
#import "RoomViewController.h"

#import "AppDelegate.h"
#import "MatrixHandler.h"

@interface RecentsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *roomTitle;
@property (weak, nonatomic) IBOutlet UILabel *lastEventDescription;
@property (weak, nonatomic) IBOutlet UILabel *recentDate;

@end

@implementation RecentsTableViewCell
@end

@interface RecentsViewController ()
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property NSArray *recents;
@end

@implementation RecentsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.roomViewController = (RoomViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    // Add activity indicator
    [self.view addSubview:_activityIndicator];
    _activityIndicator.center = self.view.center;
    [self.view bringSubviewToFront:_activityIndicator];
}

- (void)dealloc {
    self.recents = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh recents table
    [self refresh];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isInitialSyncDone" options:0 context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isInitialSyncDone"];
}

#pragma mark - recents

- (void)refresh {
    [_activityIndicator startAnimating];
    
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    if ([mxHandler isInitialSyncDone] || [mxHandler isLogged] == NO) {
        // Update recents
        if (mxHandler.mxData) {
            self.recents = mxHandler.mxData.recents;
        } else {
            self.recents = nil;
        }
        
        [self.tableView reloadData];
        [_activityIndicator stopAnimating];
    }
}

- (void)insertNewObject:(id)sender {
//    if (!self.recents) {
//        self.recents = [[NSMutableArray alloc] init];
//    }
//    [self.recents insertObject:[NSDate date] atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"isInitialSyncDone" isEqualToString:keyPath])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refresh];
        });
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        MXEvent *mxEvent = self.recents[indexPath.row];
        
        UIViewController *controller;
        if ([[segue destinationViewController] isKindOfClass:[UINavigationController class]]) {
            controller = [[segue destinationViewController] topViewController];
        } else {
            controller = [segue destinationViewController];
        }
        
        if ([controller isKindOfClass:[RoomViewController class]]) {
            [(RoomViewController *)controller setRoomId:mxEvent.room_id];
        }
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.recents.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecentsTableViewCell *cell = (RecentsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"RecentsCell" forIndexPath:indexPath];

    MXEvent *mxEvent = self.recents[indexPath.row];
    MXRoomData *mxRoomData = [[[MatrixHandler sharedHandler] mxData] getRoomData:mxEvent.room_id];
    
    cell.roomTitle.text = [mxRoomData room_id]; // TODO use room display name
    cell.lastEventDescription.text = [mxEvent description];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:mxEvent.ts];
    NSString *dateFormat =  @"MMM dd HH:mm";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:dateFormat];
    cell.recentDate.text = [dateFormatter stringFromDate:date];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [self.recents removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end
