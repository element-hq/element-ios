/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */


#import "UsersDevicesViewController.h"

#import "GeneratedInterface-Swift.h"

@interface UsersDevicesViewController () <KeyVerificationCoordinatorBridgePresenterDelegate>
{
    MXUsersDevicesMap<MXDeviceInfo*> *usersDevices;
    MXSession *mxSession;

    void (^onCompleteBlock)(BOOL doneButtonPressed);

    KeyVerificationCoordinatorBridgePresenter *keyVerificationCoordinatorBridgePresenter;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation UsersDevicesViewController

- (void)displayUsersDevices:(MXUsersDevicesMap<MXDeviceInfo*>*)theUsersDevices andMatrixSession:(MXSession*)matrixSession onComplete:(void (^)(BOOL doneButtonPressed))onComplete
{
    usersDevices = theUsersDevices;
    mxSession = matrixSession;
    onCompleteBlock = onComplete;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [VectorL10n unknownDevicesTitle];
    self.accessibilityLabel=@"UsersDevicesVCTitleStaticText";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier=@"UsersDevicesVCDoneButton";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
    self.navigationItem.leftBarButtonItem.accessibilityIdentifier=@"UsersDevicesVCCancelButton";
    self.tableView.delegate = self;
    self.tableView.accessibilityIdentifier=@"UsersDevicesVCDTableView";
    self.tableView.dataSource = self;

    // Register collection view cell class
    [self.tableView registerClass:DeviceTableViewCell.class forCellReuseIdentifier:[DeviceTableViewCell defaultReuseIdentifier]];

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

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return usersDevices.userIds.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return usersDevices.userIds[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *userId = usersDevices.userIds[section];
    return [usersDevices deviceIdsForUser:userId].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;

    MXDeviceInfo *device = [self deviceAtIndexPath:indexPath];
    if (device)
    {
        DeviceTableViewCell *deviceCell = [tableView dequeueReusableCellWithIdentifier:[DeviceTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
        deviceCell.selectionStyle = UITableViewCellSelectionStyleNone;

        [deviceCell render:device];
        deviceCell.delegate = self;

        cell = deviceCell;
    }
    else
    {
        // Return a fake cell to prevent app from crashing.
        cell = [[UITableViewCell alloc] init];
    }

    return cell;
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
    MXDeviceInfo *device = [self deviceAtIndexPath:indexPath];

    return [DeviceTableViewCell cellHeightWithDeviceInfo:device andCellWidth:self.tableView.frame.size.width];
}

#pragma mark - DeviceTableViewCellDelegate

- (void)deviceTableViewCell:(DeviceTableViewCell *)deviceTableViewCell updateDeviceVerification:(MXDeviceVerification)verificationStatus
{
    if (verificationStatus == MXDeviceVerified)
    {
        // Prompt the user before marking as verified the device.
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;

        [keyVerificationCoordinatorBridgePresenter presentFrom:self otherUserId:deviceTableViewCell.deviceInfo.userId otherDeviceId:deviceTableViewCell.deviceInfo.deviceId animated:YES];
    }
    else
    {
        [mxSession.crypto setDeviceVerification:verificationStatus
                                      forDevice:deviceTableViewCell.deviceInfo.deviceId
                                         ofUser:deviceTableViewCell.deviceInfo.userId
                                        success:^{
                                            [self reloadDataforUser:deviceTableViewCell.deviceInfo.userId andDevice:deviceTableViewCell.deviceInfo.deviceId];
                                        } failure:nil];
    }
}

- (void)reloadDataforUser:(NSString *)userId andDevice:(NSString *)deviceId
{
    // Refresh data
    MXDeviceInfo *device = [mxSession.crypto deviceWithDeviceId:deviceId ofUser:userId];
    [usersDevices setObject:device forUser:userId andDevice:deviceId];

    // and reload
    [self.tableView reloadData];
}

#pragma mark - DeviceVerificationCoordinatorBridgePresenterDelegate

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    // Update our map
    [mxSession.crypto downloadKeys:@[otherUserId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {
        
        [self reloadDataforUser:otherUserId andDevice:otherDeviceId];
        
    } failure:^(NSError *error) {
        // Should not happen (the device is in the crypto db)
    }];
    
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidCancel:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)dismissKeyVerificationCoordinatorBridgePresenter
{
    [keyVerificationCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    keyVerificationCoordinatorBridgePresenter = nil;
}


#pragma mark - User actions

- (IBAction)onDone:(id)sender
{
    // Acknowledge the existence of all devices before leaving this screen
    [self dismissViewControllerAnimated:YES completion:nil];

    if (self->onCompleteBlock)
    {
        self->onCompleteBlock(YES);
    }
}

- (IBAction)onCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];

    if (onCompleteBlock)
    {
        onCompleteBlock(NO);
    }
}

#pragma mark - Private methods

- (MXDeviceInfo*)deviceAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *userId = usersDevices.userIds[indexPath.section];
    NSString *deviceId = [usersDevices deviceIdsForUser:userId][indexPath.row];

    return [usersDevices objectForDevice:deviceId forUser:userId];
}

@end
