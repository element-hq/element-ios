/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DirectoryServerPickerViewController.h"
#import "DirectoryServerTableViewCell.h"
#import "DirectoryServerDetailTableViewCell.h"

#import "GeneratedInterface-Swift.h"

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
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@end

@implementation DirectoryServerPickerViewController

- (void)finalizeInit
{
    [super finalizeInit];

    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenSwitchDirectory];
}

- (void)destroy
{
    dataSource.delegate = nil;
    dataSource = nil;
    onCompleteBlock = nil;
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
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

    self.title = [VectorL10n directoryServerPickerTitle];

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
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        [self.tableView setContentOffset:CGPointMake(-self.tableView.adjustedContentInset.left, -self.tableView.adjustedContentInset.top) animated:YES];

    }];

    [dataSource loadData];
    [self.screenTracker trackScreen];
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
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
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
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:[VectorL10n directoryServerTypeHomeserver] preferredStyle:UIAlertControllerStyleAlert];

    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {

        textField.secureTextEntry = NO;
        textField.placeholder = [VectorL10n directoryServerPlaceholder];
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           
                                                           NSString *text = [self->currentAlert textFields].firstObject.text;
                                                           
                                                           self->currentAlert = nil;
                                                           
                                                           NSString *homeserver = text;
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
