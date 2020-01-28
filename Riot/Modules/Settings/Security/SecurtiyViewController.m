/*
 Copyright 2020 New Vector Ltd
 
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

#import "SecurityViewController.h"

#import <MatrixKit/MatrixKit.h>

#import <OLMKit/OLMKit.h>

#import "AppDelegate.h"
#import "AvatarGenerator.h"

#import "ThemeService.h"

#import "Riot-Swift.h"


enum
{
    SETTINGS_SECTION_DEVICES_INDEX,
    SETTINGS_SECTION_CRYPTOGRAPHY_INDEX,
    SETTINGS_SECTION_KEYBACKUP_INDEX,
    SETTINGS_SECTION_COUNT
};

enum {
    CRYPTOGRAPHY_INFO_INDEX = 0,
    CRYPTOGRAPHY_BLACKLIST_UNVERIFIED_DEVICES_INDEX,
    CRYPTOGRAPHY_EXPORT_INDEX,
    CRYPTOGRAPHY_COUNT
};

enum
{
    DEVICES_DESCRIPTION_INDEX = 0
};


@interface SecurityViewController () <
MXKDataSourceDelegate,
MXKDeviceViewDelegate,
SettingsKeyBackupTableViewSectionDelegate,
MXKEncryptionInfoViewDelegate,
KeyBackupSetupCoordinatorBridgePresenterDelegate,
KeyBackupRecoverCoordinatorBridgePresenterDelegate,
UIDocumentInteractionControllerDelegate>
{
    // Current alert (if any).
    UIAlertController *currentAlert;

    // Devices
    NSMutableArray<MXDevice *> *devicesArray;
    DeviceView *deviceView;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;

    // The view used to export e2e keys
    MXKEncryptionKeysExportView *exportView;

    // The document interaction Controller used to export e2e keys
    UIDocumentInteractionController *documentInteractionController;
    NSURL *keyExportsFile;
    NSTimer *keyExportsFileDeletionTimer;
    
    // The current pushed view controller
    UIViewController *pushedViewController;

    SettingsKeyBackupTableViewSection *keyBackupSection;
    KeyBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter;
    KeyBackupRecoverCoordinatorBridgePresenter *keyBackupRecoverCoordinatorBridgePresenter;
}

@end

@implementation SecurityViewController

#pragma mark - Setup & Teardown

+ (SecurityViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession
{
    SecurityViewController* viewController = [[UIStoryboard storyboardWithName:@"Security" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [viewController addMatrixSession:matrixSession];
    return viewController;
}


#pragma mark - View life cycle

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
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"security_title", @"Vector", nil);
    
    // Remove back bar button title when pushing a view controller
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithTextView.nib forCellReuseIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
    
    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;

    if (self.mainSession.crypto.backup)
    {
        MXDeviceInfo *deviceInfo = [self.mainSession.crypto.deviceList storedDevice:self.mainSession.matrixRestClient.credentials.userId
                                                                           deviceId:self.mainSession.matrixRestClient.credentials.deviceId];

        if (deviceInfo)
        {
            keyBackupSection = [[SettingsKeyBackupTableViewSection alloc] initWithKeyBackup:self.mainSession.crypto.backup userDevice:deviceInfo];
            keyBackupSection.delegate = self;
        }
    }
    
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
        [self refreshSettings];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    if (documentInteractionController)
    {
        [documentInteractionController dismissPreviewAnimated:NO];
        [documentInteractionController dismissMenuAnimated:NO];
        documentInteractionController = nil;
    }
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }

    keyBackupSetupCoordinatorBridgePresenter = nil;
    keyBackupRecoverCoordinatorBridgePresenter = nil;
}

- (void)onMatrixSessionStateDidChange:(NSNotification *)notif
{
    MXSession *mxSession = notif.object;
    
    // Check whether the concerned session is a new one which is not already associated with this view controller.
    if (mxSession.state == MXSessionStateInitialised && [self.mxSessions indexOfObject:mxSession] != NSNotFound)
    {
        // Store this new session
        [self addMatrixSession:mxSession];
    }
    else
    {
        [super onMatrixSessionStateDidChange:notif];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"Settings"];

    // Release the potential pushed view controller
    [self releasePushedViewController];

    // Refresh display
    [self refreshSettings];

    // Refresh the current device information in parallel
    [self loadCurrentDeviceInformation];

    // Refresh devices in parallel
    [self loadDevices];

    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

        [self.tableView setContentOffset:CGPointMake(-self.tableView.mxk_adjustedContentInset.left, -self.tableView.mxk_adjustedContentInset.top) animated:YES];

    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }

    if (kAppDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kAppDelegateDidTapStatusBarNotificationObserver];
        kAppDelegateDidTapStatusBarNotificationObserver = nil;
    }
}

#pragma mark - Internal methods

- (void)pushViewController:(UIViewController*)viewController
{
    // Keep ref on pushed view controller
    pushedViewController = viewController;

    // Hide back button title
    self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)releasePushedViewController
{
    if (pushedViewController)
    {
        if ([pushedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController*)pushedViewController;
            for (id subViewController in navigationController.viewControllers)
            {
                if ([subViewController respondsToSelector:@selector(destroy)])
                {
                    [subViewController destroy];
                }
            }
        }
        else if ([pushedViewController respondsToSelector:@selector(destroy)])
        {
            [(id)pushedViewController destroy];
        }

        pushedViewController = nil;
    }
}

- (void)reset
{
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (deviceView)
    {
        [deviceView removeFromSuperview];
        deviceView = nil;
    }
}

- (void)loadCurrentDeviceInformation
{
    // Refresh the current device information
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account loadDeviceInformation:^{

        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];

    } failure:nil];
}

- (NSAttributedString*)cryptographyInformation
{
    // TODO Handle multi accounts
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;

    // Crypto information
    NSMutableAttributedString *cryptoInformationString = [[NSMutableAttributedString alloc]
                                                          initWithString:NSLocalizedStringFromTable(@"settings_crypto_device_name", @"Vector", nil)
                                                          attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                       NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:account.device.displayName ? account.device.displayName : @""
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];

    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:NSLocalizedStringFromTable(@"settings_crypto_device_id", @"Vector", nil)
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:account.device.deviceId ? account.device.deviceId : @""
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];

    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:NSLocalizedStringFromTable(@"settings_crypto_device_key", @"Vector", nil)
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    NSString *fingerprint = account.mxSession.crypto.deviceEd25519Key;
    if (fingerprint)
    {
        fingerprint = [MXTools addWhiteSpacesToString:fingerprint every:4];
    }
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:fingerprint ? fingerprint : @""
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont boldSystemFontOfSize:17]}]];

    return cryptoInformationString;
}

- (void)loadDevices
{
    // Refresh the account devices list
    MXWeakify(self);
    [self.mainSession.matrixRestClient devices:^(NSArray<MXDevice *> *devices) {
        MXStrongifyAndReturnIfNil(self);

        if (devices)
        {
            self->devicesArray = [NSMutableArray arrayWithArray:devices];

            // Sort devices according to the last seen date.
            NSComparator comparator = ^NSComparisonResult(MXDevice *deviceA, MXDevice *deviceB) {

                if (deviceA.lastSeenTs > deviceB.lastSeenTs)
                {
                    return NSOrderedAscending;
                }
                if (deviceA.lastSeenTs < deviceB.lastSeenTs)
                {
                    return NSOrderedDescending;
                }

                return NSOrderedSame;
            };

            // Sort devices list
            [self->devicesArray sortUsingComparator:comparator];
        }
        else
        {
            self->devicesArray = nil;

        }

        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];

    } failure:^(NSError *error) {

        // Display the data that has been loaded last time
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];

    }];
}

- (void)showDeviceDetails:(MXDevice *)device
{
    deviceView = [[DeviceView alloc] initWithDevice:device andMatrixSession:self.mainSession];
    deviceView.delegate = self;

    // Add the view and define edge constraints
    [self.tableView.superview addSubview:deviceView];
    [self.tableView.superview bringSubviewToFront:deviceView];

    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.tableView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0f
                                                                      constant:0.0f];

    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.tableView
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0f
                                                                       constant:0.0f];

    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.tableView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1.0f
                                                                        constant:0.0f];

    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:deviceView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.tableView
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0f
                                                                         constant:0.0f];

    [NSLayoutConstraint activateConstraints:@[topConstraint, leftConstraint, widthConstraint, heightConstraint]];
}

- (void)deviceView:(DeviceView*)theDeviceView presentAlertController:(UIAlertController *)alert
{
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dismissDeviceView:(MXKDeviceView *)theDeviceView didUpdate:(BOOL)isUpdated
{
    [deviceView removeFromSuperview];
    deviceView = nil;

    if (isUpdated)
    {
        [self loadDevices];
    }
}

- (void)refreshSettings
{
    // Trigger a full table reloadData
    [self.tableView reloadData];
}

- (void)requestAccountPasswordWithTitle:(NSString*)title message:(NSString*)message onComplete:(void (^)(NSString *password))onComplete
{
    [currentAlert dismissViewControllerAnimated:NO completion:nil];

    // Prompt the user before deleting the device.
    currentAlert = [UIAlertController alertControllerWithTitle:title
                                                       message:message
                                                preferredStyle:UIAlertControllerStyleAlert];

    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
    }];

    MXWeakify(self);
    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 MXStrongifyAndReturnIfNil(self);
                                 self->currentAlert = nil;
                             }]];

    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       MXStrongifyAndReturnIfNil(self);

                                                       UITextField *textField = [self->currentAlert textFields].firstObject;
                                                       self->currentAlert = nil;

                                                       onComplete(textField.text);
                                                   }]];

    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];

    // FIXME add night mode
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;

    if (section == SETTINGS_SECTION_DEVICES_INDEX)
    {
        count = devicesArray.count;
        if (count)
        {
            // For some description (DEVICES_DESCRIPTION_INDEX)
            count++;
        }
    }
    else if (section == SETTINGS_SECTION_CRYPTOGRAPHY_INDEX)
    {
        // Check whether this section is visible.
        if (self.mainSession.crypto)
        {
            count = CRYPTOGRAPHY_COUNT;
        }
    }
    else if (section == SETTINGS_SECTION_KEYBACKUP_INDEX)
    {
        // Check whether this section is visible.
        if (self.mainSession.crypto)
        {
            count = keyBackupSection.numberOfRows;
        }
    }

    return count;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];

    cell.mxkLabelLeadingConstraint.constant = cell.separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;

    cell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

    [cell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];

    // Force layout before reusing a cell (fix switch displayed outside the screen)
    [cell layoutIfNeeded];

    return cell;
}

- (MXKTableViewCell*)getDefaultTableViewCell:(UITableView*)tableView
{
    MXKTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    if (!cell)
    {
        cell = [[MXKTableViewCell alloc] init];
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }
    cell.textLabel.accessibilityIdentifier = nil;
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    cell.contentView.backgroundColor = UIColor.clearColor;

    return cell;
}

- (MXKTableViewCellWithTextView*)textViewCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithTextView *textViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier] forIndexPath:indexPath];

    textViewCell.mxkTextView.textColor = ThemeService.shared.theme.textPrimaryColor;
    textViewCell.mxkTextView.font = [UIFont systemFontOfSize:17];
    textViewCell.mxkTextView.backgroundColor = [UIColor clearColor];
    textViewCell.mxkTextViewLeadingConstraint.constant = tableView.separatorInset.left;
    textViewCell.mxkTextViewTrailingConstraint.constant = tableView.separatorInset.right;
    textViewCell.mxkTextView.accessibilityIdentifier = nil;

    return textViewCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor redColor];

    MXSession* session = self.mainSession;
    if (section == SETTINGS_SECTION_DEVICES_INDEX)
    {
        if (row == DEVICES_DESCRIPTION_INDEX)
        {
            MXKTableViewCell *descriptionCell = [self getDefaultTableViewCell:tableView];
            descriptionCell.textLabel.text = NSLocalizedStringFromTable(@"settings_devices_description", @"Vector", nil);
            descriptionCell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            descriptionCell.textLabel.font = [UIFont systemFontOfSize:15];
            descriptionCell.textLabel.numberOfLines = 0;
            descriptionCell.contentView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
            descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;

            cell = descriptionCell;
        }
        else
        {
            NSUInteger deviceIndex = row - 1;

            MXKTableViewCell *deviceCell = [self getDefaultTableViewCell:tableView];
            if (deviceIndex < devicesArray.count)
            {
                NSString *name = devicesArray[deviceIndex].displayName;
                NSString *deviceId = devicesArray[deviceIndex].deviceId;
                deviceCell.textLabel.text = (name.length ? [NSString stringWithFormat:@"%@ (%@)", name, deviceId] : [NSString stringWithFormat:@"(%@)", deviceId]);
                deviceCell.textLabel.numberOfLines = 0;

                if ([deviceId isEqualToString:self.mainSession.matrixRestClient.credentials.deviceId])
                {
                    deviceCell.textLabel.font = [UIFont boldSystemFontOfSize:17];
                }
            }

            cell = deviceCell;
        }

    }
    else if (section == SETTINGS_SECTION_CRYPTOGRAPHY_INDEX)
    {
        if (row == CRYPTOGRAPHY_INFO_INDEX)
        {
            MXKTableViewCellWithTextView *cryptoCell = [self textViewCellForTableView:tableView atIndexPath:indexPath];

            cryptoCell.mxkTextView.attributedText = [self cryptographyInformation];

            cell = cryptoCell;
        }
        else if (row == CRYPTOGRAPHY_BLACKLIST_UNVERIFIED_DEVICES_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_crypto_blacklist_unverified_devices", @"Vector", nil);
            labelAndSwitchCell.mxkSwitch.on = session.crypto.globalBlacklistUnverifiedDevices;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleBlacklistUnverifiedDevices:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        else if (row == CRYPTOGRAPHY_EXPORT_INDEX)
        {
            MXKTableViewCellWithButton *exportKeysBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!exportKeysBtnCell)
            {
                exportKeysBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                exportKeysBtnCell.mxkButton.titleLabel.text = nil;
            }

            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_crypto_export", @"Vector", nil);
            [exportKeysBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [exportKeysBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [exportKeysBtnCell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
            exportKeysBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];

            [exportKeysBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [exportKeysBtnCell.mxkButton addTarget:self action:@selector(exportEncryptionKeys:) forControlEvents:UIControlEventTouchUpInside];
            exportKeysBtnCell.mxkButton.accessibilityIdentifier = nil;

            cell = exportKeysBtnCell;
        }
    }
    else if (section == SETTINGS_SECTION_KEYBACKUP_INDEX)
    {
        cell = [keyBackupSection cellForRowAtRow:row];
    }

    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_DEVICES_INDEX)
    {
        // Check whether this section is visible
        if (devicesArray.count > 0)
        {
            return NSLocalizedStringFromTable(@"settings_devices", @"Vector", nil);
        }
    }
    else if (section == SETTINGS_SECTION_CRYPTOGRAPHY_INDEX)
    {
        // Check whether this section is visible
        if (self.mainSession.crypto)
        {
            return NSLocalizedStringFromTable(@"settings_cryptography", @"Vector", nil);
        }
    }
    else if (section == SETTINGS_SECTION_KEYBACKUP_INDEX)
    {
        // Check whether this section is visible
        if (self.mainSession.crypto)
        {
            return NSLocalizedStringFromTable(@"settings_key_backup", @"Vector", nil);
        }
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:UITableViewHeaderFooterView.class])
    {
        // Customize label style
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView*)view;
        tableViewHeaderFooterView.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        tableViewHeaderFooterView.textLabel.font = [UIFont systemFontOfSize:15];
    }
}


#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;

    if (cell.selectionStyle != UITableViewCellSelectionStyleNone)
    {
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 24;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 24;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;

        if (section == SETTINGS_SECTION_DEVICES_INDEX)
        {
            if (row > DEVICES_DESCRIPTION_INDEX)
            {
                NSUInteger deviceIndex = row - 1;
                if (deviceIndex < devicesArray.count)
                {
                    [self showDeviceDetails:devicesArray[deviceIndex]];
                }
            }
        }

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    // If iOS wants to call this method, this is the right time to remove the file
    [self deleteKeyExportFile];
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
}

#pragma mark - actions

- (void)exportEncryptionKeys:(UITapGestureRecognizer *)recognizer
{
    [currentAlert dismissViewControllerAnimated:NO completion:nil];

    exportView = [[MXKEncryptionKeysExportView alloc] initWithMatrixSession:self.mainSession];
    currentAlert = exportView.alertController;

    // Use a temporary file for the export
    keyExportsFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"riot-keys.txt"]];

    // Make sure the file is empty
    [self deleteKeyExportFile];

    // Show the export dialog
    MXWeakify(self);
    [exportView showInViewController:self toExportKeysToFile:keyExportsFile onComplete:^(BOOL success) {
        MXStrongifyAndReturnIfNil(self);

        self->currentAlert = nil;
        self->exportView = nil;

        if (success)
        {
            // Let another app handling this file
            self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:self->keyExportsFile];
            [self->documentInteractionController setDelegate:self];

            if ([self->documentInteractionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES])
            {
                // We want to delete the temp keys file after it has been processed by the other app.
                // We use [UIDocumentInteractionControllerDelegate didEndSendingToApplication] for that
                // but it is not reliable for all cases (see http://stackoverflow.com/a/21867096).
                // So, arm a timer to auto delete the file after 10mins.
                self->keyExportsFileDeletionTimer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(deleteKeyExportFile) userInfo:self repeats:NO];
            }
            else
            {
                self->documentInteractionController = nil;
                [self deleteKeyExportFile];
            }
        }
    }];
}

- (void)deleteKeyExportFile
{
    // Cancel the deletion timer if it is still here
    if (keyExportsFileDeletionTimer)
    {
        [keyExportsFileDeletionTimer invalidate];
        keyExportsFileDeletionTimer = nil;
    }

    // And delete the file
    if (keyExportsFile && [[NSFileManager defaultManager] fileExistsAtPath:keyExportsFile.path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:keyExportsFile.path error:nil];
    }
}

- (void)toggleBlacklistUnverifiedDevices:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;

    self.mainSession.crypto.globalBlacklistUnverifiedDevices = switchButton.on;

    [self.tableView reloadData];
}


#pragma mark - MXKDataSourceDelegate

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    // Group data has been updated. Do a simple full reload
    [self refreshSettings];
}


#pragma mark - SettingsKeyBackupTableViewSectionDelegate

- (void)settingsKeyBackupTableViewSectionDidUpdate:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection
{
    [self.tableView reloadData];
}

- (MXKTableViewCellWithTextView *)settingsKeyBackupTableViewSection:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection textCellForRow:(NSInteger)textCellForRow
{
    return [self textViewCellForTableView:self.tableView atIndexPath:[NSIndexPath indexPathForRow:textCellForRow inSection:SETTINGS_SECTION_KEYBACKUP_INDEX]];
}

- (MXKTableViewCellWithButton *)settingsKeyBackupTableViewSection:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection buttonCellForRow:(NSInteger)buttonCellForRow
{
    MXKTableViewCellWithButton *cell = [self.tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];

    if (!cell)
    {
        cell = [[MXKTableViewCellWithButton alloc] init];
    }
    else
    {
        // Fix https://github.com/vector-im/riot-ios/issues/1354
        cell.mxkButton.titleLabel.text = nil;
    }

    cell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [cell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];

    return cell;
}

- (void)settingsKeyBackupTableViewSectionShowKeyBackupSetup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection
{
    [self showKeyBackupSetupFromSignOutFlow:NO];
}

- (void)settingsKeyBackup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection showKeyBackupRecover:(MXKeyBackupVersion *)keyBackupVersion
{
    [self showKeyBackupRecover:keyBackupVersion];
}

- (void)settingsKeyBackup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection showKeyBackupDeleteConfirm:(MXKeyBackupVersion *)keyBackupVersion
{
    MXWeakify(self);
    [currentAlert dismissViewControllerAnimated:NO completion:nil];

    currentAlert =
    [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_key_backup_delete_confirmation_prompt_title", @"Vector", nil)
                                        message:NSLocalizedStringFromTable(@"settings_key_backup_delete_confirmation_prompt_msg", @"Vector", nil)
                                 preferredStyle:UIAlertControllerStyleAlert];

    [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                   }]];

    [currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"settings_key_backup_button_delete", @"Vector", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;

                                                       [self->keyBackupSection deleteWithKeyBackupVersion:keyBackupVersion];
                                                   }]];

    [currentAlert mxk_setAccessibilityIdentifier: @"SettingsVCDeleteKeyBackup"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)settingsKeyBackup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection showActivityIndicator:(BOOL)show
{
    if (show)
    {
        [self startActivityIndicator];
    }
    else
    {
        [self stopActivityIndicator];
    }
}

- (void)settingsKeyBackup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection showError:(NSError *)error
{
    [[AppDelegate theDelegate] showErrorAsAlert:error];
}

#pragma mark - KeyBackupRecoverCoordinatorBridgePresenter

- (void)showKeyBackupSetupFromSignOutFlow:(BOOL)showFromSignOutFlow
{
    keyBackupSetupCoordinatorBridgePresenter = [[KeyBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];

    [keyBackupSetupCoordinatorBridgePresenter presentFrom:self
                                     isStartedFromSignOut:showFromSignOutFlow
                                                 animated:true];

    keyBackupSetupCoordinatorBridgePresenter.delegate = self;
}

- (void)keyBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(KeyBackupSetupCoordinatorBridgePresenter *)bridgePresenter {
    [keyBackupSetupCoordinatorBridgePresenter dismissWithAnimated:true];
    keyBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)keyBackupSetupCoordinatorBridgePresenterDelegateDidSetupRecoveryKey:(KeyBackupSetupCoordinatorBridgePresenter *)bridgePresenter {
    [keyBackupSetupCoordinatorBridgePresenter dismissWithAnimated:true];
    keyBackupSetupCoordinatorBridgePresenter = nil;

    [keyBackupSection reload];
}

#pragma mark - KeyBackupRecoverCoordinatorBridgePresenter

- (void)showKeyBackupRecover:(MXKeyBackupVersion*)keyBackupVersion
{
    keyBackupRecoverCoordinatorBridgePresenter = [[KeyBackupRecoverCoordinatorBridgePresenter alloc] initWithSession:self.mainSession keyBackupVersion:keyBackupVersion];

    [keyBackupRecoverCoordinatorBridgePresenter presentFrom:self animated:true];
    keyBackupRecoverCoordinatorBridgePresenter.delegate = self;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidCancel:(KeyBackupRecoverCoordinatorBridgePresenter *)bridgePresenter {
    [keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:true];
    keyBackupRecoverCoordinatorBridgePresenter = nil;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidRecover:(KeyBackupRecoverCoordinatorBridgePresenter *)bridgePresenter {
    [keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:true];
    keyBackupRecoverCoordinatorBridgePresenter = nil;
}

@end
