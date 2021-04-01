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

#import "ManageSessionViewController.h"

#import <MatrixKit/MatrixKit.h>

#import <OLMKit/OLMKit.h>

#import "AvatarGenerator.h"

#import "ThemeService.h"

#import "Riot-Swift.h"

// Dev flag to have more options
//#define CROSS_SIGNING_AND_BACKUP_DEV

enum
{
    SECTION_PIN_CODE,
    SECTION_CRYPTO_SESSIONS,
    SECTION_SECURE_BACKUP,
    SECTION_CRYPTOGRAPHY,
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    SECTION_CROSSSIGNING,
    SECTION_KEYBACKUP,
#endif
    SECTION_ADVANCED,
    SECTION_COUNT
};

enum {
    CROSSSIGNING_INFO,
    CROSSSIGNING_FIRST_ACTION,      // Bootstrap, Reset, Verify this session, Request keys
    CROSSSIGNING_SECOND_ACTION,     // Reset
};

enum {
    SECURE_BACKUP_DESCRIPTION,
    // TODO: We can display the state of 4S both locally and on the server. Then, provide actions according to all combinations.
    // - Does the 4S contains all the 4 keys server side?
    // - Advice the user to do a recovery if there is less keys locally
    // - Advice them to do a recovery if local keys are obsolete -> We cannot know now
    // - Advice them to fix a secure backup if there is 4S but no key backup
    // - Warm them if there is no 4S and they do not have all 3 signing keys locally. They will set up a not complete secure backup
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    SECURE_BACKUP_INFO,
#endif
    SECURE_BACKUP_SETUP,
    SECURE_BACKUP_RESTORE,
    SECURE_BACKUP_DELETE,
    SECURE_BACKUP_MANAGE_MANUALLY,  // TODO: What to do with that?
};

enum {
    PIN_CODE_SETTING,
    PIN_CODE_DESCRIPTION,
    PIN_CODE_CHANGE,
    PIN_CODE_BIOMETRICS,
    PIN_CODE_COUNT
};

enum {
    CRYPTOGRAPHY_INFO,
    CRYPTOGRAPHY_EXPORT,    // TODO: To move to SECTION_KEYBACKUP
    CRYPTOGRAPHY_COUNT
};

enum {
    ADVANCED_BLACKLIST_UNVERIFIED_DEVICES,
    ADVANCED_BLACKLIST_UNVERIFIED_DEVICES_DESCRIPTION,
    ADVANCED_COUNT
};


@interface SecurityViewController () <
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
SettingsKeyBackupTableViewSectionDelegate,
KeyBackupSetupCoordinatorBridgePresenterDelegate,
KeyBackupRecoverCoordinatorBridgePresenterDelegate,
#endif
UIDocumentInteractionControllerDelegate,
SecretsRecoveryCoordinatorBridgePresenterDelegate,
SecureBackupSetupCoordinatorBridgePresenterDelegate,
SetPinCoordinatorBridgePresenterDelegate,
TableViewSectionsDelegate>
{
    // Current alert (if any).
    UIAlertController *currentAlert;

    // Devices
    NSMutableArray<MXDevice *> *devicesArray;
    
    // SECURE_BACKUP_* rows to display
    NSArray<NSNumber *> *secureBackupSectionState;
    
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

#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    SettingsKeyBackupTableViewSection *keyBackupSection;
    KeyBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter;
#endif
    KeyBackupRecoverCoordinatorBridgePresenter *keyBackupRecoverCoordinatorBridgePresenter;

    SecretsRecoveryCoordinatorBridgePresenter *secretsRecoveryCoordinatorBridgePresenter;
}

@property (nonatomic, strong) TableViewSections *tableViewSections;
@property (nonatomic) BOOL isLoadingDevices;
@property (nonatomic, strong) MXKeyBackupVersion *currentkeyBackupVersion;
@property (nonatomic, strong) SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) SetPinCoordinatorBridgePresenter *setPinCoordinatorBridgePresenter;
@property (nonatomic, strong) CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter;

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
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"security_settings_title", @"Vector", nil);
    
    // Remove back bar button title when pushing a view controller
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithTextView.nib forCellReuseIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithButton.nib forCellReuseIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];

    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;

#ifdef CROSS_SIGNING_AND_BACKUP_DEV
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
#endif
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
    
    [self registerUserDevicesChangesNotification];
    
    self.tableViewSections = [TableViewSections new];
    self.tableViewSections.delegate = self;
     
    [self updateSections];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    [self reloadData];

    [self setNeedsStatusBarAppearanceUpdate];
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

#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    keyBackupSetupCoordinatorBridgePresenter = nil;
#endif
    keyBackupRecoverCoordinatorBridgePresenter = nil;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"Security"];

    // Release the potential pushed view controller
    [self releasePushedViewController];

    // Refresh display
    [self reloadData];

    // Refresh the current device information in parallel
    [self loadCurrentDeviceInformation];

    // Refresh devices in parallel
    [self loadDevices];
    
    [self loadCrossSigning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
}

#pragma mark - Internal methods

