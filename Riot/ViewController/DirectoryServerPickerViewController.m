/*
 Copyright 2017 Vector Creations Ltd

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

#import "DirectoryServerPickerViewController.h"
#import "DirectoryServerTableViewCell.h"

#import "AppDelegate.h"

@interface DirectoryServerPickerViewController ()
{
    MXKDirectoryServersDataSource *dataSource;

    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;

    void (^onCompleteBlock)(MXThirdPartyProtocolInstance *thirdpartyProtocolInstance, NSString *homeserver);
}
@end

@implementation DirectoryServerPickerViewController

- (void)finalizeInit
{
    [super finalizeInit];

    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kRiotNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)destroy
{
    dataSource.delegate = nil;
    dataSource = nil;
    onCompleteBlock = nil;

    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }

    [super destroy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedStringFromTable(@"directory_server_picker_title", @"Vector", nil);

    self.tableView.delegate = self;

    // Register view cell class
    [self.tableView registerClass:DirectoryServerTableViewCell.class forCellReuseIdentifier:DirectoryServerTableViewCell.defaultReuseIdentifier];

    // Add a cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    self.navigationItem.leftBarButtonItem.accessibilityIdentifier=@"DirectoryServerPickerVCCancelButton";

    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"DirectoryServerPicker"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }

    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];

    }];

    [dataSource loadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }

    [super viewWillDisappear:animated];
}

- (void)displayWithDataSource:(MXKDirectoryServersDataSource*)theDataSource
                   onComplete:(void (^)(MXThirdPartyProtocolInstance *thirdpartyProtocolInstance, NSString *homeserver))onComplete;
{
    dataSource = theDataSource;
    onCompleteBlock = onComplete;

    // Let the data source provide cells
    self.tableView.dataSource = dataSource;

    dataSource.delegate = self;
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    return DirectoryServerTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    return DirectoryServerTableViewCell.defaultReuseIdentifier;
}

- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id /* @TODO*/)changes
{
    [self.tableView reloadData];
}

- (void)dataSource:(MXKDataSource*)dataSource2 didStateChange:(MXKDataSourceState)state
{
    if (state == MXKDataSourceStatePreparing)
    {
        [self startActivityIndicator];
    }
    else
    {
        [self stopActivityIndicator];
        [self.tableView reloadData];
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DirectoryServerTableViewCell.cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKDirectoryServerCellDataStoring> cellData = [dataSource cellDataAtIndexPath:indexPath];

    if (onCompleteBlock)
    {
        if (cellData.thirdPartyProtocolInstance)
        {
            onCompleteBlock(cellData.thirdPartyProtocolInstance, nil);
        }
// TODO: Manage adding of homeserver URL
//        else if (cellData.homeserverUrl)
//        {
//            onCompleteBlock(nil, cellData.homeserverUrl);
//        }
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - User actions

- (IBAction)onCancel:(id)sender
{
    if (onCompleteBlock)
    {
        onCompleteBlock(nil, nil);
    }

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
