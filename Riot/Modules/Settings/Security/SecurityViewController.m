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

#import <OLMKit/OLMKit.h>

#import "AvatarGenerator.h"

#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@import DesignKit;

// Dev flag to have more options
//#define CROSS_SIGNING_AND_BACKUP_DEV

enum
{
    SECTION_PIN_CODE,
    SECTION_CRYPTO_SESSIONS,
    SECTION_SECURE_BACKUP,
    SECTION_CROSSSIGNING,
    SECTION_CRYPTOGRAPHY,
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
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
    PIN_CODE_SETTING,
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
    ADVANCED_COUNT
};


@interface SecurityViewController () <
SettingsSecureBackupTableViewSectionDelegate,
KeyBackupSetupCoordinatorBridgePresenterDelegate,
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
SettingsKeyBackupTableViewSectionDelegate,
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
    
    SettingsSecureBackupTableViewSection *secureBackupSection;
    
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    SettingsKeyBackupTableViewSection *keyBackupSection;
#endif
    
    KeyBackupSetupCoordinatorBridgePresenter *keyBackupSetupCoordinatorBridgePresenter;
    KeyBackupRecoverCoordinatorBridgePresenter *keyBackupRecoverCoordinatorBridgePresenter;
    SecretsRecoveryCoordinatorBridgePresenter *secretsRecoveryCoordinatorBridgePresenter;
}

@property (nonatomic, strong) TableViewSections *tableViewSections;
@property (nonatomic) BOOL isLoadingDevices;
@property (nonatomic, strong) MXKeyBackupVersion *currentkeyBackupVersion;
@property (nonatomic, strong) SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter;
@property (nonatomic, strong) SetPinCoordinatorBridgePresenter *setPinCoordinatorBridgePresenter;
@property (nonatomic, strong) CrossSigningSetupCoordinatorBridgePresenter *crossSigningSetupCoordinatorBridgePresenter;

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

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
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenSettingsSecurity];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = [VectorL10n securitySettingsTitle];
    [self vc_removeBackTitle];

    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithTextView.nib forCellReuseIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithButton.nib forCellReuseIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
    [self.tableView registerNib:SectionFooterView.nib forHeaderFooterViewReuseIdentifier:[SectionFooterView defaultReuseIdentifier]];

    // Enable self sizing cells and footers
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 50;

    if (self.mainSession.crypto.backup)
    {
        MXDeviceInfo *deviceInfo = [self.mainSession.crypto deviceWithDeviceId:self.mainSession.myDeviceId ofUser:self.mainSession.myUserId];
        
        if (deviceInfo)
        {
            secureBackupSection = [[SettingsSecureBackupTableViewSection alloc] initWithRecoveryService:self.mainSession.crypto.recoveryService keyBackup:self.mainSession.crypto.backup userDevice:deviceInfo];
            secureBackupSection.delegate = self;
            
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
            keyBackupSection = [[SettingsKeyBackupTableViewSection alloc] initWithKeyBackup:self.mainSession.crypto.backup userDevice:deviceInfo];
            keyBackupSection.delegate = self;
#endif
        }
    }
    
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

    keyBackupSetupCoordinatorBridgePresenter = nil;
    keyBackupRecoverCoordinatorBridgePresenter = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.screenTracker trackScreen];

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

    BOOL isSecureBackupRequired = self.mainSession.vc_homeserverConfiguration.encryption.isSecureBackupRequired;
    
    // Pin code section
    
    Section *pinCodeSection = [Section sectionWithTag:SECTION_PIN_CODE];
    
    // Header and footer
    if ([PinCodePreferences shared].isBiometricsAvailable)
    {
        pinCodeSection.headerTitle = [VectorL10n pinProtectionSettingsSectionHeaderWithBiometrics:[PinCodePreferences shared].localizedBiometricsName];
    } else {
        pinCodeSection.headerTitle = [VectorL10n pinProtectionSettingsSectionHeader];
    }
    if (PinCodePreferences.shared.isPinSet)
    {
        pinCodeSection.footerTitle = VectorL10n.pinProtectionSettingsSectionFooter;
    }
    
    // Rows
    [pinCodeSection addRowWithTag:PIN_CODE_SETTING];
    
    if ([PinCodePreferences shared].isPinSet)
    {
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
        
        sessionsSection.headerTitle = [VectorL10n securitySettingsCryptoSessions];
        
        if (self.showLoadingDevicesInformation)
        {
            sessionsSection.footerTitle = VectorL10n.securitySettingsCryptoSessionsLoading;
        }
        else
        {
            sessionsSection.footerTitle = VectorL10n.securitySettingsCryptoSessionsDescription2;
            [sessionsSection addRowsWithCount:devicesArray.count];
        }
        
        [sections addObject:sessionsSection];
    }
    
    // Secure backup

    if (!isSecureBackupRequired)
    {
        Section *secureBackupSection = [Section sectionWithTag:SECTION_SECURE_BACKUP];
        secureBackupSection.headerTitle = [VectorL10n securitySettingsSecureBackup];
        secureBackupSection.footerTitle = VectorL10n.securitySettingsSecureBackupDescription;

        [secureBackupSection addRowsWithCount:self->secureBackupSection.numberOfRows];

        [sections addObject:secureBackupSection];
    }
    
    // Cross-Signing
    
    Section *crossSigningSection = [Section sectionWithTag:SECTION_CROSSSIGNING];
    crossSigningSection.headerTitle = [VectorL10n securitySettingsCrosssigning];
    
    [crossSigningSection addRowsWithCount:[self numberOfRowsInCrossSigningSection]];
    
    [sections addObject:crossSigningSection];
    
    // Cryptography
    
    Section *cryptographySection = [Section sectionWithTag:SECTION_CRYPTOGRAPHY];
    cryptographySection.headerTitle = [VectorL10n securitySettingsCryptography];
    
    if (RiotSettings.shared.settingsSecurityScreenShowCryptographyInfo)
    {
        [cryptographySection addRowWithTag:CRYPTOGRAPHY_INFO];
    }
    
    if (RiotSettings.shared.settingsSecurityScreenShowCryptographyExport && !isSecureBackupRequired)
    {
        [cryptographySection addRowWithTag:CRYPTOGRAPHY_EXPORT];
    }

    if (cryptographySection.rows.count)
    {
        [sections addObject:cryptographySection];
    }