- (void)updateSections
{
    NSMutableArray<Section*> *sections = [NSMutableArray array];
    
    // Pin code section
    
    Section *pinCodeSection = [Section sectionWithTag:SECTION_PIN_CODE];
    
    // Header title
    NSString *pinCodeSectionHeaderTitleFormat = NSLocalizedStringFromTable(@"pin_protection_settings_section_header_x", @"Vector", nil);
    NSString *pinCodeSectionHeaderTitle = [NSString stringWithFormat:pinCodeSectionHeaderTitleFormat, [PinCodePreferences shared].localizedBiometricsName];
    pinCodeSection.headerTitle = pinCodeSectionHeaderTitle;
    
    // Rows
    [pinCodeSection addRowWithTag:PIN_CODE_SETTING];
    [pinCodeSection addRowWithTag:PIN_CODE_DESCRIPTION];
    if ([PinCodePreferences shared].isPinSet) {
        [pinCodeSection addRowWithTag:PIN_CODE_CHANGE];
    }

    if ([PinCodePreferences shared].isBiometricsAvailable)
    {
        [pinCodeSection addRowWithTag:PIN_CODE_BIOMETRICS];
    }
    
    [sections addObject:pinCodeSection];
    
    // Crypto sessions section
        
    if (RiotSettings.shared.settingsSecurityScreenShowSessions)
    {
        Section *sessionsSection = [Section sectionWithTag:SECTION_CRYPTO_SESSIONS];
        
        sessionsSection.headerTitle = NSLocalizedStringFromTable(@"security_settings_crypto_sessions", @"Vector", nil);
            
        NSUInteger sessionsSectionRowsCount;
        
        if (self.showLoadingDevicesInformation)
        {
            sessionsSectionRowsCount = 2;
        }
        else
        {
            sessionsSectionRowsCount = devicesArray.count + 1;
        }

        [sessionsSection addRowsWithCount:sessionsSectionRowsCount];
        
        [sections addObject:sessionsSection];
    }
    
    // Secure backup
    
    Section *secureBackupSection = [Section sectionWithTag:SECTION_SECURE_BACKUP];
    secureBackupSection.headerTitle = NSLocalizedStringFromTable(@"security_settings_secure_backup", @"Vector", nil);

    [secureBackupSection addRowsWithCount:[self numberOfRowsInSecureBackupSection]];

    if (secureBackupSection.rows.count)
    {
        [sections addObject:secureBackupSection];
    }
    
    // Cryptograhpy
    
    Section *cryptograhpySection = [Section sectionWithTag:SECTION_CRYPTOGRAPHY];
    cryptograhpySection.headerTitle = NSLocalizedStringFromTable(@"security_settings_cryptography", @"Vector", nil);
    
    if (RiotSettings.shared.settingsSecurityScreenShowCryptographyInfo)
    {
        [cryptograhpySection addRowWithTag:CRYPTOGRAPHY_INFO];
    }
    
    if (RiotSettings.shared.settingsSecurityScreenShowCryptographyExport)
    {
        [cryptograhpySection addRowWithTag:CRYPTOGRAPHY_EXPORT];
    }

    if (cryptograhpySection.rows.count)
    {
        [sections addObject:cryptograhpySection];
    }

#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    
    // Cross-Signing
    
    Section *crossSigningSection = [Section sectionWithTag:SECTION_CROSSSIGNING];
    crossSigningSection.headerTitle = NSLocalizedStringFromTable(@"security_settings_crosssigning", @"Vector", nil);
    
    [crossSigningSection addRowsWithCount:[self numberOfRowsInCrossSigningSection]];
    
    [sections addObject:crossSigningSection];
    
    // Keybackup
    
    Section *keybackupSection = [Section sectionWithTag:SECTION_KEYBACKUP];
    keybackupSection.headerTitle = NSLocalizedStringFromTable(@"security_settings_backup", @"Vector", nil);
    
    [keybackupSection addRowsWithCount:self->keyBackupSection.numberOfRows];
    
    [sections addObject:keybackupSection];
        
#endif
    
    // Advanced
    
    Section *advancedSection = [Section sectionWithTag:SECTION_ADVANCED];
    advancedSection.headerTitle = NSLocalizedStringFromTable(@"security_settings_advanced", @"Vector", nil);
    
    if (RiotSettings.shared.settingsSecurityScreenShowAdvancedUnverifiedDevices)
    {
        [advancedSection addRowWithTag:ADVANCED_BLACKLIST_UNVERIFIED_DEVICES];
        [advancedSection addRowWithTag:ADVANCED_BLACKLIST_UNVERIFIED_DEVICES_DESCRIPTION];
    }
    
    if (advancedSection.rows.count)
    {
        [sections addObject:advancedSection];
    }

    // Update sections
    
    self.tableViewSections.sections = sections;
}

- (BOOL)showLoadingDevicesInformation
{
    return self.isLoadingDevices && devicesArray.count == 0;
}

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
}

- (void)loadCurrentDeviceInformation
{
    // Refresh the current device information
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account loadDeviceInformation:^{

        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self reloadData];

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
    self.isLoadingDevices = YES;
    
    // Refresh the account devices list
    MXWeakify(self);
    [self.mainSession.matrixRestClient devices:^(NSArray<MXDevice *> *devices) {
        MXStrongifyAndReturnIfNil(self);
        
        self.isLoadingDevices = NO;

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
        [self reloadData];

    } failure:^(NSError *error) {

        self.isLoadingDevices = NO;
        
        // Display the data that has been loaded last time
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self reloadData];

    }];
}

- (void)reloadData
{
    [self refreshSecureBackupSectionData];
    
    // Update table view sections and trigger a tableView reloadData
    [self updateSections];
}


#pragma mark - Data update

- (void)registerUserDevicesChangesNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceInfoTrustLevelDidChangeNotification:)
                                                 name:MXDeviceInfoTrustLevelDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(crossSigningInfoTrustLevelDidChangeNotification:)
                                                 name:MXCrossSigningInfoTrustLevelDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDidUpdateUsersDevicesNotification:)
                                                 name:MXDeviceListDidUpdateUsersDevicesNotification
                                               object:nil];
}

- (void)onDidUpdateUsersDevicesNotification:(NSNotification*)notification
{
    NSDictionary *usersDevices = notification.userInfo;
    
    if ([usersDevices.allKeys containsObject:self.mainSession.myUserId])
    {
        [self loadDevices];
    }
}

- (void)onDeviceInfoTrustLevelDidChangeNotification:(NSNotification*)notification
{
    MXDeviceInfo *deviceInfo = notification.object;
    
    NSString *userId = deviceInfo.userId;
    if ([userId isEqualToString:self.mainSession.myUserId])
    {
        [self loadDevices];
    }
}

- (void)crossSigningInfoTrustLevelDidChangeNotification:(NSNotification*)notification
{
    MXCrossSigningInfo *crossSigningInfo = notification.object;
    
    NSString *userId = crossSigningInfo.userId;
    if ([userId isEqualToString:self.mainSession.myUserId])
    {
        [self loadDevices];
    }
}


#pragma mark - Cross-signing

