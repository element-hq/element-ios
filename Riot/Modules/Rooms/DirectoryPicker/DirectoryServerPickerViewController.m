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
#import "DirectoryServerDetailTableViewCell.h"

#import "AppDelegate.h"

@interface DirectoryServerPickerViewController ()
{
    MXKDirectoryServersDataSource *dataSource;

    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;

    void (^onCompleteBlock)(id<MXKDirectoryServerCellDataStoring> cellData);

    // Current alert (if any).
    UIAlertController *currentAlert;

    // Current request in progress.
    MXHTTPOperation *mxCurrentOperation;
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}
@end

@implementation DirectoryServerPickerViewController

- (void)finalizeInit
{
    [super finalizeInit];

    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)destroy
{
    dataSource.delegate = nil;
    dataSource = nil;
    onCompleteBlock = nil;
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }

    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }

    // Close any pending actionsheet
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }

    if (mxCurrentOperation)
    {
        [mxCurrentOperation cancel];
        mxCurrentOperation = nil;
    }

    [super destroy];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedStringFromTable(@"directory_server_picker_title", @"Vector", nil);

    self.tableView.delegate = self;

    // Register view cell classes
    [self.tableView registerClass:DirectoryServerTableViewCell.class forCellReuseIdentifier:DirectoryServerTableViewCell.defaultReuseIdentifier];
    [self.tableView registerClass:DirectoryServerDetailTableViewCell.class forCellReuseIdentifier:DirectoryServerDetailTableViewCell.defaultReuseIdentifier];

    // Add a cancel button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    self.navigationItem.leftBarButtonItem.accessibilityIdentifier = @"DirectoryServerPickerVCCancelButton";

    // Add a + button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd:)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier = @"DirectoryServerPickerVCAddButton";

    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? kRiotPrimaryBgColor : kRiotSecondaryBgColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"DirectoryServerPicker"];

    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        [self.tableView setContentOffset:CGPointMake(-self.tableView.mxk_adjustedContentInset.left, -self.tableView.mxk_adjustedContentInset.top) animated:YES];

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
                   onComplete:(void (^)(id<MXKDirectoryServerCellDataStoring> cellData))onComplete;
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
    id<MXKDirectoryServerCellDataStoring> directoryCellData = (id<MXKDirectoryServerCellDataStoring>)cellData;

    if (directoryCellData.homeserver)
    {
        return DirectoryServerDetailTableViewCell.class;
    }
    return DirectoryServerTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    id<MXKDirectoryServerCellDataStoring> directoryCellData = (id<MXKDirectoryServerCellDataStoring>)cellData;

    if (directoryCellData.homeserver)
    {
        return DirectoryServerDetailTableViewCell.defaultReuseIdentifier;
    }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DirectoryServerTableViewCell.cellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MXKDirectoryServerCellDataStoring> cellData = [dataSource cellDataAtIndexPath:indexPath];

    if (onCompleteBlock)
    {
        onCompleteBlock(cellData);
    }

    [self withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - User actions

- (IBAction)onCancel:(id)sender
{
    if (onCompleteBlock)
    {
        onCompleteBlock(nil);
    }

    [self withdrawViewControllerAnimated:YES completion:nil];
}

- (IBAction)onAdd:(id)sender
{
    __weak typeof(self) weakSelf = self;

    [currentAlert dismissViewControllerAnimated:NO completion:nil];

    // Prompt the user to enter a homeserver
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedStringFromTable(@"directory_server_type_homeserver", @"Vector", nil) preferredStyle:UIAlertControllerStyleAlert];

    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {

        textField.secureTextEntry = NO;
        textField.placeholder = NSLocalizedStringFromTable(@"directory_server_placeholder", @"Vector", nil);
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           
                                                           UITextField *textField = [self->currentAlert textFields].firstObject;
                                                           
                                                           self->currentAlert = nil;
                                                           
                                                           NSString *homeserver = textField.text;
                                                           if (homeserver.length)
                                                           {
                                                               // Test if the homeserver exists
                                                               [self.activityIndicator startAnimating];
                                                               
                                                               self->mxCurrentOperation = [self->dataSource.mxSession.matrixRestClient publicRoomsOnServer:homeserver limit:20 since:nil filter:nil thirdPartyInstanceId:nil includeAllNetworks:YES success:^(MXPublicRoomsResponse *publicRoomsResponse) {
                                                                   
                                                                   if (weakSelf && self->mxCurrentOperation)
                                                                   {
                                                                       // The homeserver is valid
                                                                       self->mxCurrentOperation = nil;
                                                                       [self.activityIndicator stopAnimating];
                                                                       
                                                                       if (self->onCompleteBlock)
                                                                       {
                                                                           // Prepare response argument
                                                                           MXKDirectoryServerCellData *cellData = [[MXKDirectoryServerCellData alloc] initWithHomeserver:homeserver includeAllNetworks:YES];
                                                                           
                                                                           self->onCompleteBlock(cellData);
                                                                       }
                                                                       
                                                                       [self withdrawViewControllerAnimated:YES completion:nil];
                                                                   }
                                                                   
                                                               } failure:^(NSError *error) {
                                                                   
                                                                   if (weakSelf && self->mxCurrentOperation)
                                                                   {
                                                                       // The homeserver is not valid
                                                                       self->mxCurrentOperation = nil;
                                                                       [self.activityIndicator stopAnimating];
                                                                       
                                                                       [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                   }
                                                                   
                                                               }];
                                                           }
                                                       }
                                                       
                                                   }]];

    [self presentViewController:currentAlert animated:YES completion:nil];
}

@end