#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    
    // Keybackup
    
    Section *keybackupSection = [Section sectionWithTag:SECTION_KEYBACKUP];
    keybackupSection.headerTitle = [VectorL10n securitySettingsBackup];
    
    [keybackupSection addRowsWithCount:self->keyBackupSection.numberOfRows];
    
    [sections addObject:keybackupSection];
        
#endif
    
    // Advanced
    
    if (RiotSettings.shared.settingsSecurityScreenShowAdvancedUnverifiedDevices)
    {
        Section *advancedSection = [Section sectionWithTag:SECTION_ADVANCED];
        advancedSection.headerTitle = VectorL10n.securitySettingsAdvanced;
        advancedSection.footerTitle = VectorL10n.securitySettingsBlacklistUnverifiedDevicesDescription;
        
        [advancedSection addRowWithTag:ADVANCED_BLACKLIST_UNVERIFIED_DEVICES];
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
                                                          initWithString:[VectorL10n settingsCryptoDeviceName]
                                                          attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                       NSFontAttributeName: [UIFont systemFontOfSize:17]}];
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:account.device.displayName ? account.device.displayName : @""
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];

    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:[VectorL10n settingsCryptoDeviceId]
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];
    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:account.device.deviceId ? account.device.deviceId : @""
                                                     attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textPrimaryColor,
                                                                  NSFontAttributeName: [UIFont systemFontOfSize:17]}]];

    [cryptoInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                     initWithString:[VectorL10n settingsCryptoDeviceKey]
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
        MXLogDebug(@"[SecurityVC] loadCrossSigning: Cannot refresh cross-signing state. Error: %@", error);
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
            crossSigningInformation = [VectorL10n securitySettingsCrosssigningInfoNotBootstrapped];
            break;
        case MXCrossSigningStateCrossSigningExists:
            crossSigningInformation = [VectorL10n securitySettingsCrosssigningInfoExists];
            break;
        case MXCrossSigningStateTrustCrossSigning:
            crossSigningInformation = [VectorL10n securitySettingsCrosssigningInfoTrusted];
            break;
        case MXCrossSigningStateCanCrossSign:
            crossSigningInformation = [VectorL10n securitySettingsCrosssigningInfoOk];
            
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
    NSString *btnTitle = [VectorL10n securitySettingsCrosssigningBootstrap];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
 
    [buttonCell.mxkButton addTarget:self action:@selector(setupCrossSigning:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupCrossSigning:(id)sender
{
    [self setupCrossSigningWithTitle:@"Set up cross-signing"    // TODO
                             message:[VectorL10n securitySettingsUserPasswordDescription]
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
    
    [alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    currentAlert = alertController;
}

- (void)setUpcrossSigningButtonCellForReset:(MXKTableViewCellWithButton*)buttonCell
{
    NSString *btnTitle = [VectorL10n securitySettingsCrosssigningReset];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
    
    buttonCell.mxkButton.tintColor = ThemeService.shared.theme.warningColor;
    
    [buttonCell.mxkButton addTarget:self action:@selector(resetCrossSigning:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpcrossSigningButtonCellForCompletingSecurity:(MXKTableViewCellWithButton*)buttonCell
{
    NSString *btnTitle = [VectorL10n securitySettingsCrosssigningCompleteSecurity];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
    [buttonCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
    
    [buttonCell.mxkButton addTarget:self action:@selector(presentCompleteSecurity) forControlEvents:UIControlEventTouchUpInside];
}

- (void)displayComingSoon
{
    [[AppDelegate theDelegate] showAlertWithTitle:nil message:[VectorL10n securitySettingsComingSoon:AppInfo.current.displayName :AppInfo.current.displayName]];
}


#pragma mark - SSSS

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
        [self setupCrossSigningWithTitle:[VectorL10n secureKeyBackupSetupIntroTitle]
                                 message:[VectorL10n securitySettingsUserPasswordDescription]
                                 success:^{
                                     [self setupSecureBackup2];
                                 } failure:^(NSError *error) {
                                 }];
    }
}

- (void)setupSecureBackup2
{
    SecureBackupSetupCoordinatorBridgePresenter *secureBackupSetupCoordinatorBridgePresenter = [[SecureBackupSetupCoordinatorBridgePresenter alloc] initWithSession:self.mainSession allowOverwrite:YES];
    secureBackupSetupCoordinatorBridgePresenter.delegate = self;
    
    [secureBackupSetupCoordinatorBridgePresenter presentFrom:self animated:YES];
    
    self.secureBackupSetupCoordinatorBridgePresenter = secureBackupSetupCoordinatorBridgePresenter;
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

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableView forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];

    cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
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
            return AssetImages.encryptionWarning.image;
        }
        else
        {
            return AssetImages.encryptionNormal.image;
        }
    }
    
    UIImage* shieldImageForDevice = AssetImages.encryptionWarning.image;
    MXDeviceInfo *device = [self.mainSession.crypto deviceWithDeviceId:deviceId ofUser:self.mainSession.myUser.userId];
    if (device.trustLevel.isVerified)
    {
        shieldImageForDevice = AssetImages.encryptionTrusted.image;
    }

    return shieldImageForDevice;
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
    NSInteger sectionTag = tagsIndexPath.section;
    NSInteger rowTag = tagsIndexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor redColor];

    MXSession* session = self.mainSession;
    if (sectionTag == SECTION_PIN_CODE)
    {
        if (rowTag == PIN_CODE_SETTING)
        {
            if ([PinCodePreferences shared].forcePinProtection)
            {
                cell = [self getDefaultTableViewCell:tableView];
                cell.textLabel.text = [VectorL10n pinProtectionSettingsEnabledForced];
            }
            else
            {
                MXKTableViewCellWithLabelAndSwitch *switchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                
                switchCell.mxkLabel.text = [VectorL10n pinProtectionSettingsEnablePin];
                switchCell.mxkSwitch.on = [PinCodePreferences shared].isPinSet;
                [switchCell.mxkSwitch addTarget:self action:@selector(enablePinCodeSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
                
                cell = switchCell;
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (rowTag == PIN_CODE_CHANGE)
        {
            cell = [self buttonCellWithTitle:[VectorL10n pinProtectionSettingsChangePin] action:@selector(changePinCode:) forTableView:tableView atIndexPath:indexPath];
        }
        else if (rowTag == PIN_CODE_BIOMETRICS)
        {
            MXKTableViewCellWithLabelAndSwitch *switchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            switchCell.mxkLabel.text = [VectorL10n biometricsSettingsEnableX:[PinCodePreferences shared].localizedBiometricsName];
            switchCell.mxkSwitch.on = [PinCodePreferences shared].isBiometricsSet;
            switchCell.mxkSwitch.enabled = [PinCodePreferences shared].isBiometricsAvailable;
            [switchCell.mxkSwitch addTarget:self action:@selector(enableBiometricsSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            cell = switchCell;
        }
    }
    else if (sectionTag == SECTION_CRYPTO_SESSIONS)
    {
        cell = [self deviceCellWithDevice:devicesArray[rowTag] forTableView:tableView];
    }
    else if (sectionTag == SECTION_SECURE_BACKUP)
    {
        cell = [secureBackupSection cellForRowAtRow:rowTag];
    }
#ifdef CROSS_SIGNING_AND_BACKUP_DEV
    else if (section == SECTION_KEYBACKUP)
    {
        cell = [keyBackupSection cellForRowAtRow:row];
    }
#endif
    else if (sectionTag == SECTION_CROSSSIGNING)
    {
        switch (rowTag)
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
    else if (sectionTag == SECTION_CRYPTOGRAPHY)
    {
        switch (rowTag)
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
                MXKTableViewCellWithButton *exportKeysBtnCell = [self buttonCellWithTitle:[VectorL10n securitySettingsExportKeysManually]
                                                                                   action:@selector(exportEncryptionKeys:)
                                                                             forTableView:tableView
                                                                              atIndexPath:indexPath];
                cell = exportKeysBtnCell;
                break;
            }
        }
    }
    else if (sectionTag == SECTION_ADVANCED)
    {
        switch (rowTag)
        {
            case ADVANCED_BLACKLIST_UNVERIFIED_DEVICES:
            {
                MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                
                labelAndSwitchCell.mxkLabel.text = [VectorL10n securitySettingsBlacklistUnverifiedDevices];
                labelAndSwitchCell.mxkSwitch.on = session.crypto.globalBlacklistUnverifiedDevices;
                labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
                labelAndSwitchCell.mxkSwitch.enabled = YES;
                [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleBlacklistUnverifiedDevices:) forControlEvents:UIControlEventValueChanged];
                
                cell = labelAndSwitchCell;
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
        tableViewHeaderFooterView.textLabel.textColor = ThemeService.shared.theme.colors.secondaryContent;
        tableViewHeaderFooterView.textLabel.font = ThemeService.shared.theme.fonts.footnote;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerTitle = [_tableViewSections sectionAtIndex:section].footerTitle;
    
    if (!footerTitle)
    {
        return nil;
    }
    
    SectionFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionFooterView.defaultReuseIdentifier];
    [view updateWithTheme:ThemeService.shared.theme];
    view.leadingInset = tableView.vc_separatorInset.left;
    [view updateWithText:footerTitle];
    
    return view;
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[VectorL10n securitySettingsCompleteSecurityAlertTitle]
                                                                             message:[VectorL10n securitySettingsCompleteSecurityAlertMessage]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                    [self presentCompleteSecurity];
                                            }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n later]
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
    keyExportsFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"element-keys.txt"]];

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


#pragma mark - SettingsSecureBackupTableViewSectionDelegate

- (void)settingsSecureBackupTableViewSectionDidUpdate:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection
{
    [self reloadData];
}

- (MXKTableViewCellWithTextView *)settingsSecureBackupTableViewSection:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection textCellForRow:(NSInteger)textCellForRow
{
    MXKTableViewCellWithTextView *cell;
    
    NSIndexPath *indexPath = [self.tableViewSections exactIndexPathForRowTag:textCellForRow sectionTag:SECTION_SECURE_BACKUP];
    
    if (indexPath)
    {
        cell = [self textViewCellForTableView:self.tableView atIndexPath:indexPath];
    }
    
    return cell;
}

- (MXKTableViewCellWithButton *)settingsSecureBackupTableViewSection:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection buttonCellForRow:(NSInteger)buttonCellForRow
{
    MXKTableViewCellWithButton *cell;
    
    NSIndexPath *indexPath = [self.tableViewSections exactIndexPathForRowTag:buttonCellForRow sectionTag:SECTION_SECURE_BACKUP];
    
    if (indexPath)
    {
        cell = [self buttonCellForTableView:self.tableView atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)settingsSecureBackupTableViewSectionShowSecureBackupReset:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection
{
    [self setupSecureBackup];
}

- (void)settingsSecureBackupTableViewSectionShowKeyBackupCreate:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection
{
    [self showKeyBackupSetupFromSignOutFlow:NO];
}

- (void)settingsSecureBackupTableViewSection:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection showKeyBackupRecover:(MXKeyBackupVersion *)keyBackupVersion
{
    self.currentkeyBackupVersion = keyBackupVersion;
    
    // If key backup key is stored in SSSS, ask for secrets recovery before restoring key backup.
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

- (void)settingsSecureBackupTableViewSection:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection showKeyBackupDeleteConfirm:(MXKeyBackupVersion *)keyBackupVersion
{
    MXWeakify(self);
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    currentAlert =
    [UIAlertController alertControllerWithTitle:[VectorL10n settingsKeyBackupDeleteConfirmationPromptTitle]
                                        message:[VectorL10n settingsKeyBackupDeleteConfirmationPromptMsg]
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
    }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n settingsKeyBackupButtonDelete]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
        
        [self->secureBackupSection deleteKeyBackupWithKeyBackupVersion:keyBackupVersion];
    }]];
    
    [currentAlert mxk_setAccessibilityIdentifier: @"SettingsVCDeleteKeyBackup"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)settingsSecureBackupTableViewSection:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection showActivityIndicator:(BOOL)show
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

- (void)settingsSecureBackupTableViewSection:(SettingsSecureBackupTableViewSection *)settingsSecureBackupTableViewSection showError:(NSError *)error
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
    
    [secureBackupSection reload];
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
        cell = [self buttonCellForTableView:self.tableView atIndexPath:indexPath];
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
    [UIAlertController alertControllerWithTitle:[VectorL10n  settingsKeyBackupDeleteConfirmationPromptTitle]
                                        message:[VectorL10n  settingsKeyBackupDeleteConfirmationPromptMsg]
                                 preferredStyle:UIAlertControllerStyleAlert];

    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self->currentAlert = nil;
                                                   }]];

    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n  settingsKeyBackupButtonDelete]
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
    secretsRecoveryCoordinatorBridgePresenter = [[SecretsRecoveryCoordinatorBridgePresenter alloc] initWithSession:self.mainSession recoveryGoal:SecretsRecoveryGoalBridgeKeyBackup];
    
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
    
    if (coordinatorBridgePresenter.recoveryGoal == SecretsRecoveryGoalBridgeKeyBackup)
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