- (void)loadCrossSigning
{
    MXCrossSigning *crossSigning = self.mainSession.crypto.crossSigning;
    
    [crossSigning refreshStateWithSuccess:^(BOOL stateUpdated) {
        if (stateUpdated)
        {
            [self reloadData];
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"[SecurityVC] loadCrossSigning: Cannot refresh cross-signing state. Error: %@", error);
    }];
}

- (NSInteger)numberOfRowsInCrossSigningSection
{
    NSInteger numberOfRowsInCrossSigningSection;
    
    MXCrossSigning *crossSigning = self.mainSession.crypto.crossSigning;
    switch (crossSigning.state)
    {
        case MXCrossSigningStateNotBootstrapped:                // Action: Bootstrap
        case MXCrossSigningStateCanCrossSign:                   // Action: Reset
            numberOfRowsInCrossSigningSection = CROSSSIGNING_FIRST_ACTION + 1;
            break;
        case MXCrossSigningStateCrossSigningExists:             // Actions: Verify this session, Reset
        case MXCrossSigningStateTrustCrossSigning:              // Actions: Request keys, Reset
            numberOfRowsInCrossSigningSection = CROSSSIGNING_SECOND_ACTION + 1;
            break;
    }
    
    return numberOfRowsInCrossSigningSection;
}

- (NSAttributedString*)crossSigningInformation
{
    MXCrossSigning *crossSigning = self.mainSession.crypto.crossSigning;
    
    NSString *crossSigningInformation;
    switch (crossSigning.state)
    {
        case MXCrossSigningStateNotBootstrapped:
            crossSigningInformation = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_info_not_bootstrapped"];
            break;
        case MXCrossSigningStateCrossSigningExists:
            crossSigningInformation = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_info_exists"];
            break;
        case MXCrossSigningStateTrustCrossSigning:
            crossSigningInformation = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_info_trusted"];
            break;
        case MXCrossSigningStateCanCrossSign:
            crossSigningInformation = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_info_ok"];
            
            if (![self.mainSession.crypto.recoveryService hasSecretLocally:MXSecretId.crossSigningMaster])
            {
                crossSigningInformation = [crossSigningInformation stringByAppendingString:@"\n\n⚠️ The MSK is missing. Verify this device again or use the Secure Backup below to synchronise your keys accross your devices"];
            }
            break;
    }
    
    return [[NSAttributedString alloc] initWithString:crossSigningInformation
                                           attributes:@{
                                                        NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                        NSFontAttributeName: [UIFont systemFontOfSize:17]
                                                        }];
}

