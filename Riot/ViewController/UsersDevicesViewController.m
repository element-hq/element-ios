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


#import "UsersDevicesViewController.h"

#import "AppDelegate.h"

@interface UsersDevicesViewController ()
{
    MXUsersDevicesMap<MXDeviceInfo*> *usersDevices;
    MXSession *mxSession;

    void (^onCompleteBlock)(BOOL doneButtonPressed);
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
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

    self.title = NSLocalizedStringFromTable(@"unknown_devices_title", @"Vector", nil);
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

- (void)destroy
{
    [super destroy];
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"UnknowDevices"];

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
    MXDeviceInfo *device = [self deviceAtIndexPath:indexPath];

    return [DeviceTableViewCell cellHeightWithDeviceInfo:device andCellWidth:self.tableView.frame.size.width];
}

#pragma mark - DeviceTableViewCellDelegate

- (void)deviceTableViewCell:(DeviceTableViewCell *)deviceTableViewCell updateDeviceVerification:(MXDeviceVerification)verificationStatus
{
    if (verificationStatus == MXDeviceVerified)
    {
        // Prompt the user before marking as verified the device.
        EncryptionInfoView *encryptionInfoView = [[EncryptionInfoView alloc] initWithDeviceInfo:deviceTableViewCell.deviceInfo andMatrixSession:mxSession];
        [encryptionInfoView onButtonPressed:encryptionInfoView.verifyButton];

        encryptionInfoView.delegate = self;

        // Add shadow on added view
        encryptionInfoView.layer.cornerRadius = 5;
        encryptionInfoView.layer.shadowOffset = CGSizeMake(0, 1);
        encryptionInfoView.layer.shadowOpacity = 0.5f;

        // Add the view and define edge constraints
        [self.view addSubview:encryptionInfoView];

        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.topLayoutGuide
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0f
                                                               constant:10.0f]];

        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:encryptionInfoView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.bottomLayoutGuide
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0f
                                                               constant:-10.0f]];

        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:encryptionInfoView
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0f
                                                               constant:-10.0f]];

        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:encryptionInfoView
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0f
                                                               constant:10.0f]];
        [self.view setNeedsUpdateConstraints];
    }
    else
    {
        [mxSession.crypto setDeviceVerification:verificationStatus
                                      forDevice:deviceTableViewCell.deviceInfo.deviceId
                                         ofUser:deviceTableViewCell.deviceInfo.userId
                                        success:^{

                                            deviceTableViewCell.deviceInfo.verified = verificationStatus;
                                            [self.tableView reloadData];

                                        } failure:nil];
    }
}

#pragma mark - MXKEncryptionInfoViewDelegate

- (void)encryptionInfoView:(MXKEncryptionInfoView *)encryptionInfoView didDeviceInfoVerifiedChange:(MXDeviceInfo *)deviceInfo
{
    // Update our map
    MXDeviceInfo *device = [usersDevices objectForDevice:deviceInfo.deviceId forUser:deviceInfo.userId];
    device.verified = deviceInfo.verified;

    [self.tableView reloadData];
}

#pragma mark - User actions

- (IBAction)onDone:(id)sender
{
    // Acknowledge the existence of all devices before leaving this screen
    [self startActivityIndicator];
    [mxSession.crypto setDevicesKnown:usersDevices complete:^{

        [self stopActivityIndicator];
        [self dismissViewControllerAnimated:YES completion:nil];

        if (onCompleteBlock)
        {
            onCompleteBlock(YES);
        }
    }];
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