- (UITableViewCell*)crossSigningButtonCellInTableView:(UITableView*)tableView forAction:(NSInteger)action
{
    // Get a button cell
    MXKTableViewCellWithButton *buttonCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
    if (!buttonCell)
    {
        buttonCell = [[MXKTableViewCellWithButton alloc] init];
    }

    [buttonCell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
    buttonCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
    
    [buttonCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    buttonCell.mxkButton.accessibilityIdentifier = nil;
    
    // And customise it
    MXCrossSigning *crossSigning = self.mainSession.crypto.crossSigning;
    switch (crossSigning.state)
    {
        case MXCrossSigningStateNotBootstrapped:                // Action: Bootstrap
            [self setUpcrossSigningButtonCellForBootstrap:buttonCell];
            break;
        case MXCrossSigningStateCanCrossSign:                   // Action: Reset
            [self setUpcrossSigningButtonCellForReset:buttonCell];
            break;
        case MXCrossSigningStateCrossSigningExists:             // Actions: Verify this session, Reset
            switch (action)
            {
                case CROSSSIGNING_FIRST_ACTION:
                    [self setUpcrossSigningButtonCellForCompletingSecurity:buttonCell];
                    break;
                case CROSSSIGNING_SECOND_ACTION:
                    [self setUpcrossSigningButtonCellForReset:buttonCell];
                    break;
            }
            break;
        case MXCrossSigningStateTrustCrossSigning:              // Actions: Request keys, Reset
            switch (action)
            {
                case CROSSSIGNING_FIRST_ACTION:
                    // By verifying our device again, it will get cross-signing keys by gossiping
                    [self setUpcrossSigningButtonCellForCompletingSecurity:buttonCell];
                    break;
                case CROSSSIGNING_SECOND_ACTION:
                    [self setUpcrossSigningButtonCellForReset:buttonCell];
                    break;
            }
            break;
    }
    
    return buttonCell;
}

- (void)setUpcrossSigningButtonCellForBootstrap:(MXKTableViewCellWithButton*)buttonCell
{
    NSString *btnTitle = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_bootstrap"];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
 
    [buttonCell.mxkButton addTarget:self action:@selector(setupCrossSigning:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupCrossSigning:(id)sender
{
    [self setupCrossSigningWithTitle:@"Set up cross-signing"    // TODO
                             message:NSLocalizedStringFromTable(@"security_settings_user_password_description", @"Vector", nil)
                             success:^{
                             } failure:^(NSError *error) {
                             }];
}

- (void)setupCrossSigningWithTitle:(NSString*)title
                           message:(NSString*)message
                           success:(void (^)(void))success
                           failure:(void (^)(NSError *error))failure

{
    [self startActivityIndicator];
    
    MXWeakify(self);
    
    void (^animationCompletion)(void) = ^void () {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        [self.crossSigningSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{}];
        self.crossSigningSetupCoordinatorBridgePresenter = nil;
    };
    
    CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter = [[CrossSigningSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
        
    [crossSigningSetupCoordinatorBridgePresenter presentWith:title
                                                     message:message
                                                        from:self
                                                    animated:YES
                                                     success:^{
        animationCompletion();
        [self reloadData];
        success();
    } cancel:^{
        animationCompletion();
        failure(nil);
    } failure:^(NSError * _Nonnull error) {
        animationCompletion();
        [self reloadData];
        [[AppDelegate theDelegate] showErrorAsAlert:error];
        failure(error);
    }];
    
    self.crossSigningSetupCoordinatorBridgePresenter = crossSigningSetupCoordinatorBridgePresenter;
}

- (void)resetCrossSigning:(id)sender
{
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    // Double confirmation
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Are you sure?"  // TODO
                                                                             message:@"Anyone you have verified with will see security alerts. You almost certainly don't want to do this, unless you've lost every device you can cross-sign from."     // TODO
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Reset"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action)
                                {
                                    // Setup and reset are the same thing
                                    [self setupCrossSigning:nil];
                                }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    currentAlert = alertController;
}

- (void)setUpcrossSigningButtonCellForReset:(MXKTableViewCellWithButton*)buttonCell
{
    NSString *btnTitle = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_reset"];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
    
    buttonCell.mxkButton.tintColor = ThemeService.shared.theme.warningColor;
    
    [buttonCell.mxkButton addTarget:self action:@selector(resetCrossSigning:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpcrossSigningButtonCellForCompletingSecurity:(MXKTableViewCellWithButton*)buttonCell
{
    NSString *btnTitle = [NSBundle mxk_localizedStringForKey:@"security_settings_crosssigning_complete_security"];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
    
    [buttonCell.mxkButton addTarget:self action:@selector(presentCompleteSecurity) forControlEvents:UIControlEventTouchUpInside];
}

- (void)displayComingSoon
{
    [[AppDelegate theDelegate] showAlertWithTitle:nil message:[NSBundle mxk_localizedStringForKey:@"security_settings_coming_soon"]];
}


#pragma mark - SSSS

- (void)refreshSecureBackupSectionData
{
    MXRecoveryService *recoveryService =  self.mainSession.crypto.recoveryService;
    NSMutableArray *secureBackupSectionState = [NSMutableArray new];
    if (recoveryService.hasRecovery)
    {
        if (RiotSettings.shared.settingsSecurityScreenShowRestoreBackup)
        {
            [secureBackupSectionState addObject:@(SECURE_BACKUP_RESTORE)];
        }
        if (RiotSettings.shared.settingsSecurityScreenShowDeleteBackup)
        {
            [secureBackupSectionState addObject:@(SECURE_BACKUP_DELETE)];
        }
    }
    else
    {
        if (RiotSettings.shared.settingsSecurityScreenShowSetupBackup)
        {
            [secureBackupSectionState addObject:@(SECURE_BACKUP_SETUP)];
        }
    }
    
    if (secureBackupSectionState.count)
    {
        [secureBackupSectionState addObject:@(SECURE_BACKUP_DESCRIPTION)];
    }

#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    [secureBackupSectionState addObject:@(SECURE_BACKUP_INFO)];
#endif
    
    self->secureBackupSectionState = secureBackupSectionState;
}

- (NSUInteger)secureBackupSectionEnumForRow:(NSUInteger)row
{
    if (row < secureBackupSectionState.count)
    {
        return secureBackupSectionState[row].unsignedIntegerValue;
    }
    
    return SECURE_BACKUP_DESCRIPTION;
}

- (NSUInteger)numberOfRowsInSecureBackupSection
{
    return secureBackupSectionState.count;
}

- (NSString*)secureBackupInformation
{
    NSString *secureBackupInformation;
    
    MXRecoveryService *recoveryService =  self.mainSession.crypto.recoveryService;
    
    if (recoveryService.hasRecovery)
    {
        NSMutableString *mutableString = [@"Your account has a Secure Backup.\n" mutableCopy];
        
        // Check all keys that should be in the SSSSS
        // TODO: Check obsoletes ones but need spec update
        
        BOOL hasWarning = NO;
        NSString *keyState = [self informationForSecret:MXSecretId.crossSigningMaster secretName:@"Cross-signing" hasWarning:&hasWarning];
        if (keyState)
        {
            [mutableString appendString:keyState];
        }
        
        keyState = [self informationForSecret:MXSecretId.crossSigningSelfSigning secretName:@"Self signing" hasWarning:&hasWarning];
        if (keyState)
        {
            [mutableString appendString:keyState];
        }

        keyState = [self informationForSecret:MXSecretId.crossSigningUserSigning secretName:@"User signing" hasWarning:&hasWarning];
        if (keyState)
        {
            [mutableString appendString:keyState];
        }
        
        keyState = [self informationForSecret:MXSecretId.keyBackup secretName:@"Message Backup" hasWarning:&hasWarning];
        if (keyState)
        {
            [mutableString appendString:keyState];
        }
        else
        {
            if (self.mainSession.crypto.backup.keyBackupVersion)
            {
                [mutableString appendString:@"\n\n⚠️ The key of your current Message backup is not in the Secure Backup. Restore it first (see below)."];
            }
            else
            {
                [mutableString appendString:@"\n\n⚠️ Consider create a Message Backup (see below)."];
            }
        }
        
        if (!hasWarning)
        {
            [mutableString appendFormat:@"\n\nIf you are facing an issue, synchronise your Secure Backup."];
        }
        
        secureBackupInformation = mutableString;
    }
    else
    {
        if (self.canSetupSecureBackup)
        {
            secureBackupInformation = [NSString stringWithFormat:@"No Secure Backup. Create one.\n-----\nKeys to back up: %@", recoveryService.secretsStoredLocally];
        }
        else
        {
            secureBackupInformation = [NSString stringWithFormat:@"No Secure Backup. Set up cross-signing first (see above)"];
        }
    }

    return secureBackupInformation;
}

- (nullable NSString*)informationForSecret:(NSString*)secretId secretName:(NSString*)secretName hasWarning:(BOOL*)hasWarning
{
    NSString *information;
    
    MXRecoveryService *recoveryService = self.mainSession.crypto.recoveryService;
    
    if ([recoveryService hasSecretWithSecretId:secretId])
    {
        if ([recoveryService hasSecretLocally:secretId])
        {
            information = [NSString stringWithFormat:@"\n ✅ %@ is in the backup", secretName];
        }
        else
        {
            information = [NSString stringWithFormat:@"\n ⚠️ %@ is in the backup but not locally. Tap Synchronise", secretName];
            *hasWarning |= YES;
        }
    }
    else
    {
        if ([recoveryService hasSecretLocally:secretId])
        {
            information = [NSString stringWithFormat:@"\n ⚠️ %@ is not in the backup. Tap Synchronise", secretName];
            *hasWarning |= YES;
        }
    }
    
    return information;
}

- (BOOL)canSetupSecureBackup
{
    // Accept to create a setup only if we have the 3 cross-signing keys
    // This is the path to have a sane state
    MXRecoveryService *recoveryService = self.mainSession.crypto.recoveryService;
    
    NSArray *crossSigningServiceSecrets = @[
                                            MXSecretId.crossSigningMaster,
                                            MXSecretId.crossSigningSelfSigning,
                                            MXSecretId.crossSigningUserSigning];
    
    return ([recoveryService.secretsStoredLocally mx_intersectArray:crossSigningServiceSecrets].count
            == crossSigningServiceSecrets.count);
}

- (void)setupSecureBackup
{
    if (self.canSetupSecureBackup)
    {
        [self setupSecureBackup2];
    }
    else
    {
        // Set up cross-signing first
        [self setupCrossSigningWithTitle:NSLocalizedStringFromTable(@"secure_key_backup_setup_intro_title", @"Vector", nil)
                                 message:NSLocalizedStringFromTable(@"security_settings_user_password_description", @"Vector", nil)
                                 success:^{
                                     [self setupSecureBackup2];
                                 } failure:^(NSError *error) {
                                 }];
    }
}

- (void)setupSecureBackup2
{
    SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter = [[SecureBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
    secureBackupSetupCoordinatorBridgePresenter.delegate = self;
    
    [secureBackupSetupCoordinatorBridgePresenter presentFrom:self animated:YES];
    
    self.secureBackupSetupCoordinatorBridgePresenter = secureBackupSetupCoordinatorBridgePresenter;
}

- (void)restoreFromSecureBackup
{
    secretsRecoveryCoordinatorBridgePresenter = [[SecretsRecoveryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession recoveryGoal:SecretsRecoveryGoalRestoreSecureBackup];
    
    [secretsRecoveryCoordinatorBridgePresenter presentFrom:self animated:true];
    secretsRecoveryCoordinatorBridgePresenter.delegate = self;
}

- (void)deleteSecureBackup
{
    MXRecoveryService *recoveryService = self.mainSession.crypto.recoveryService;
    if (recoveryService)
    {
        [self startActivityIndicator];
        [recoveryService deleteRecoveryWithDeleteServicesBackups:YES success:^{
            [self stopActivityIndicator];
            [self reloadData];
        } failure:^(NSError * _Nonnull error) {
            [self stopActivityIndicator];
            [self reloadData];
            
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    }
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
    return self.tableViewSections.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Section *tableSection = [self.tableViewSections sectionAtIndex:section];
    return tableSection.rows.count;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];

    cell.mxkLabelLeadingConstraint.constant = cell.vc_separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;

    cell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

    [cell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];

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
        cell.imageView.image = nil;
    }
    cell.textLabel.accessibilityIdentifier = nil;
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    cell.contentView.backgroundColor = UIColor.clearColor;

    return cell;
}

- (MXKTableViewCell*)deviceCellWithDevice:(MXDevice*)device forTableView:(UITableView*)tableView
{
    MXKTableViewCell *cell = [self getDefaultTableViewCell:tableView];
    NSString *name = device.displayName;
    NSString *deviceId = device.deviceId;
    cell.textLabel.text = (name.length ? [NSString stringWithFormat:@"%@ (%@)", name, deviceId] : [NSString stringWithFormat:@"(%@)", deviceId]);
    cell.textLabel.numberOfLines = 0;
    [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];

    if ([deviceId isEqualToString:self.mainSession.matrixRestClient.credentials.deviceId])
    {
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    }

    cell.imageView.image = [self shieldImageForDevice:deviceId];

    return cell;
}

- (UIImage*)shieldImageForDevice:(NSString*)deviceId
{
    if (!self.mainSession.crypto.crossSigning.canCrossSign)
    {
        if ([deviceId isEqualToString:self.mainSession.myDeviceId])
        {
            return [UIImage imageNamed:@"encryption_warning"];
        }
        else
        {
            return [UIImage imageNamed:@"encryption_normal"];
        }
    }
    
    UIImage* shieldImageForDevice = [UIImage imageNamed:@"encryption_warning"];
    MXDeviceInfo *device = [self.mainSession.crypto deviceWithDeviceId:deviceId ofUser:self.mainSession.myUser.userId];
    if (device.trustLevel.isVerified)
    {
        shieldImageForDevice = [UIImage imageNamed:@"encryption_trusted"];
    }

    return shieldImageForDevice;
}


- (MXKTableViewCell*)descriptionCellForTableView:(UITableView*)tableView withText:(NSString*)text
{
    MXKTableViewCell *cell = [self getDefaultTableViewCell:tableView];
    cell.textLabel.text = text;
    cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    cell.textLabel.numberOfLines = 0;
    cell.contentView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (MXKTableViewCellWithTextView*)textViewCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithTextView *textViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier] forIndexPath:indexPath];

    textViewCell.mxkTextView.textColor = ThemeService.shared.theme.textPrimaryColor;
    textViewCell.mxkTextView.font = [UIFont systemFontOfSize:17];
    textViewCell.mxkTextView.backgroundColor = [UIColor clearColor];
    textViewCell.mxkTextViewLeadingConstraint.constant = tableView.vc_separatorInset.left;
    textViewCell.mxkTextViewTrailingConstraint.constant = tableView.vc_separatorInset.right;
    textViewCell.mxkTextView.accessibilityIdentifier = nil;

    return textViewCell;
}

- (MXKTableViewCellWithButton *)buttonCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithButton *cell = [self.tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[MXKTableViewCellWithButton alloc] init];
    }
    else
    {
        // Fix https://github.com/vector-im/riot-ios/issues/1354
        cell.mxkButton.titleLabel.text = nil;
        cell.mxkButton.enabled = YES;
    }
    
    cell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [cell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
    
    return cell;
}

- (MXKTableViewCellWithButton *)buttonCellWithTitle:(NSString*)title
                                           action:(SEL)action
                                       forTableView:(UITableView*)tableView
                                        atIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithButton *cell = [self buttonCellForTableView:tableView atIndexPath:indexPath];
    
    
    [cell.mxkButton setTitle:title forState:UIControlStateNormal];
    [cell.mxkButton setTitle:title forState:UIControlStateHighlighted];
    
    [cell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
    [cell.mxkButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    cell.mxkButton.accessibilityIdentifier = nil;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [self.tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor redColor];

    MXSession* session = self.mainSession;
    if (section == SECTION_PIN_CODE)
    {
        if (indexPath.row == PIN_CODE_SETTING)
        {
            if ([PinCodePreferences shared].forcePinProtection)
            {
                cell = [self getDefaultTableViewCell:tableView];
                cell.textLabel.text = NSLocalizedStringFromTable(@"pin_protection_settings_enabled_forced", @"Vector", nil);
            }
            else
            {
                MXKTableViewCellWithLabelAndSwitch *switchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                
                switchCell.mxkLabel.text = NSLocalizedStringFromTable(@"pin_protection_settings_enable_pin", @"Vector", nil);
                switchCell.mxkSwitch.on = [PinCodePreferences shared].isPinSet;
                [switchCell.mxkSwitch addTarget:self action:@selector(enablePinCodeSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
                
                cell = switchCell;
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (indexPath.row == PIN_CODE_DESCRIPTION)
        {
            if ([PinCodePreferences shared].isPinSet)
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:NSLocalizedStringFromTable(@"pin_protection_settings_section_footer", @"Vector", nil) ];
            }
            else
            {
                cell = [self descriptionCellForTableView:tableView withText:nil];
            }
        }
        else if (indexPath.row == PIN_CODE_CHANGE)
        {
            cell = [self buttonCellWithTitle:NSLocalizedStringFromTable(@"pin_protection_settings_change_pin", @"Vector", nil) action:@selector(changePinCode:  ) forTableView:tableView atIndexPath:indexPath];
        }
        else if (indexPath.row == PIN_CODE_BIOMETRICS)
        {
            MXKTableViewCellWithLabelAndSwitch *switchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            NSString *format = NSLocalizedStringFromTable(@"biometrics_settings_enable_x", @"Vector", nil);
            switchCell.mxkLabel.text = [NSString stringWithFormat:format, [PinCodePreferences shared].localizedBiometricsName];
            switchCell.mxkSwitch.on = [PinCodePreferences shared].isBiometricsSet;
            switchCell.mxkSwitch.enabled = [PinCodePreferences shared].isBiometricsAvailable;
            [switchCell.mxkSwitch addTarget:self action:@selector(enableBiometricsSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            cell = switchCell;
        }
    }
    else if (section == SECTION_CRYPTO_SESSIONS)
    {
        if (self.showLoadingDevicesInformation)
        {
            if (indexPath.row == 0)
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:NSLocalizedStringFromTable(@"security_settings_crypto_sessions_loading", @"Vector", nil) ];
            }
            else
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:NSLocalizedStringFromTable(@"security_settings_crypto_sessions_description_2", @"Vector", nil) ];
            }
        }
        else
        {
            if (row < devicesArray.count)
            {
                cell = [self deviceCellWithDevice:devicesArray[row] forTableView:tableView];
            }
            else if (row == devicesArray.count)
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:NSLocalizedStringFromTable(@"security_settings_crypto_sessions_description_2", @"Vector", nil) ];
                
            }
        }
    }
    else if (section == SECTION_SECURE_BACKUP)
    {
        switch ([self secureBackupSectionEnumForRow:row])
        {
            case SECURE_BACKUP_DESCRIPTION:
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:NSLocalizedStringFromTable(@"security_settings_secure_backup_description", @"Vector", nil)];
                break;
            }
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
            case SECURE_BACKUP_INFO:
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:self.secureBackupInformation];
                break;
            }
#endif
            case SECURE_BACKUP_SETUP:
            {
                MXKTableViewCellWithButton *buttonCell = [self buttonCellWithTitle:NSLocalizedStringFromTable(@"security_settings_secure_backup_setup", @"Vector", nil)
                                                                            action:@selector(setupSecureBackup)
                                                                      forTableView:tableView
                                                                       atIndexPath:indexPath];
                
                cell = buttonCell;
                break;
            }
            case SECURE_BACKUP_RESTORE:
            {
                MXKTableViewCellWithButton *buttonCell = [self buttonCellWithTitle:NSLocalizedStringFromTable(@"security_settings_secure_backup_synchronise", @"Vector", nil)
                                                                            action:@selector(restoreFromSecureBackup)
                                                                      forTableView:tableView
                                                                       atIndexPath:indexPath];
                
                cell = buttonCell;
                break;
            }
            case SECURE_BACKUP_DELETE:
            {
                MXKTableViewCellWithButton *buttonCell = [self buttonCellWithTitle:NSLocalizedStringFromTable(@"security_settings_secure_backup_delete", @"Vector", nil)
                                                                            action:@selector(deleteSecureBackup)
                                                                      forTableView:tableView
                                                                       atIndexPath:indexPath];
                buttonCell.mxkButton.tintColor = ThemeService.shared.theme.warningColor;
                
                cell = buttonCell;
                break;
            }
            
            case SECURE_BACKUP_MANAGE_MANUALLY:
            {
                MXKTableViewCellWithTextView *textCell = [self textViewCellForTableView:tableView atIndexPath:indexPath];
                textCell.mxkTextView.text = @"Advanced: Manually manage keys";  // TODO
                [textCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
                
                cell = textCell;
                break;
            }
        }

    }
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    else if (section == SECTION_KEYBACKUP)
    {
        cell = [keyBackupSection cellForRowAtRow:row];
    }
    else if (section == SECTION_CROSSSIGNING)
    {
        switch (row)
        {
            case CROSSSIGNING_INFO:
            {
                MXKTableViewCellWithTextView *cryptoCell = [self textViewCellForTableView:tableView atIndexPath:indexPath];
                cryptoCell.mxkTextView.attributedText = [self crossSigningInformation];
                cell = cryptoCell;
                break;
            }
            case CROSSSIGNING_FIRST_ACTION:
                cell = [self crossSigningButtonCellInTableView:tableView forAction:CROSSSIGNING_FIRST_ACTION];
                break;
            case CROSSSIGNING_SECOND_ACTION:
                cell = [self crossSigningButtonCellInTableView:tableView forAction:CROSSSIGNING_SECOND_ACTION];
                break;
        }
    }
#endif
    else if (section == SECTION_CRYPTOGRAPHY)
    {
        switch (row)
        {
            case CRYPTOGRAPHY_INFO:
            {
                MXKTableViewCellWithTextView *cryptoCell = [self textViewCellForTableView:tableView atIndexPath:indexPath];
                cryptoCell.mxkTextView.attributedText = [self cryptographyInformation];
                cell = cryptoCell;
                break;
            }
            case CRYPTOGRAPHY_EXPORT:
            {
                MXKTableViewCellWithButton *exportKeysBtnCell = [self buttonCellWithTitle:NSLocalizedStringFromTable(@"security_settings_export_keys_manually", @"Vector", nil)
                                                                                   action:@selector(exportEncryptionKeys:)
                                                                             forTableView:tableView
                                                                              atIndexPath:indexPath];
                cell = exportKeysBtnCell;
                break;
            }
        }
    }
    else if (section == SECTION_ADVANCED)
    {
        switch (row)
        {
            case ADVANCED_BLACKLIST_UNVERIFIED_DEVICES:
            {
                MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                
                labelAndSwitchCell.mxkLabel.text = NSLocalizedStringFromTable(@"security_settings_blacklist_unverified_devices", @"Vector", nil);
                labelAndSwitchCell.mxkSwitch.on = session.crypto.globalBlacklistUnverifiedDevices;
                labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
                labelAndSwitchCell.mxkSwitch.enabled = YES;
                [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleBlacklistUnverifiedDevices:) forControlEvents:UIControlEventValueChanged];
                
                cell = labelAndSwitchCell;
                break;
            }
            case ADVANCED_BLACKLIST_UNVERIFIED_DEVICES_DESCRIPTION:
            {
                cell = [self descriptionCellForTableView:tableView
                                                withText:NSLocalizedStringFromTable(@"security_settings_blacklist_unverified_devices_description", @"Vector", nil) ];
                
                break;
            }
        }
    }
    
    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    Section *tableSection = [self.tableViewSections sectionAtIndex:section];
    return tableSection.headerTitle;
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
    if (section == SECTION_CRYPTO_SESSIONS)
    {
        return 44;
    }
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
        NSIndexPath *tagsIndexPath = [self.tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
        NSInteger section = tagsIndexPath.section;
        NSInteger row = tagsIndexPath.row;

        if (section == SECTION_CRYPTO_SESSIONS)
        {
            NSUInteger deviceIndex = row;
            if (deviceIndex < devicesArray.count)
            {
                MXDevice *device = devicesArray[deviceIndex];
                
                if (self.mainSession.crypto.crossSigning.state == MXCrossSigningStateNotBootstrapped)
                {
                    // Display the device details. The verification will fail there.
                    ManageSessionViewController *viewController = [ManageSessionViewController instantiateWithMatrixSession:self.mainSession andDevice:device];
                    
                    [self pushViewController:viewController];
                }
                else if (self.mainSession.crypto.crossSigning.canCrossSign)
                {
                    ManageSessionViewController *viewController = [ManageSessionViewController instantiateWithMatrixSession:self.mainSession andDevice:device];
                    
                    [self pushViewController:viewController];
                }
                else
                {
                    if ([device.deviceId isEqualToString:self.mainSession.matrixRestClient.credentials.deviceId])
                    {
                        [self presentCompleteSecurity];
                    }
                    else
                    {
                        [self presentShouldCompleteSecurityAlert];
                    }
                }
            }
        }

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)presentCompleteSecurity
{
    [[AppDelegate theDelegate] presentCompleteSecurityForSession:self.mainSession];
}

- (void)presentShouldCompleteSecurityAlert
{
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"security_settings_complete_security_alert_title", @"Vector", nil)
                                                                             message:NSLocalizedStringFromTable(@"security_settings_complete_security_alert_message", @"Vector", nil)
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                    [self presentCompleteSecurity];
                                            }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"later", @"Vector", nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    currentAlert = alertController;
    [currentAlert mxk_setAccessibilityIdentifier: @"SettingsVCCompleteSecurity"];
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

- (void)enablePinCodeSwitchValueChanged:(UISwitch *)sender
{
    SetPinCoordinatorViewMode viewMode = sender.isOn ? SetPinCoordinatorViewModeSetPin : SetPinCoordinatorViewModeConfirmPinToDeactivate;
    self.setPinCoordinatorBridgePresenter = [[SetPinCoordinatorBridgePresenter alloc] initWithSession:self.mainSession viewMode:viewMode];
    self.setPinCoordinatorBridgePresenter.delegate = self;
    [self.setPinCoordinatorBridgePresenter presentFrom:self animated:YES];
}

- (void)enableBiometricsSwitchValueChanged:(UISwitch *)sender
{
    SetPinCoordinatorViewMode viewMode = sender.isOn ? SetPinCoordinatorViewModeSetupBiometricsFromSettings : SetPinCoordinatorViewModeConfirmBiometricsToDeactivate;
    self.setPinCoordinatorBridgePresenter = [[SetPinCoordinatorBridgePresenter alloc] initWithSession:self.mainSession viewMode:viewMode];
    self.setPinCoordinatorBridgePresenter.delegate = self;
    [self.setPinCoordinatorBridgePresenter presentFrom:self animated:YES];
}

- (void)changePinCode:(UIButton *)sender
{
    SetPinCoordinatorViewMode viewMode = SetPinCoordinatorViewModeChangePin;
    self.setPinCoordinatorBridgePresenter = [[SetPinCoordinatorBridgePresenter alloc] initWithSession:self.mainSession viewMode:viewMode];
    self.setPinCoordinatorBridgePresenter.delegate = self;
    [self.setPinCoordinatorBridgePresenter presentFrom:self animated:YES];
}

#pragma mark - SettingsKeyBackupTableViewSectionDelegate
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
- (void)settingsKeyBackupTableViewSectionDidUpdate:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection
{
    [self reloadData];
}

- (MXKTableViewCellWithTextView *)settingsKeyBackupTableViewSection:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection textCellForRow:(NSInteger)textCellForRow
{
    MXKTableViewCellWithTextView *cell;
    
    NSIndexPath *indexPath = [self.tableViewSections exactIndexPathForRowTag:textCellForRow sectionTag:SECTION_KEYBACKUP];
    
    if (indexPath)
    {
        cell = [self textViewCellForTableView:self.tableView atIndexPath:indexPath];
    }
    
    return cell;
}

- (MXKTableViewCellWithButton *)settingsKeyBackupTableViewSection:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection buttonCellForRow:(NSInteger)buttonCellForRow
{
    MXKTableViewCellWithButton *cell;
    
    NSIndexPath *indexPath = [self.tableViewSections exactIndexPathForRowTag:buttonCellForRow sectionTag:SECTION_KEYBACKUP];
    
    if (indexPath)
    {
        [self buttonCellForTableView:self.tableView atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)settingsKeyBackupTableViewSectionShowKeyBackupSetup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection
{
    [self showKeyBackupSetupFromSignOutFlow:NO];
}

- (void)settingsKeyBackup:(SettingsKeyBackupTableViewSection *)settingsKeyBackupTableViewSection showKeyBackupRecover:(MXKeyBackupVersion *)keyBackupVersion
{
    self.currentkeyBackupVersion = keyBackupVersion;
    
    // If key backup key is stored in SSSS ask for secrets recovery before restoring key backup.
    if (!self.mainSession.crypto.backup.hasPrivateKeyInCryptoStore
        && self.mainSession.crypto.recoveryService.hasRecovery
        && [self.mainSession.crypto.recoveryService hasSecretWithSecretId:MXSecretId.keyBackup])
    {
        [self showSecretsRecovery];
    }
    else
    {
        [self showKeyBackupRecover:keyBackupVersion fromViewController:self];
    }
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

#endif

#pragma mark - KeyBackupRecoverCoordinatorBridgePresenter

- (void)showKeyBackupRecover:(MXKeyBackupVersion*)keyBackupVersion fromViewController:(UIViewController*)presentingViewController
{
    keyBackupRecoverCoordinatorBridgePresenter = [[KeyBackupRecoverCoordinatorBridgePresenter alloc] initWithSession:self.mainSession keyBackupVersion:keyBackupVersion];

    [keyBackupRecoverCoordinatorBridgePresenter presentFrom:presentingViewController animated:true];
    keyBackupRecoverCoordinatorBridgePresenter.delegate = self;
}
    
- (void)pushKeyBackupRecover:(MXKeyBackupVersion*)keyBackupVersion fromNavigationController:(UINavigationController*)navigationController
{
    keyBackupRecoverCoordinatorBridgePresenter = [[KeyBackupRecoverCoordinatorBridgePresenter alloc] initWithSession:self.mainSession keyBackupVersion:keyBackupVersion];
    
    [keyBackupRecoverCoordinatorBridgePresenter pushFrom:navigationController animated:YES];
    keyBackupRecoverCoordinatorBridgePresenter.delegate = self;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidCancel:(KeyBackupRecoverCoordinatorBridgePresenter *)bridgePresenter {
    [keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:true];
    keyBackupRecoverCoordinatorBridgePresenter = nil;
    secretsRecoveryCoordinatorBridgePresenter = nil;
}

- (void)keyBackupRecoverCoordinatorBridgePresenterDidRecover:(KeyBackupRecoverCoordinatorBridgePresenter *)bridgePresenter {
    [keyBackupRecoverCoordinatorBridgePresenter dismissWithAnimated:true];
    keyBackupRecoverCoordinatorBridgePresenter = nil;
    secretsRecoveryCoordinatorBridgePresenter = nil;
}
    
#pragma mark - KeyBackupRecoverCoordinatorBridgePresenter
    
- (void)showSecretsRecovery
{
    secretsRecoveryCoordinatorBridgePresenter = [[SecretsRecoveryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession recoveryGoal:SecretsRecoveryGoalKeyBackup];
    
    [secretsRecoveryCoordinatorBridgePresenter presentFrom:self animated:true];
    secretsRecoveryCoordinatorBridgePresenter.delegate = self;
}

- (void)secretsRecoveryCoordinatorBridgePresenterDelegateDidCancel:(SecretsRecoveryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [secretsRecoveryCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    secretsRecoveryCoordinatorBridgePresenter = nil;
}

- (void)secretsRecoveryCoordinatorBridgePresenterDelegateDidComplete:(SecretsRecoveryCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    UIViewController *presentedViewController = [coordinatorBridgePresenter toPresentable];
    
    if (coordinatorBridgePresenter.recoveryGoal == SecretsRecoveryGoalKeyBackup)
    {
        // Go to the true key backup recovery screen
        if ([presentedViewController isKindOfClass:UINavigationController.class])
        {
            UINavigationController *navigationController = (UINavigationController*)self.presentedViewController;
            [self pushKeyBackupRecover:self.currentkeyBackupVersion fromNavigationController:navigationController];
        }
        else
        {
            [self showKeyBackupRecover:self.currentkeyBackupVersion fromViewController:presentedViewController];
        }
    }
    else
    {
        [secretsRecoveryCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
        secretsRecoveryCoordinatorBridgePresenter = nil;
    }
}

#pragma mark - SecureBackupSetupCoordinatorBridgePresenterDelegate

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

- (void)secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel:(SecureBackupSetupCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.secureBackupSetupCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.secureBackupSetupCoordinatorBridgePresenter = nil;
}

#pragma mark - SetPinCoordinatorBridgePresenterDelegate

- (void)setPinCoordinatorBridgePresenterDelegateDidComplete:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setPinCoordinatorBridgePresenterDelegateDidCancel:(SetPinCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableViewSectionsDelegate

- (void)tableViewSectionsDidUpdateSections:(TableViewSections *)sections
{
    [self.tableView reloadData];
}

@end
