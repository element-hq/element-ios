/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "SettingsViewController.h"

#import "AvatarGenerator.h"

#import "BugReportViewController.h"

#import "WebViewViewController.h"

#import "CountryPickerViewController.h"
#import "LanguagePickerViewController.h"
#import "DeactivateAccountViewController.h"
#import "SecurityViewController.h"

#import "NBPhoneNumberUtil.h"
#import "RageShakeManager.h"
#import "ThemeService.h"
#import "TableViewCellWithPhoneNumberTextField.h"

#import "GBDeviceInfo_iOS.h"

#import "MediaPickerViewController.h"

#import "GeneratedInterface-Swift.h"

@import DesignKit;

NSString* const kSettingsViewControllerPhoneBookCountryCellId = @"kSettingsViewControllerPhoneBookCountryCellId";

typedef NS_ENUM(NSUInteger, SECTION_TAG)
{
    SECTION_TAG_SIGN_OUT = 0,
    SECTION_TAG_USER_SETTINGS,
    SECTION_TAG_ACCOUNT,
    SECTION_TAG_SENDING_MEDIA,
    SECTION_TAG_LINKS,
    SECTION_TAG_SECURITY,
    SECTION_TAG_NOTIFICATIONS,
    SECTION_TAG_CALLS,
    SECTION_TAG_DISCOVERY,
    SECTION_TAG_IDENTITY_SERVER,
    SECTION_TAG_LOCAL_CONTACTS,
    SECTION_TAG_IGNORED_USERS,
    SECTION_TAG_INTEGRATIONS,
    SECTION_TAG_USER_INTERFACE,
    SECTION_TAG_TIMELINE,
    SECTION_TAG_PRESENCE,
    SECTION_TAG_ADVANCED,
    SECTION_TAG_ABOUT,
    SECTION_TAG_LABS,
    SECTION_TAG_DEACTIVATE_ACCOUNT
};

typedef NS_ENUM(NSUInteger, USER_SETTINGS_INDEX)
{
    USER_SETTINGS_PROFILE_PICTURE_INDEX = 0,
    USER_SETTINGS_DISPLAYNAME_INDEX,
    USER_SETTINGS_CHANGE_PASSWORD_INDEX,
    USER_SETTINGS_FIRST_NAME_INDEX,
    USER_SETTINGS_SURNAME_INDEX,
    USER_SETTINGS_ADD_EMAIL_INDEX,
    USER_SETTINGS_ADD_PHONENUMBER_INDEX
};

typedef NS_ENUM(NSUInteger, USER_SETTINGS_OFFSET)
{
    USER_SETTINGS_EMAILS_OFFSET = 2000,
    USER_SETTINGS_PHONENUMBERS_OFFSET = 1000
};

typedef NS_ENUM(NSUInteger, SENDING_MEDIA)
{
    SENDING_MEDIA_CONFIRM_SIZE = 0
};

typedef NS_ENUM(NSUInteger, LINKS_SHOW_URL_PREVIEWS)
{
    LINKS_SHOW_URL_PREVIEWS_INDEX = 0,
    LINKS_SHOW_URL_PREVIEWS_DESCRIPTION_INDEX
};

typedef NS_ENUM(NSUInteger, NOTIFICATION_SETTINGS)
{
    NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX = 0,
    NOTIFICATION_SETTINGS_SYSTEM_SETTINGS,
    NOTIFICATION_SETTINGS_SHOW_IN_APP_INDEX,
    NOTIFICATION_SETTINGS_SHOW_DECODED_CONTENT,
    NOTIFICATION_SETTINGS_PIN_MISSED_NOTIFICATIONS_INDEX,
    NOTIFICATION_SETTINGS_PIN_UNREAD_INDEX,
    NOTIFICATION_SETTINGS_DEFAULT_SETTINGS_INDEX,
    NOTIFICATION_SETTINGS_MENTION_AND_KEYWORDS_SETTINGS_INDEX,
    NOTIFICATION_SETTINGS_OTHER_SETTINGS_INDEX,
};

typedef NS_ENUM(NSUInteger, CALLS_ENABLE_STUN_SERVER)
{
    CALLS_ENABLE_STUN_SERVER_FALLBACK_INDEX = 0
};

typedef NS_ENUM(NSUInteger, INTEGRATIONS)
{
    INTEGRATIONS_INDEX
};

typedef NS_ENUM(NSUInteger, LOCAL_CONTACTS)
{
    LOCAL_CONTACTS_SYNC_INDEX,
    LOCAL_CONTACTS_PHONEBOOK_COUNTRY_INDEX
};

typedef NS_ENUM(NSUInteger, USER_INTERFACE)
{
    USER_INTERFACE_LANGUAGE_INDEX = 0,
    USER_INTERFACE_THEME_INDEX
};

typedef NS_ENUM(NSUInteger, TIMELINE)
{
    TIMELINE_STYLE_INDEX,
    TIMELINE_SHOW_REDACTIONS_IN_ROOM_HISTORY_INDEX,
    TIMELINE_USE_ONLY_LATEST_USER_AVATAR_AND_NAME_INDEX
};

typedef NS_ENUM(NSUInteger, IDENTITY_SERVER)
{
    IDENTITY_SERVER_INDEX
};

typedef NS_ENUM(NSUInteger, PRESENCE)
{
    PRESENCE_OFFLINE_MODE = 0,
};

typedef NS_ENUM(NSUInteger, ADVANCED)
{
    ADVANCED_CRASH_REPORT_INDEX = 0,
    ADVANCED_ENABLE_RAGESHAKE_INDEX,
    ADVANCED_MARK_ALL_AS_READ_INDEX,
    ADVANCED_CLEAR_CACHE_INDEX,
    ADVANCED_REPORT_BUG_INDEX,
};

typedef NS_ENUM(NSUInteger, ABOUT)
{
    ABOUT_COPYRIGHT_INDEX = 0,
    ABOUT_ACCEPTABLE_USE_INDEX,
    ABOUT_PRIVACY_INDEX,
    ABOUT_THIRD_PARTY_INDEX,
};

typedef NS_ENUM(NSUInteger, LABS_ENABLE)
{
    LABS_ENABLE_RINGING_FOR_GROUP_CALLS_INDEX = 0,
    LABS_ENABLE_THREADS_INDEX,
    LABS_ENABLE_AUTO_REPORT_DECRYPTION_ERRORS,
    LABS_ENABLE_LIVE_LOCATION_SHARING,
    LABS_ENABLE_NEW_SESSION_MANAGER,
    LABS_ENABLE_NEW_CLIENT_INFO_FEATURE,
    LABS_ENABLE_WYSIWYG_COMPOSER,
    LABS_ENABLE_VOICE_BROADCAST
};

typedef NS_ENUM(NSUInteger, SECURITY)
{
    SECURITY_BUTTON_INDEX = 0,
    DEVICE_MANAGER_INDEX
};

typedef NS_ENUM(NSUInteger, ACCOUNT)
{
    ACCOUNT_MANAGE_INDEX = 0,
};

typedef void (^blockSettingsViewController_onReadyToDestroy)(void);

#pragma mark - SettingsViewController

@interface SettingsViewController () <UITextFieldDelegate, MXKCountryPickerViewControllerDelegate, MXKLanguagePickerViewControllerDelegate, DeactivateAccountViewControllerDelegate,
NotificationSettingsCoordinatorBridgePresenterDelegate,
SignOutFlowPresenterDelegate,
SingleImagePickerPresenterDelegate,
SettingsDiscoveryTableViewSectionDelegate, SettingsDiscoveryViewModelCoordinatorDelegate,
SettingsIdentityServerCoordinatorBridgePresenterDelegate,
ServiceTermsModalCoordinatorBridgePresenterDelegate,
TableViewSectionsDelegate,
ThreadsBetaCoordinatorBridgePresenterDelegate,
ChangePasswordCoordinatorBridgePresenterDelegate,
SSOAuthenticationPresenterDelegate>
{
    // Current alert (if any).
    __weak UIAlertController *currentAlert;
    
    // listener
    __weak id removedAccountObserver;
    __weak id accountUserInfoObserver;
    __weak id pushInfoUpdateObserver;
    
    __weak id notificationCenterWillUpdateObserver;
    __weak id notificationCenterDidUpdateObserver;
    __weak id notificationCenterDidFailObserver;
    
    // profile updates
    // avatar
    UIImage* newAvatarImage;
    // the avatar image has been uploaded
    NSString* uploadedAvatarURL;
    
    // new display name
    NSString* newDisplayName;

    // New email address to bind
    UITextField* newEmailTextField;
    
    // New phone number to bind
    TableViewCellWithPhoneNumberTextField * newPhoneNumberCell;
    CountryPickerViewController *newPhoneNumberCountryPicker;
    NBPhoneNumber *newPhoneNumber;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    __weak id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    __weak id kThemeServiceDidChangeThemeNotificationObserver;
    
    // Postpone destroy operation when saving or email binding is in progress
    BOOL isSavingInProgress;
    BOOL is3PIDBindingInProgress;
    blockSettingsViewController_onReadyToDestroy onReadyToDestroyHandler;
    
    BOOL keepNewEmailEditing;
    BOOL keepNewPhoneNumberEditing;
    
    // The current pushed view controller
    UIViewController *pushedViewController;

    SettingsIdentityServerCoordinatorBridgePresenter *identityServerSettingsCoordinatorBridgePresenter;
}

/**
 Flag indicating whether the user is typing an email to bind.
 */
@property (nonatomic) BOOL newEmailEditingEnabled;

/**
 Flag indicating whether the user is typing a phone number to bind.
 */
@property (nonatomic) BOOL newPhoneEditingEnabled;

/**
 The current `UNUserNotificationCenter` notification settings for the app.
 */
@property (nonatomic) UNNotificationSettings *systemNotificationSettings;

@property (nonatomic, weak) DeactivateAccountViewController *deactivateAccountViewController;

@property (nonatomic, strong) NotificationSettingsCoordinatorBridgePresenter *notificationSettingsBridgePresenter;

@property (nonatomic, strong) SignOutFlowPresenter *signOutFlowPresenter;
@property (nonatomic, weak) UIButton *signOutButton;
@property (nonatomic, strong) SingleImagePickerPresenter *imagePickerPresenter;

@property (nonatomic, strong) SettingsDiscoveryViewModel *settingsDiscoveryViewModel;
@property (nonatomic, strong) SettingsDiscoveryTableViewSection *settingsDiscoveryTableViewSection;
@property (nonatomic, strong) SettingsDiscoveryThreePidDetailsCoordinatorBridgePresenter *discoveryThreePidDetailsPresenter;

@property (nonatomic, strong) TableViewSections *tableViewSections;

@property (nonatomic, strong) ReauthenticationCoordinatorBridgePresenter *reauthenticationCoordinatorBridgePresenter;

@property (nonatomic, strong) UserInteractiveAuthenticationService *userInteractiveAuthenticationService;

@property (nonatomic, strong) ThreadsBetaCoordinatorBridgePresenter *threadsBetaBridgePresenter;
@property (nonatomic, strong) ChangePasswordCoordinatorBridgePresenter *changePasswordBridgePresenter;
@property (nonatomic, strong) UserSessionsFlowCoordinatorBridgePresenter *userSessionsFlowCoordinatorBridgePresenter;

/**
 Whether or not to check for contacts access after the user accepts the service terms. The value of this property is
 set automatically when calling `prepareIdentityServiceAndPresentTermsWithSession:checkingAccessForContactsOnAccept`
*/
@property (nonatomic) BOOL serviceTermsModalShouldCheckAccessForContactsOnAccept;
@property (nonatomic) BOOL isPreparingIdentityService;
@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;

@property (nonatomic, strong) SSOAuthenticationPresenter *ssoAuthenticationPresenter;

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@end

@implementation SettingsViewController

- (UserInteractiveAuthenticationService*)userInteractiveAuthenticationService
{
    if (!_userInteractiveAuthenticationService)
    {
        _userInteractiveAuthenticationService = [self createUserInteractiveAuthenticationService];
    }
    
    return _userInteractiveAuthenticationService;
}

+ (instancetype)instantiate
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    SettingsViewController *settingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    return settingsViewController;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    isSavingInProgress = NO;
    is3PIDBindingInProgress = NO;
    
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenSettings];
}

- (void)dealloc {
    // Fix for destroy not being called
    [self destroy];
}

- (void)updateSections
{
    NSMutableArray<Section*> *tmpSections = [NSMutableArray arrayWithCapacity:SECTION_TAG_DEACTIVATE_ACCOUNT + 1];
    
    Section *sectionSignOut = [Section sectionWithTag:SECTION_TAG_SIGN_OUT];
    [sectionSignOut addRowWithTag:0];
    [tmpSections addObject:sectionSignOut];
    
    Section *sectionUserSettings = [Section sectionWithTag:SECTION_TAG_USER_SETTINGS];
    [sectionUserSettings addRowWithTag:USER_SETTINGS_PROFILE_PICTURE_INDEX];
    [sectionUserSettings addRowWithTag:USER_SETTINGS_DISPLAYNAME_INDEX];
    if (RiotSettings.shared.settingsScreenShowChangePassword)
    {
        [sectionUserSettings addRowWithTag:USER_SETTINGS_CHANGE_PASSWORD_INDEX];
    }
    if (BuildSettings.settingsScreenShowUserFirstName)
    {
        [sectionUserSettings addRowWithTag:USER_SETTINGS_FIRST_NAME_INDEX];
    }
    if (BuildSettings.settingsScreenShowUserSurname)
    {
        [sectionUserSettings addRowWithTag:USER_SETTINGS_SURNAME_INDEX];
    }
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    //  add linked emails
    for (NSInteger index = 0; index < account.linkedEmails.count; index++)
    {
        [sectionUserSettings addRowWithTag: USER_SETTINGS_EMAILS_OFFSET + index];
    }
    //  add linked phone numbers
    for (NSInteger index = 0; index < account.linkedPhoneNumbers.count; index++)
    {
        [sectionUserSettings addRowWithTag: USER_SETTINGS_PHONENUMBERS_OFFSET + index];
    }
    // If the threePidChanges is nil we assume the capability to be true
    if (!self.mainSession.homeserverCapabilities.threePidChanges ||
        self.mainSession.homeserverCapabilities.threePidChanges.enabled) {
        if (BuildSettings.settingsScreenAllowAddingEmailThreepids)
        {
            [sectionUserSettings addRowWithTag:USER_SETTINGS_ADD_EMAIL_INDEX];
        }
        if (BuildSettings.settingsScreenAllowAddingPhoneThreepids)
        {
            [sectionUserSettings addRowWithTag:USER_SETTINGS_ADD_PHONENUMBER_INDEX];
        }
        if (BuildSettings.settingsScreenShowThreepidExplanatory)
        {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[VectorL10n settingsThreePidsManagementInformationPart1] attributes:@{}];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n settingsThreePidsManagementInformationPart2] attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.tintColor}]];
            [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n settingsThreePidsManagementInformationPart3] attributes:@{}]];
            sectionUserSettings.attributedFooterTitle = attributedString;
        }
    }
    
    sectionUserSettings.headerTitle = [VectorL10n settingsUserSettings];
    [tmpSections addObject:sectionUserSettings];
    
    NSString *manageAccountURL = self.mainSession.homeserverWellknown.authentication.account;
    if (manageAccountURL)
    {
        Section *account = [Section sectionWithTag: SECTION_TAG_ACCOUNT];
        [account addRowWithTag:ACCOUNT_MANAGE_INDEX];
        account.headerTitle = [VectorL10n settingsManageAccountTitle];
        account.footerTitle = [VectorL10n settingsManageAccountDescription:manageAccountURL];
        [tmpSections addObject:account];
    }
        
    if (BuildSettings.settingsScreenShowConfirmMediaSize)
    {
        Section *sectionMedia = [Section sectionWithTag:SECTION_TAG_SENDING_MEDIA];
        [sectionMedia addRowWithTag:SENDING_MEDIA_CONFIRM_SIZE];
        sectionMedia.headerTitle = [VectorL10n settingsSendingMedia];
        sectionMedia.footerTitle = VectorL10n.settingsConfirmMediaSizeDescription;
        [tmpSections addObject:sectionMedia];
    }
    
    Section *sectionLinks = [Section sectionWithTag:SECTION_TAG_LINKS];
    [sectionLinks addRowWithTag:LINKS_SHOW_URL_PREVIEWS_INDEX];
    sectionLinks.headerTitle = [VectorL10n settingsLinks];
    sectionLinks.footerTitle = VectorL10n.settingsShowUrlPreviewsDescription;
    [tmpSections addObject:sectionLinks];
    
    Section *sectionSecurity = [Section sectionWithTag:SECTION_TAG_SECURITY];
    [sectionSecurity addRowWithTag:SECURITY_BUTTON_INDEX];
        
    if (RiotSettings.shared.enableNewSessionManager)
    {
        // NOTE: Add device manager entry point in the security section atm for debug purpose
        [sectionSecurity addRowWithTag:DEVICE_MANAGER_INDEX];
    }
    
    sectionSecurity.headerTitle = [VectorL10n settingsSecurity];
    [tmpSections addObject:sectionSecurity];
    
    Section *sectionNotificationSettings = [Section sectionWithTag:SECTION_TAG_NOTIFICATIONS];
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX];
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_SYSTEM_SETTINGS];
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_SHOW_IN_APP_INDEX];
    if (RiotSettings.shared.settingsScreenShowNotificationDecodedContentOption)
    {
        [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_SHOW_DECODED_CONTENT];
    }

    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_PIN_MISSED_NOTIFICATIONS_INDEX];
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_PIN_UNREAD_INDEX];
    
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_DEFAULT_SETTINGS_INDEX];
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_MENTION_AND_KEYWORDS_SETTINGS_INDEX];
    [sectionNotificationSettings addRowWithTag:NOTIFICATION_SETTINGS_OTHER_SETTINGS_INDEX];

    sectionNotificationSettings.headerTitle = [VectorL10n settingsNotifications];
    [tmpSections addObject:sectionNotificationSettings];
    
    if (BuildSettings.allowVoIPUsage && BuildSettings.stunServerFallbackUrlString && RiotSettings.shared.settingsScreenShowEnableStunServerFallback)
    {
        Section *sectionCalls = [Section sectionWithTag:SECTION_TAG_CALLS];
        sectionCalls.headerTitle = [VectorL10n settingsCallsSettings];
        
        // Remove "stun:"
        NSString* stunFallbackHost = [BuildSettings.stunServerFallbackUrlString componentsSeparatedByString:@":"].lastObject;
        sectionCalls.footerTitle = [VectorL10n settingsCallsStunServerFallbackDescription:stunFallbackHost];

        [sectionCalls addRowWithTag:CALLS_ENABLE_STUN_SERVER_FALLBACK_INDEX];
        [tmpSections addObject:sectionCalls];
    }
    
    if (BuildSettings.settingsScreenShowDiscoverySettings)
    {
        Section *sectionDiscovery = [Section sectionWithTag:SECTION_TAG_DISCOVERY];
        NSInteger count = self.settingsDiscoveryTableViewSection.numberOfRows;
        for (NSInteger index = 0; index < count; index++)
        {
            [sectionDiscovery addRowWithTag:index];
        }
        sectionDiscovery.headerTitle = [VectorL10n settingsDiscoverySettings];
        sectionDiscovery.attributedFooterTitle = self.settingsDiscoveryTableViewSection.attributedFooterTitle;
        [tmpSections addObject:sectionDiscovery];
    }
    
    if (BuildSettings.settingsScreenAllowIdentityServerConfig)
    {
        Section *sectionIdentityServer = [Section sectionWithTag:SECTION_TAG_IDENTITY_SERVER];
        [sectionIdentityServer addRowWithTag:IDENTITY_SERVER_INDEX];
        
        sectionIdentityServer.headerTitle = [VectorL10n settingsIdentityServerSettings];
        sectionIdentityServer.footerTitle = account.mxSession.identityService.identityServer ? VectorL10n.settingsIdentityServerDescription : VectorL10n.settingsIdentityServerNoIsDescription;
        [tmpSections addObject:sectionIdentityServer];
    }
    
    if (BuildSettings.allowLocalContactsAccess)
    {
        Section *sectionLocalContacts = [Section sectionWithTag:SECTION_TAG_LOCAL_CONTACTS];
        [sectionLocalContacts addRowWithTag:LOCAL_CONTACTS_SYNC_INDEX];
        if (MXKAppSettings.standardAppSettings.syncLocalContacts)
        {
            [sectionLocalContacts addRowWithTag:LOCAL_CONTACTS_PHONEBOOK_COUNTRY_INDEX];
        }
        
        NSString *headerTitle = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? VectorL10n.settingsPhoneContacts : VectorL10n.settingsContacts;
        sectionLocalContacts.headerTitle = headerTitle;
        sectionLocalContacts.footerTitle = VectorL10n.settingsContactsEnableSyncDescription;
        [tmpSections addObject:sectionLocalContacts];
    }
    
    MXSession *session = [AppDelegate theDelegate].mxSessions.firstObject;
    if (session.ignoredUsers.count)
    {
        Section *sectionIgnoredUsers = [Section sectionWithTag:SECTION_TAG_IGNORED_USERS];
        for (NSInteger index = 0; index < session.ignoredUsers.count; index++)
        {
            [sectionIgnoredUsers addRowWithTag:index];
        }
        sectionIgnoredUsers.headerTitle = [VectorL10n settingsIgnoredUsers];
        [tmpSections addObject:sectionIgnoredUsers];
    }
    
    if (RiotSettings.shared.matrixApps)
    {
        Section *sectionIntegrations = [Section sectionWithTag:SECTION_TAG_INTEGRATIONS];
        [sectionIntegrations addRowWithTag:INTEGRATIONS_INDEX];
        sectionIntegrations.headerTitle = [VectorL10n settingsIntegrations];
        
        NSString *integrationManager = [WidgetManager.sharedManager configForUser:session.myUser.userId].apiUrl;
        NSString *integrationManagerDomain = [NSURL URLWithString:integrationManager].host;
        sectionIntegrations.footerTitle = [VectorL10n settingsIntegrationsAllowDescription:integrationManagerDomain];
        
        [tmpSections addObject:sectionIntegrations];
    }
    
    Section *sectionUserInterface = [Section sectionWithTag:SECTION_TAG_USER_INTERFACE];
    sectionUserInterface.headerTitle = [VectorL10n settingsUserInterface];
    
    [sectionUserInterface addRowWithTag:USER_INTERFACE_LANGUAGE_INDEX];
    [sectionUserInterface addRowWithTag:USER_INTERFACE_THEME_INDEX];
        
    [tmpSections addObject:sectionUserInterface];

    Section *sectionTimeline = [Section sectionWithTag:SECTION_TAG_TIMELINE];
    sectionTimeline.headerTitle = VectorL10n.settingsTimeline;

    if (BuildSettings.roomScreenAllowTimelineStyleConfiguration)
    {
        [sectionTimeline addRowWithTag:TIMELINE_STYLE_INDEX];
    }
    [sectionTimeline addRowWithTag:TIMELINE_SHOW_REDACTIONS_IN_ROOM_HISTORY_INDEX];
    [sectionTimeline addRowWithTag:TIMELINE_USE_ONLY_LATEST_USER_AVATAR_AND_NAME_INDEX];

    [tmpSections addObject:sectionTimeline];
    
    if(BuildSettings.settingsScreenPresenceAllowConfiguration)
    {
        Section *sectionPresence = [Section sectionWithTag:SECTION_TAG_PRESENCE];
        [sectionPresence addRowWithTag:PRESENCE_OFFLINE_MODE];
        sectionPresence.headerTitle = VectorL10n.settingsPresence;
        sectionPresence.footerTitle = VectorL10n.settingsPresenceOfflineModeDescription;

        [tmpSections addObject:sectionPresence];
    }
    
    Section *sectionAdvanced = [Section sectionWithTag:SECTION_TAG_ADVANCED];
    sectionAdvanced.headerTitle = [VectorL10n settingsAdvanced];
    
    if (BuildSettings.settingsScreenAllowChangingCrashUsageDataSettings)
    {
        [sectionAdvanced addRowWithTag:ADVANCED_CRASH_REPORT_INDEX];
    }
    if (BuildSettings.settingsScreenAllowChangingRageshakeSettings)
    {
        [sectionAdvanced addRowWithTag:ADVANCED_ENABLE_RAGESHAKE_INDEX];
    }
    [sectionAdvanced addRowWithTag:ADVANCED_MARK_ALL_AS_READ_INDEX];
    [sectionAdvanced addRowWithTag:ADVANCED_CLEAR_CACHE_INDEX];
    if (BuildSettings.settingsScreenAllowBugReportingManually)
    {
        [sectionAdvanced addRowWithTag:ADVANCED_REPORT_BUG_INDEX];
    }
    
    [tmpSections addObject:sectionAdvanced];
    
    Section *sectionAbout = [Section sectionWithTag:SECTION_TAG_ABOUT];
    if (BuildSettings.applicationCopyrightUrlString.length)
    {
        [sectionAbout addRowWithTag:ABOUT_COPYRIGHT_INDEX];
    }
    if (BuildSettings.applicationAcceptableUsePolicyUrlString.length)
    {
        [sectionAbout addRowWithTag:ABOUT_ACCEPTABLE_USE_INDEX];
    }
    if (BuildSettings.applicationPrivacyPolicyUrlString.length)
    {
        [sectionAbout addRowWithTag:ABOUT_PRIVACY_INDEX];
    }
    [sectionAbout addRowWithTag:ABOUT_THIRD_PARTY_INDEX];
    sectionAbout.headerTitle = VectorL10n.settingsAbout;

    if (BuildSettings.settingsScreenShowAdvancedSettings)
    {        
        sectionAbout.footerTitle = [self buildAboutSectionFooterTitleWithAccount:account];
    }
    
    [tmpSections addObject:sectionAbout];
    
    if (BuildSettings.settingsScreenShowLabSettings)
    {
        Section *sectionLabs = [Section sectionWithTag:SECTION_TAG_LABS];
        [sectionLabs addRowWithTag:LABS_ENABLE_RINGING_FOR_GROUP_CALLS_INDEX];
        [sectionLabs addRowWithTag:LABS_ENABLE_THREADS_INDEX];
        [sectionLabs addRowWithTag:LABS_ENABLE_AUTO_REPORT_DECRYPTION_ERRORS];
        if (BuildSettings.locationSharingEnabled)
        {
            [sectionLabs addRowWithTag:LABS_ENABLE_LIVE_LOCATION_SHARING];
        }
        [sectionLabs addRowWithTag:LABS_ENABLE_NEW_SESSION_MANAGER];
        [sectionLabs addRowWithTag:LABS_ENABLE_NEW_CLIENT_INFO_FEATURE];
        if (@available(iOS 15.0, *))
        {
            [sectionLabs addRowWithTag:LABS_ENABLE_WYSIWYG_COMPOSER];
        }
        [sectionLabs addRowWithTag:LABS_ENABLE_VOICE_BROADCAST];
        sectionLabs.headerTitle = [VectorL10n settingsLabs];
        if (sectionLabs.hasAnyRows)
        {
            [tmpSections addObject:sectionLabs];
        }
    }
    
    if (BuildSettings.settingsScreenAllowDeactivatingAccount && !self.mainSession.homeserverWellknown.authentication)
    {
        Section *sectionDeactivate = [Section sectionWithTag:SECTION_TAG_DEACTIVATE_ACCOUNT];
        [sectionDeactivate addRowWithTag:0];
        sectionDeactivate.headerTitle = [VectorL10n settingsDeactivateAccount];
        [tmpSections addObject:sectionDeactivate];
    }
    
    //  update sections
    _tableViewSections.sections = tmpSections;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = [VectorL10n settingsTitle];
    [self vc_removeBackTitle];

    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndMXKImageView.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithPhoneNumberTextField.class forCellReuseIdentifier:[TableViewCellWithPhoneNumberTextField defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithTextView.nib forCellReuseIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
    [self.tableView registerNib:SectionFooterView.nib forHeaderFooterViewReuseIdentifier:[SectionFooterView defaultReuseIdentifier]];
    
    // Enable self sizing cells and footers
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionFooterHeight = 50;
    
    MXWeakify(self);
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        if ([MXKAccountManager sharedManager].accounts.count)
        {
            // Refresh table to remove this account
            [self refreshSettings];
        }
        
    }];
    
    // Add observer to handle accounts update
    accountUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountUserInfoDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        
        [self refreshSettings];
        
    }];
    
    // Add observer to push settings
    pushInfoUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountAPNSActivityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        
        [self refreshSettings];
        
    }];

    [self registerAccountDataDidChangeIdentityServerNotification];
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    [self setupDiscoverySection];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSave:)];
    self.navigationItem.rightBarButtonItem.accessibilityIdentifier=@"SettingsVCNavBarSaveButton";

    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
    
    _tableViewSections = [TableViewSections new];
    _tableViewSections.delegate = self;
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
    
    if (self.tableView.dataSource)
    {
        [self refreshSettings];
    }

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
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }

    if (isSavingInProgress || is3PIDBindingInProgress)
    {
        __weak typeof(self) weakSelf = self;
        onReadyToDestroyHandler = ^() {
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                [self destroy];
            }
            
        };
    }
    else
    {
        // Dispose all resources
        [self reset];
        
        [super destroy];
    }
    
    identityServerSettingsCoordinatorBridgePresenter = nil;
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
    
    [self.screenTracker trackScreen];

    // Refresh display
    [self refreshSettings];

    // Refresh linked emails and phone numbers in parallel
    [self loadAccount3PIDs];
    
    MXWeakify(self);
        
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.adjustedContentInset.left, -self.tableView.adjustedContentInset.top) animated:YES];
        
    }];
    
    newPhoneNumberCountryPicker = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    [self.settingsDiscoveryTableViewSection reload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }

    if (notificationCenterWillUpdateObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationCenterWillUpdateObserver];
        notificationCenterWillUpdateObserver = nil;
    }
    
    if (notificationCenterDidUpdateObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationCenterDidUpdateObserver];
        notificationCenterDidUpdateObserver = nil;
    }
    
    if (notificationCenterDidFailObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationCenterDidFailObserver];
        notificationCenterDidFailObserver = nil;
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

- (void)dismissKeyboard
{
    [newEmailTextField resignFirstResponder];
    [newPhoneNumberCell.mxkTextField resignFirstResponder];
}

- (void)reset
{
    // Remove observers
    if (removedAccountObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:removedAccountObserver];
        removedAccountObserver = nil;
    }
    
    if (accountUserInfoObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:accountUserInfoObserver];
        accountUserInfoObserver = nil;
    }
    
    if (pushInfoUpdateObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:pushInfoUpdateObserver];
        pushInfoUpdateObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    onReadyToDestroyHandler = nil;
}

-(void)setNewEmailEditingEnabled:(BOOL)newEmailEditingEnabled
{
    if (newEmailEditingEnabled != _newEmailEditingEnabled)
    {
        // Update the flag
        _newEmailEditingEnabled = newEmailEditingEnabled;

        if (!newEmailEditingEnabled)
        {
            // Dismiss the keyboard
            [newEmailTextField resignFirstResponder];
            newEmailTextField = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView beginUpdates];
            
            // Refresh the corresponding table view cell with animation
            NSIndexPath *addEmailIndexPath = [self.tableViewSections exactIndexPathForRowTag:USER_SETTINGS_ADD_EMAIL_INDEX
                                                                                  sectionTag:SECTION_TAG_USER_SETTINGS];
            if (addEmailIndexPath)
            {
                [self.tableView reloadRowsAtIndexPaths:@[addEmailIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [self.tableView endUpdates];            
        });
    }
}

-(void)setNewPhoneEditingEnabled:(BOOL)newPhoneEditingEnabled
{
    if (newPhoneEditingEnabled != _newPhoneEditingEnabled)
    {
        // Update the flag
        _newPhoneEditingEnabled = newPhoneEditingEnabled;
        
        if (!newPhoneEditingEnabled)
        {
            // Dismiss the keyboard
            [newPhoneNumberCell.mxkTextField resignFirstResponder];
            newPhoneNumberCell = nil;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.tableView beginUpdates];
            
            // Refresh the corresponding table view cell with animation
            NSIndexPath *addPhoneIndexPath = [self.tableViewSections exactIndexPathForRowTag:USER_SETTINGS_ADD_PHONENUMBER_INDEX
                                                                                  sectionTag:SECTION_TAG_USER_SETTINGS];
            if (addPhoneIndexPath)
            {
                [self.tableView reloadRowsAtIndexPaths:@[addPhoneIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [self.tableView endUpdates];
        });
    }
}

- (void)showValidationEmailDialogWithMessage:(NSString*)message for3PidAddSession:(MX3PidAddSession*)threePidAddSession threePidAddManager:(MX3PidAddManager*)threePidAddManager authenticationParameters:(NSDictionary*)authenticationParameters
{
    MXWeakify(self);
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    UIAlertController *validationAlert = [UIAlertController alertControllerWithTitle:[VectorL10n accountEmailValidationTitle]
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    [validationAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        self->currentAlert = nil;
        [self stopActivityIndicator];

        // Reset new email adding
        self.newEmailEditingEnabled = NO;
    }]];

    [validationAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n continue] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        [self tryFinaliseAddEmailSession:threePidAddSession withAuthenticationParameters:authenticationParameters
                      threePidAddManager:threePidAddManager];
    }]];

    [validationAlert mxk_setAccessibilityIdentifier:@"SettingsVCEmailValidationAlert"];
    [self presentViewController:validationAlert animated:YES completion:nil];
    currentAlert = validationAlert;
}

- (void)tryFinaliseAddEmailSession:(MX3PidAddSession*)threePidAddSession withAuthenticationParameters:(NSDictionary*)authParams threePidAddManager:(MX3PidAddManager*)threePidAddManager
{
    self->is3PIDBindingInProgress = YES;
    
    [threePidAddManager tryFinaliseAddEmailSession:threePidAddSession authParams:authParams success:^{

        self->is3PIDBindingInProgress = NO;

        // Check whether destroy has been called during email binding
        if (self->onReadyToDestroyHandler)
        {
            // Ready to destroy
            self->onReadyToDestroyHandler();
            self->onReadyToDestroyHandler = nil;
        }
        else
        {
            self->currentAlert = nil;

            [self stopActivityIndicator];

            // Reset new email adding
            self.newEmailEditingEnabled = NO;

            // Update linked emails
            [self loadAccount3PIDs];
        }

    } failure:^(NSError * _Nonnull error) {
        MXLogDebug(@"[SettingsViewController] tryFinaliseAddEmailSession: Failed to bind email");

        MXError *mxError = [[MXError alloc] initWithNSError:error];
        if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringForbidden])
        {
            MXLogDebug(@"[SettingsViewController] tryFinaliseAddEmailSession: Wrong credentials");

            // Ask password again
            UIAlertController *passwordPrompt = [UIAlertController alertControllerWithTitle:nil
                                                                                    message:[VectorL10n settingsAdd3pidInvalidPasswordMessage]
                                                                             preferredStyle:UIAlertControllerStyleAlert];

            MXWeakify(self);
            [passwordPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n retry] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                
                [self showAuthenticationIfNeededForAdding:kMX3PIDMediumEmail withSession:self.mainSession completion:^(NSDictionary *authParams) {
                    [self tryFinaliseAddEmailSession:threePidAddSession withAuthenticationParameters:authParams threePidAddManager:threePidAddManager];
                }];
            }]];

            [self presentViewController:passwordPrompt animated:YES completion:nil];
            self->currentAlert = passwordPrompt;

            return;
        }

        self->is3PIDBindingInProgress = NO;

        // Check whether destroy has been called during email binding
        if (self->onReadyToDestroyHandler)
        {
            // Ready to destroy
            self->onReadyToDestroyHandler();
            self->onReadyToDestroyHandler = nil;
        }
        else
        {
            self->currentAlert = nil;

            // Display the same popup again if the error is M_THREEPID_AUTH_FAILED
            MXError *mxError = [[MXError alloc] initWithNSError:error];
            if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringThreePIDAuthFailed])
            {
                [self showValidationEmailDialogWithMessage:[VectorL10n accountEmailValidationError] for3PidAddSession:threePidAddSession threePidAddManager:threePidAddManager authenticationParameters:authParams];
            }
            else
            {
                [self stopActivityIndicator];

                // Notify user
                NSString *myUserId = self.mainSession.myUser.userId; // TODO: Hanlde multi-account
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
            }
        }
    }];
}

- (void)showValidationMsisdnDialogWithMessage:(NSString*)message for3PidAddSession:(MX3PidAddSession*)threePidAddSession threePidAddManager:(MX3PidAddManager*)threePidAddManager authenticationParameters:(NSDictionary*)authenticationParameters
{
    MXWeakify(self);
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    UIAlertController *validationAlert = [UIAlertController alertControllerWithTitle:[VectorL10n accountMsisdnValidationTitle]
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [validationAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);

        self->currentAlert = nil;

        [self stopActivityIndicator];

        // Reset new phone adding
        self.newPhoneEditingEnabled = NO;
    }]];

    [validationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = NO;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    [validationAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n submit] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {

        MXStrongifyAndReturnIfNil(self);

        NSString *smsCode = [self->currentAlert textFields].firstObject.text;

        self->currentAlert = nil;

        if (smsCode.length)
        {
            [self finaliseAddPhoneNumberSession:threePidAddSession withToken:smsCode andAuthenticationParameters:authenticationParameters message:message threePidAddManager:threePidAddManager];
        }
        else
        {
            // Ask again the sms token
            [self showValidationMsisdnDialogWithMessage:message for3PidAddSession:threePidAddSession threePidAddManager:threePidAddManager authenticationParameters:authenticationParameters];
        }
    }]];
    
    [validationAlert mxk_setAccessibilityIdentifier: @"SettingsVCMsisdnValidationAlert"];
    [self presentViewController:validationAlert animated:YES completion:nil];
    currentAlert = validationAlert;
}

- (void)finaliseAddPhoneNumberSession:(MX3PidAddSession*)threePidAddSession withToken:(NSString*)token andAuthenticationParameters:(NSDictionary*)authParams message:(NSString*)message threePidAddManager:(MX3PidAddManager*)threePidAddManager
{
    self->is3PIDBindingInProgress = YES;

    [threePidAddManager finaliseAddPhoneNumberSession:threePidAddSession withToken:token authParams:authParams success:^{
        
        self->is3PIDBindingInProgress = NO;

        // Check whether destroy has been called during the binding
        if (self->onReadyToDestroyHandler)
        {
            // Ready to destroy
            self->onReadyToDestroyHandler();
            self->onReadyToDestroyHandler = nil;
        }
        else
        {
            [self stopActivityIndicator];

            // Reset new phone adding
            self.newPhoneEditingEnabled = NO;

            // Update linked 3pids
            [self loadAccount3PIDs];
        }

    } failure:^(NSError * _Nonnull error) {

        MXLogDebug(@"[SettingsViewController] finaliseAddPhoneNumberSession: Failed to submit the sms token");
   
        MXError *mxError = [[MXError alloc] initWithNSError:error];
        if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringForbidden])
        {
            MXLogDebug(@"[SettingsViewController] finaliseAddPhoneNumberSession: Wrong authentication credentials");

            // Ask password again
            UIAlertController *passwordPrompt = [UIAlertController alertControllerWithTitle:nil
                                                                                    message:[VectorL10n settingsAdd3pidInvalidPasswordMessage]
                                                                             preferredStyle:UIAlertControllerStyleAlert];

            MXWeakify(self);
            [passwordPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n retry] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                
                [self showAuthenticationIfNeededForAdding:kMX3PIDMediumMSISDN withSession:self.mainSession completion:^(NSDictionary *authParams) {
                    [self finaliseAddPhoneNumberSession:threePidAddSession withToken:token andAuthenticationParameters:authParams message:message threePidAddManager:threePidAddManager];
                }];
            }]];

            [self presentViewController:passwordPrompt animated:YES completion:nil];
            self->currentAlert = passwordPrompt;

            return;
        }

        self->is3PIDBindingInProgress = NO;

        // Check whether destroy has been called during phone binding
        if (self->onReadyToDestroyHandler)
        {
            // Ready to destroy
            self->onReadyToDestroyHandler();
            self->onReadyToDestroyHandler = nil;
        }
        else
        {
            // Ignore connection cancellation error
            if (([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
            {
                [self stopActivityIndicator];
                return;
            }

            // Alert user
            NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
            NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            if (!title)
            {
                if (msg)
                {
                    title = msg;
                    msg = nil;
                }
                else
                {
                    title = [VectorL10n error];
                }
            }


            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];

            MXWeakify(self);
            [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;

                // Ask again the sms token
                [self showValidationMsisdnDialogWithMessage:message for3PidAddSession:threePidAddSession threePidAddManager:threePidAddManager authenticationParameters:authParams];
            }]];

            [errorAlert mxk_setAccessibilityIdentifier: @"SettingsVCErrorAlert"];
            [self presentViewController:errorAlert animated:YES completion:nil];
            self->currentAlert = errorAlert;
        }
    }];
}

- (void)loadAccount3PIDs
{
    // Refresh the account 3PIDs list
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account load3PIDs:^{

        NSArray<MXThirdPartyIdentifier*> *thirdPartyIdentifiers = account.threePIDs ?: @[];
        [self.settingsDiscoveryViewModel updateWithThirdPartyIdentifiers:thirdPartyIdentifiers];
        
        // Refresh all the table (A slide down animation is observed when we limit the refresh to the concerned section).
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];

    } failure:^(NSError *error) {
        
        // Display the data that has been loaded last time
        // Note: The use of 'reloadData' handles the case where the account has been logged out.
        [self refreshSettings];
        
    }];
}

- (void)editNewEmailTextField
{
    if (newEmailTextField && ![newEmailTextField becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editNewEmailTextField];
            
        });
    }
}

- (void)editNewPhoneNumberTextField
{
    if (newPhoneNumberCell && ![newPhoneNumberCell.mxkTextField becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editNewPhoneNumberTextField];
            
        });
    }
}

- (void)refreshSettings
{
    // Check whether a text input is currently edited
    keepNewEmailEditing = newEmailTextField ? newEmailTextField.isFirstResponder : NO;
    keepNewPhoneNumberEditing = newPhoneNumberCell ? newPhoneNumberCell.mxkTextField.isFirstResponder : NO;
    
    // Trigger a full table reloadData
    [self updateSections];
    
    // Restore the previous edited field
    if (keepNewEmailEditing)
    {
        [self editNewEmailTextField];
        keepNewEmailEditing = NO;
    }
    else if (keepNewPhoneNumberEditing)
    {
        [self editNewPhoneNumberTextField];
        keepNewPhoneNumberEditing = NO;
    }
    
    // Update notification access
    [self refreshSystemNotificationSettings];
    
    [[MXKAccountManager sharedManager].activeAccounts.firstObject loadCurrentPusher:nil failure:nil];
}

- (void)refreshSystemNotificationSettings
{
    MXWeakify(self);
    
    // Get the system notification settings to check authorization status and configuration.
    [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MXStrongifyAndReturnIfNil(self);
            
            self.systemNotificationSettings = settings;
            [self.tableView reloadData];
        });
    }];
}

- (void)formatNewPhoneNumber
{
    if (newPhoneNumber)
    {
        NSString *formattedNumber = [[NBPhoneNumberUtil sharedInstance] format:newPhoneNumber numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil];
        NSString *prefix = newPhoneNumberCell.mxkLabel.text;
        if ([formattedNumber hasPrefix:prefix])
        {
            // Format the display phone number
            newPhoneNumberCell.mxkTextField.text = [formattedNumber substringFromIndex:prefix.length];
        }
    }
}

- (void)setupDiscoverySection
{
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    
    NSArray<MXThirdPartyIdentifier*> *thirdPartyIdentifiers = account.threePIDs ?: @[];
    
    SettingsDiscoveryViewModel *viewModel = [[SettingsDiscoveryViewModel alloc] initWithSession:self.mainSession thirdPartyIdentifiers:thirdPartyIdentifiers];
    viewModel.coordinatorDelegate = self;
    
    SettingsDiscoveryTableViewSection *discoverySection = [[SettingsDiscoveryTableViewSection alloc] initWithViewModel:viewModel];
    discoverySection.delegate = self;
    
    self.settingsDiscoveryViewModel = viewModel;
    self.settingsDiscoveryTableViewSection = discoverySection;
}

- (UserInteractiveAuthenticationService*)createUserInteractiveAuthenticationService
{
    MXSession *session = self.mainSession;
    UserInteractiveAuthenticationService *userInteractiveAuthenticationService;
    
    if (session)
    {
        userInteractiveAuthenticationService = [[UserInteractiveAuthenticationService alloc] initWithSession:session];
    }
    
    return userInteractiveAuthenticationService;
}

- (void)scrollToDiscoverySection
{
    // settingsDiscoveryTableViewSection is a dynamic section, so check number of rows before scroll to avoid crashes
    if (self.settingsDiscoveryTableViewSection.numberOfRows > 0)
    {
        NSIndexPath *discoveryIndexPath = [_tableViewSections exactIndexPathForRowTag:0 sectionTag:SECTION_TAG_DISCOVERY];
        if (discoveryIndexPath)
        {
            [self.tableView scrollToRowAtIndexPath:discoveryIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
    else
    {
        //  this won't be precise in scroll location, but seems the best option for now
        NSIndexPath *discoveryIndexPath = [_tableViewSections nearestIndexPathForRowTag:0 sectionTag:SECTION_TAG_DISCOVERY];
        if (discoveryIndexPath)
        {
            [self.tableView scrollToRowAtIndexPath:discoveryIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

- (void)scrollToUserSettingsSection
{
    NSIndexPath *discoveryIndexPath = [_tableViewSections exactIndexPathForRowTag:USER_SETTINGS_ADD_EMAIL_INDEX
                                                         sectionTag:SECTION_TAG_USER_SETTINGS];
    if (discoveryIndexPath)
    {
        [self.tableView scrollToRowAtIndexPath:discoveryIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (NSString*)buildAboutSectionFooterTitleWithAccount:(MXKAccount*)account
{    
    NSMutableString *footerText = [NSMutableString new];
    
    AppInfo *appInfo = AppInfo.current;
    
    NSString *appName = appInfo.displayName;
    NSString *appVersion = appInfo.appVersion.bundleShortVersion;
    NSString *buildVersion = appInfo.appVersion.bundleVersion;
    
    NSString *appVersionInfo = [NSString stringWithFormat:@"%@ %@ (%@)", appName, appVersion, buildVersion];
 
    NSString *loggedUserInfo = [VectorL10n settingsConfigUserId:account.mxCredentials.userId];
    
    NSString *homeserverInfo = [VectorL10n settingsConfigHomeServer:account.mxCredentials.homeServer];       
    
    NSString *sdkVersionInfo = [NSString stringWithFormat:@"Matrix SDK %@", MatrixSDKVersion];
    
    [footerText appendFormat:@"%@\n", loggedUserInfo];
    [footerText appendFormat:@"%@\n", homeserverInfo];
    [footerText appendFormat:@"%@\n", appVersionInfo];
    [footerText appendFormat:@"%@\n", sdkVersionInfo];
    [footerText appendFormat:@"%@", self.mainSession.crypto.version];
    
    return [footerText copy];
}

- (UITableViewCell *)buildMessageBubblesCellForTableView:(UITableView*)tableView
                                             atIndexPath:(NSIndexPath*)indexPath
{
    MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
    labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsEnableRoomMessageBubbles];
    
    labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.roomScreenEnableMessageBubbles;
    labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
    labelAndSwitchCell.mxkSwitch.enabled = YES;
    [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableRoomMessageBubbles:) forControlEvents:UIControlEventTouchUpInside];
    
    return labelAndSwitchCell;
}

- (UITableViewCell *)buildAutoReportDecryptionErrorsCellForTableView:(UITableView*)tableView
                                             atIndexPath:(NSIndexPath*)indexPath
{
    MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
    labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableAutoReportDecryptionErrors];
    
    labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableUISIAutoReporting;
    labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
    labelAndSwitchCell.mxkSwitch.enabled = YES;
    [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableAutoReportDecryptionErrors:) forControlEvents:UIControlEventTouchUpInside];
    
    return labelAndSwitchCell;
}

- (UITableViewCell *)buildLiveLocationSharingCellForTableView:(UITableView*)tableView
                                                  atIndexPath:(NSIndexPath*)indexPath
{
    MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
    labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableLiveLocationSharing];
    
    labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableLiveLocationSharing;
    labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
    labelAndSwitchCell.mxkSwitch.enabled = YES;
    [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableLiveLocationSharing:) forControlEvents:UIControlEventTouchUpInside];
    
    return labelAndSwitchCell;
}

#pragma mark - 3Pid Add

- (void)showAuthenticationIfNeededForAdding:(MX3PIDMedium)medium withSession:(MXSession*)session completion:(void (^)(NSDictionary* authParams))completion
{
    [self startActivityIndicator];
    
    MXWeakify(self);
    
    void (^animationCompletion)(void) = ^void () {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        [self.reauthenticationCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{}];
        self.reauthenticationCoordinatorBridgePresenter = nil;
    };
        
    NSString *title;
    
    if ([medium isEqualToString:kMX3PIDMediumMSISDN])
    {
        title = [VectorL10n settingsAdd3pidPasswordTitleMsidsn];
    }
    else
    {
        title = [VectorL10n settingsAdd3pidPasswordTitleEmail];
    }
    
    NSString *message = [VectorL10n settingsAdd3pidPasswordMessage];
    
    
    [session.matrixRestClient add3PIDOnlyWithSessionId:@"" clientSecret:[MXTools generateSecret] authParams:nil success:^{
        
    } failure:^(NSError *error) {
        
        if (error)
        {
            [self.userInteractiveAuthenticationService authenticationSessionFromRequestError:error success:^(MXAuthenticationSession * _Nullable authenticationSession) {
                                
                if (authenticationSession)
                {
                    ReauthenticationCoordinatorParameters *coordinatorParameters = [[ReauthenticationCoordinatorParameters alloc] initWithSession:self.mainSession presenter:self title:title message:message authenticationSession:authenticationSession];
                    
                    ReauthenticationCoordinatorBridgePresenter *reauthenticationPresenter = [ReauthenticationCoordinatorBridgePresenter new];
                    
                    [reauthenticationPresenter presentWith:coordinatorParameters animated:YES success:^(NSDictionary<NSString *,id> *_Nullable authParams) {
                        completion(authParams);
                    } cancel:^{
                        animationCompletion();
                    } failure:^(NSError * _Nonnull error) {
                        animationCompletion();
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                    }];
                    
                    self.reauthenticationCoordinatorBridgePresenter = reauthenticationPresenter;
                }
                else
                {
                    animationCompletion();
                    completion(nil);
                }
            } failure:^(NSError * _Nonnull error) {
                animationCompletion();
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        }
        else
        {
            animationCompletion();
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }
    }];            
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
    // update the save button if there is an update
    [self updateSaveButtonStatus];
    
    return _tableViewSections.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Section *sectionObject = [_tableViewSections sectionAtIndex:section];
    return sectionObject.rows.count;
}

- (MXKTableViewCellWithLabelAndTextField*)getLabelAndTextFieldCell:(UITableView*)tableView forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndTextField *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
    cell.mxkTextFieldLeadingConstraint.constant = 16;
    cell.mxkTextFieldTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    cell.mxkTextField.userInteractionEnabled = YES;
    cell.mxkTextField.borderStyle = UITextBorderStyleNone;
    cell.mxkTextField.textAlignment = NSTextAlignmentRight;
    cell.mxkTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    cell.mxkTextField.tintColor = ThemeService.shared.theme.tintColor;
    cell.mxkTextField.font = [UIFont systemFontOfSize:16];
    cell.mxkTextField.placeholder = nil;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    cell.alpha = 1.0f;
    cell.userInteractionEnabled = YES;
    
    [cell layoutIfNeeded];
    
    return cell;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableView forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
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
    textViewCell.mxkTextViewLeadingConstraint.constant = tableView.vc_separatorInset.left;
    textViewCell.mxkTextViewTrailingConstraint.constant = tableView.vc_separatorInset.right;
    textViewCell.mxkTextView.accessibilityIdentifier = nil;
    
    return textViewCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor redColor];
    
    // check if there is a valid session
    if (([AppDelegate theDelegate].mxSessions.count == 0) || ([MXKAccountManager sharedManager].activeAccounts.count == 0))
    {
        // else use a default cell
        return cell;
    }
    
    MXSession* session = self.mainSession;
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;

    if (section == SECTION_TAG_SIGN_OUT)
    {
        MXKTableViewCellWithButton *signOutCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        if (!signOutCell)
        {
            signOutCell = [[MXKTableViewCellWithButton alloc] init];
        }
        else
        {
            // Fix https://github.com/vector-im/riot-ios/issues/1354
            // Do not move this line in prepareForReuse because of https://github.com/vector-im/riot-ios/issues/1323
            signOutCell.mxkButton.titleLabel.text = nil;
        }
        
        NSString* title = [VectorL10n settingsSignOut];
        
        [signOutCell.mxkButton setTitle:title forState:UIControlStateNormal];
        [signOutCell.mxkButton setTitle:title forState:UIControlStateHighlighted];
        [signOutCell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
        signOutCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
        
        [signOutCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [signOutCell.mxkButton addTarget:self action:@selector(onSignout:) forControlEvents:UIControlEventTouchUpInside];
        signOutCell.mxkButton.accessibilityIdentifier=@"SettingsVCSignOutButton";
        
        cell = signOutCell;
    }
    else if (section == SECTION_TAG_USER_SETTINGS)
    {
        MXMyUser* myUser = session.myUser;
        
        if (row == USER_SETTINGS_PROFILE_PICTURE_INDEX)
        {
            MXKTableViewCellWithLabelAndMXKImageView *profileCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            profileCell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
            profileCell.mxkImageViewTrailingConstraint.constant = 10;
            
            profileCell.mxkImageViewWidthConstraint.constant = profileCell.mxkImageViewHeightConstraint.constant = 30;
            profileCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
            
            if (!profileCell.mxkImageView.gestureRecognizers.count)
            {
                // tap on avatar to update it
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onProfileAvatarTap:)];
                [profileCell.mxkImageView addGestureRecognizer:tap];
            }
            
            profileCell.mxkLabel.text = [VectorL10n settingsProfilePicture];
            profileCell.accessibilityIdentifier=@"SettingsVCProfilPictureStaticText";
            profileCell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            // if the user defines a new avatar
            if (newAvatarImage)
            {
                profileCell.mxkImageView.image = newAvatarImage;
            }
            else
            {
                UIImage* avatarImage = [AvatarGenerator generateAvatarForMatrixItem:myUser.userId withDisplayName:myUser.displayname];
                
                if (myUser.avatarUrl)
                {
                    profileCell.mxkImageView.enableInMemoryCache = YES;
                    
                    [profileCell.mxkImageView setImageURI:myUser.avatarUrl
                                                 withType:nil
                                      andImageOrientation:UIImageOrientationUp
                                            toFitViewSize:profileCell.mxkImageView.frame.size
                                               withMethod:MXThumbnailingMethodCrop
                                             previewImage:avatarImage
                                             mediaManager:session.mediaManager];
                }
                else
                {
                    profileCell.mxkImageView.image = avatarImage;
                }
            }
            
            cell = profileCell;
        }
        else if (row == USER_SETTINGS_DISPLAYNAME_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *displaynameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            displaynameCell.mxkLabel.text = [VectorL10n settingsDisplayName];
            displaynameCell.mxkTextField.text = myUser.displayname;
            
            displaynameCell.mxkTextField.tag = row;
            displaynameCell.mxkTextField.delegate = self;
            [displaynameCell.mxkTextField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [displaynameCell.mxkTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            displaynameCell.mxkTextField.accessibilityIdentifier=@"SettingsVCDisplayNameTextField";
            
            cell = displaynameCell;
        }
        else if (row == USER_SETTINGS_FIRST_NAME_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *firstCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
        
            firstCell.mxkLabel.text = [VectorL10n settingsFirstName];
            firstCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = firstCell;
        }
        else if (row == USER_SETTINGS_SURNAME_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *surnameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            surnameCell.mxkLabel.text = [VectorL10n settingsSurname];
            surnameCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = surnameCell;
        }
        else if (row >= USER_SETTINGS_EMAILS_OFFSET)
        {
            NSInteger emailIndex = row - USER_SETTINGS_EMAILS_OFFSET;
            MXKTableViewCellWithLabelAndTextField *emailCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            emailCell.mxkLabel.text = [VectorL10n settingsEmailAddress];
            emailCell.mxkTextField.text = account.linkedEmails[emailIndex];
            emailCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = emailCell;
        }
        else if (row >= USER_SETTINGS_PHONENUMBERS_OFFSET)
        {
            NSInteger phoneNumberIndex = row - USER_SETTINGS_PHONENUMBERS_OFFSET;
            MXKTableViewCellWithLabelAndTextField *phoneCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            phoneCell.mxkLabel.text = [VectorL10n settingsPhoneNumber];
            
            phoneCell.mxkTextField.text = [MXKTools readableMSISDN:account.linkedPhoneNumbers[phoneNumberIndex]];
            phoneCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = phoneCell;
        }
        else if (row == USER_SETTINGS_ADD_EMAIL_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *newEmailCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];

            // Render the cell according to the `newEmailEditingEnabled` property
            if (!_newEmailEditingEnabled)
            {
                newEmailCell.mxkLabel.text = [VectorL10n settingsAddEmailAddress];
                newEmailCell.mxkTextField.text = nil;
                newEmailCell.mxkTextField.userInteractionEnabled = NO;
                newEmailCell.accessoryView = [[UIImageView alloc] initWithImage:[AssetImages.plusIcon.image vc_tintedImageUsingColor:ThemeService.shared.theme.textPrimaryColor]];
            }
            else
            {
                newEmailCell.mxkLabel.text = nil;
                newEmailCell.mxkTextField.placeholder = [VectorL10n settingsEmailAddressPlaceholder];
                newEmailCell.mxkTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                                   initWithString:newEmailCell.mxkTextField.placeholder
                                                                   attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
                newEmailCell.mxkTextField.text = newEmailTextField.text;
                newEmailCell.mxkTextField.userInteractionEnabled = YES;
                newEmailCell.mxkTextField.keyboardType = UIKeyboardTypeEmailAddress;
                newEmailCell.mxkTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                newEmailCell.mxkTextField.spellCheckingType = UITextSpellCheckingTypeNo;
                newEmailCell.mxkTextField.delegate = self;
                newEmailCell.mxkTextField.accessibilityIdentifier=@"SettingsVCAddEmailTextField";

                [newEmailCell.mxkTextField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                [newEmailCell.mxkTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

                [newEmailCell.mxkTextField removeTarget:self action:@selector(textFieldDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
                [newEmailCell.mxkTextField addTarget:self action:@selector(textFieldDidEnd:) forControlEvents:UIControlEventEditingDidEnd];

                // When displaying the textfield the 1st time, open the keyboard
                if (!newEmailTextField)
                {
                    newEmailTextField = newEmailCell.mxkTextField;
                    [self editNewEmailTextField];
                }
                else
                {
                    // Update the current text field.
                    newEmailTextField = newEmailCell.mxkTextField;
                }
                
                UIImage *accessoryViewImage = [AssetImages.plusIcon.image vc_tintedImageUsingColor:ThemeService.shared.theme.tintColor];
                newEmailCell.accessoryView = [[UIImageView alloc] initWithImage:accessoryViewImage];
            }
            
            newEmailCell.mxkTextField.tag = row;

            cell = newEmailCell;
        }
        else if (row == USER_SETTINGS_ADD_PHONENUMBER_INDEX)
        {
            // Render the cell according to the `newPhoneEditingEnabled` property
            if (!_newPhoneEditingEnabled)
            {
                MXKTableViewCellWithLabelAndTextField *newPhoneCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
                
                newPhoneCell.mxkLabel.text = [VectorL10n settingsAddPhoneNumber];
                newPhoneCell.mxkTextField.text = nil;
                newPhoneCell.mxkTextField.userInteractionEnabled = NO;
                newPhoneCell.accessoryView = [[UIImageView alloc] initWithImage:[AssetImages.plusIcon.image vc_tintedImageUsingColor:ThemeService.shared.theme.textPrimaryColor]];
                
                cell = newPhoneCell;
            }
            else
            {
                TableViewCellWithPhoneNumberTextField * newPhoneCell = [self.tableView dequeueReusableCellWithIdentifier:[TableViewCellWithPhoneNumberTextField defaultReuseIdentifier] forIndexPath:indexPath];
                
                [newPhoneCell.countryCodeButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
                [newPhoneCell.countryCodeButton addTarget:self action:@selector(selectPhoneNumberCountry:) forControlEvents:UIControlEventTouchUpInside];
                newPhoneCell.countryCodeButton.accessibilityIdentifier = @"SettingsVCPhoneCountryButton";
                
                newPhoneCell.mxkLabel.font = newPhoneCell.mxkTextField.font = [UIFont systemFontOfSize:16];
                
                newPhoneCell.mxkTextField.userInteractionEnabled = YES;
                newPhoneCell.mxkTextField.keyboardType = UIKeyboardTypePhonePad;
                newPhoneCell.mxkTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                newPhoneCell.mxkTextField.spellCheckingType = UITextSpellCheckingTypeNo;
                newPhoneCell.mxkTextField.delegate = self;
                newPhoneCell.mxkTextField.accessibilityIdentifier=@"SettingsVCAddPhoneTextField";
                
                [newPhoneCell.mxkTextField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                [newPhoneCell.mxkTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                
                [newPhoneCell.mxkTextField removeTarget:self action:@selector(textFieldDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
                [newPhoneCell.mxkTextField addTarget:self action:@selector(textFieldDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
                
                newPhoneCell.mxkTextField.tag = row;
                
                // When displaying the textfield the 1st time, open the keyboard
                if (!newPhoneNumberCell)
                {
                    NSString *countryCode = [MXKAppSettings standardAppSettings].phonebookCountryCode;
                    if (!countryCode)
                    {
                        // If none, consider the preferred locale
                        NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:[[NSBundle mainBundle] preferredLocalizations][0]];
                        if ([local respondsToSelector:@selector(countryCode)])
                        {
                            countryCode = local.countryCode;
                        }
                        
                        if (!countryCode)
                        {
                            countryCode = @"GB";
                        }
                    }
                    newPhoneCell.isoCountryCode = countryCode;
                    newPhoneCell.mxkTextField.text = nil;
                    
                    newPhoneNumberCell = newPhoneCell;

                    [self editNewPhoneNumberTextField];
                }
                else
                {
                    newPhoneCell.isoCountryCode = newPhoneNumberCell.isoCountryCode;
                    newPhoneCell.mxkTextField.text = newPhoneNumberCell.mxkTextField.text;
                    
                    newPhoneNumberCell = newPhoneCell;
                }
                
                UIImage *accessoryViewImage = [AssetImages.plusIcon.image vc_tintedImageUsingColor:ThemeService.shared.theme.tintColor];
                newPhoneCell.accessoryView = [[UIImageView alloc] initWithImage:accessoryViewImage];
                
                cell = newPhoneCell;
            }
        }
        else if (row == USER_SETTINGS_CHANGE_PASSWORD_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *passwordCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            passwordCell.mxkLabel.text = [VectorL10n settingsChangePassword];
            passwordCell.mxkTextField.text = @"*********";
            passwordCell.mxkTextField.userInteractionEnabled = NO;
            passwordCell.mxkLabel.accessibilityIdentifier=@"SettingsVCChangePwdStaticText";
            
            cell = passwordCell;
        }
    }
    else if (section == SECTION_TAG_SENDING_MEDIA)
    {
        if (row == SENDING_MEDIA_CONFIRM_SIZE)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsConfirmMediaSize];
            labelAndSwitchCell.mxkSwitch.on =  RiotSettings.shared.showMediaCompressionPrompt;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleConfirmMediaSize:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
    }
    else if (section == SECTION_TAG_LINKS)
    {
        if (row == LINKS_SHOW_URL_PREVIEWS_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsShowUrlPreviews];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.roomScreenShowsURLPreviews;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableURLPreviews:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == LINKS_SHOW_URL_PREVIEWS_DESCRIPTION_INDEX)
        {
            MXKTableViewCell *descriptionCell = [self getDefaultTableViewCell:tableView];
            descriptionCell.textLabel.text = [VectorL10n settingsShowUrlPreviewsDescription];
            descriptionCell.textLabel.numberOfLines = 0;
            descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;

            cell = descriptionCell;
        }
    }
    else if (section == SECTION_TAG_NOTIFICATIONS)
    {
        if (row == NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsEnablePushNotif];
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventTouchUpInside];
            
            BOOL isPushEnabled = account.pushNotificationServiceIsActive;
            
            // Even if push is enabled for the account, the user may have turned off notifications in system settings
            if (isPushEnabled && self.systemNotificationSettings)
            {
                isPushEnabled = self.systemNotificationSettings.authorizationStatus == UNAuthorizationStatusAuthorized;
            }
            
            labelAndSwitchCell.mxkSwitch.on = isPushEnabled;
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_SYSTEM_SETTINGS)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            }

            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

            cell.textLabel.text = [VectorL10n settingsDeviceNotifications];
            cell.detailTextLabel.text = @"";

            [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (row == NOTIFICATION_SETTINGS_SHOW_IN_APP_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = VectorL10n.settingsEnableInappNotifications;
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.showInAppNotifications;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = account.pushNotificationServiceIsActive;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleShowInAppNotifications:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_SHOW_DECODED_CONTENT)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsShowDecryptedContent];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.showDecryptedContentInNotifications;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = account.pushNotificationServiceIsActive;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleShowDecodedContent:) forControlEvents:UIControlEventTouchUpInside];
            
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_PIN_MISSED_NOTIFICATIONS_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsPinRoomsWithMissedNotif];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(togglePinRoomsWithMissedNotif:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_PIN_UNREAD_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsPinRoomsWithUnread];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(togglePinRoomsWithUnread:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == NOTIFICATION_SETTINGS_DEFAULT_SETTINGS_INDEX || row == NOTIFICATION_SETTINGS_MENTION_AND_KEYWORDS_SETTINGS_INDEX || row == NOTIFICATION_SETTINGS_OTHER_SETTINGS_INDEX)
        {
            cell = [self getDefaultTableViewCell:tableView];
            if (row == NOTIFICATION_SETTINGS_DEFAULT_SETTINGS_INDEX)
            {
                cell.textLabel.text = [VectorL10n settingsDefault];
            }
            else if (row == NOTIFICATION_SETTINGS_MENTION_AND_KEYWORDS_SETTINGS_INDEX)
            {
                cell.textLabel.text = [VectorL10n settingsMentionsAndKeywords];
            }
            else if (row == NOTIFICATION_SETTINGS_OTHER_SETTINGS_INDEX)
            {
                cell.textLabel.text = [VectorL10n settingsOther];
            }
            [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
        }
    }
    else if (section == SECTION_TAG_CALLS)
    {
        if (row == CALLS_ENABLE_STUN_SERVER_FALLBACK_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsCallsStunServerFallbackButton];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.allowStunServerFallback;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleStunServerFallback:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
    }
    else if (section == SECTION_TAG_DISCOVERY)
    {
        cell = [self.settingsDiscoveryTableViewSection cellForRowAtRow:row];
    }
    else if (section == SECTION_TAG_IDENTITY_SERVER)
    {
        switch (row)
        {
            case IDENTITY_SERVER_INDEX:
            {
                MXKTableViewCell *isCell = [self getDefaultTableViewCell:tableView];

                if (account.mxSession.identityService.identityServer)
                {
                    isCell.textLabel.text = account.mxSession.identityService.identityServer;
                }
                else
                {
                    isCell.textLabel.text = [VectorL10n settingsIdentityServerNoIs];
                }
                [isCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
                cell = isCell;
                break;
            }

            default:
                break;
        }
    }
    else if (section == SECTION_TAG_INTEGRATIONS)
    {
        switch (row) {
            case INTEGRATIONS_INDEX:
            {
                RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:session];

                MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsIntegrationsAllowButton];
                labelAndSwitchCell.mxkSwitch.on = sharedSettings.hasIntegrationProvisioningEnabled;
                labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
                labelAndSwitchCell.mxkSwitch.enabled = YES;
                [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleAllowIntegrations:) forControlEvents:UIControlEventTouchUpInside];

                cell = labelAndSwitchCell;
                break;
            }

            default:
                break;
        }
    }
    else if (section == SECTION_TAG_USER_INTERFACE)
    {
        if (row == USER_INTERFACE_LANGUAGE_INDEX)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            }

            NSString *language = [NSBundle mxk_language];
            if (!language)
            {
                language = [MXKLanguagePickerViewController defaultLanguage];
            }
            NSString *languageDescription = [MXKLanguagePickerViewController languageDescription:language];

            // Capitalise the description in the language locale
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:language];
            languageDescription = [languageDescription capitalizedStringWithLocale:locale];

            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

            cell.textLabel.text = [VectorL10n settingsUiLanguage];
            cell.detailTextLabel.text = languageDescription;

            [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (row == USER_INTERFACE_THEME_INDEX)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            }

            NSString *theme = RiotSettings.shared.userInterfaceTheme;
            
            if (!theme)
            {
                theme = @"auto";
            }

            theme = [NSString stringWithFormat:@"settings_ui_theme_%@", theme];
            NSString *i18nTheme = NSLocalizedStringFromTable(theme, @"Vector", nil);

            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

            cell.textLabel.text = [VectorL10n settingsUiTheme];
            cell.detailTextLabel.text = i18nTheme;

            [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else if (section == SECTION_TAG_TIMELINE)
    {
        if (row == TIMELINE_STYLE_INDEX)
        {
            cell = [self buildMessageBubblesCellForTableView:tableView atIndexPath:indexPath];
        }
        else if (row == TIMELINE_SHOW_REDACTIONS_IN_ROOM_HISTORY_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = VectorL10n.settingsUiShowRedactionsInRoomHistory;

            labelAndSwitchCell.mxkSwitch.on = [MXKAppSettings standardAppSettings].showRedactionsInRoomHistory;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleShowRedacted:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        else if (row == TIMELINE_USE_ONLY_LATEST_USER_AVATAR_AND_NAME_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = VectorL10n.settingsLabsUseOnlyLatestUserAvatarAndName;
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.roomScreenUseOnlyLatestUserAvatarAndName;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;

            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleUseOnlyLatestUserAvatarAndName:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
    }
    else if (section == SECTION_TAG_IGNORED_USERS)
    {
        MXKTableViewCell *ignoredUserCell = [self getDefaultTableViewCell:tableView];

        ignoredUserCell.textLabel.text = session.ignoredUsers[row];

        cell = ignoredUserCell;
    }
    else if (section == SECTION_TAG_LOCAL_CONTACTS)
    {
        if (row == LOCAL_CONTACTS_SYNC_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.numberOfLines = 0;
            labelAndSwitchCell.mxkLabel.text = VectorL10n.settingsContactsEnableSync;
            labelAndSwitchCell.mxkSwitch.on = [MXKAppSettings standardAppSettings].syncLocalContacts;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleLocalContactsSync:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        else if (row == LOCAL_CONTACTS_PHONEBOOK_COUNTRY_INDEX)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kSettingsViewControllerPhoneBookCountryCellId];
            }
            
            NSString* countryCode = [[MXKAppSettings standardAppSettings] phonebookCountryCode];
            NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:[[NSBundle mainBundle] preferredLocalizations][0]];
            NSString *countryName = [local displayNameForKey:NSLocaleCountryCode value:countryCode];
            
            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            cell.textLabel.text = [VectorL10n settingsContactsPhonebookCountry];
            cell.detailTextLabel.text = countryName;
            
            [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    else if (section == SECTION_TAG_PRESENCE)
    {
        if (row == PRESENCE_OFFLINE_MODE)
        {
            MXKTableViewCellWithLabelAndSwitch* labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = VectorL10n.settingsPresenceOfflineMode;
            
            MXKAccount *account = MXKAccountManager.sharedManager.accounts.firstObject;
            
            labelAndSwitchCell.mxkSwitch.on = account.preferredSyncPresence == MXPresenceOffline;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            labelAndSwitchCell.mxkSwitch.enabled = YES;
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(togglePresenceOfflineMode:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
    }
    else if (section == SECTION_TAG_ADVANCED)
    {
        if (row == ADVANCED_CRASH_REPORT_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* sendCrashReportCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            sendCrashReportCell.mxkLabel.text = VectorL10n.settingsAnalyticsAndCrashData;
            sendCrashReportCell.mxkSwitch.on = RiotSettings.shared.enableAnalytics;
            sendCrashReportCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            sendCrashReportCell.mxkSwitch.enabled = YES;
            [sendCrashReportCell.mxkSwitch addTarget:self action:@selector(toggleAnalytics:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = sendCrashReportCell;
        }
        else if (row == ADVANCED_ENABLE_RAGESHAKE_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* enableRageShakeCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            enableRageShakeCell.mxkLabel.text = [VectorL10n settingsEnableRageshake];
            enableRageShakeCell.mxkSwitch.on = RiotSettings.shared.enableRageShake;
            enableRageShakeCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            enableRageShakeCell.mxkSwitch.enabled = YES;
            [enableRageShakeCell.mxkSwitch addTarget:self action:@selector(toggleEnableRageShake:) forControlEvents:UIControlEventTouchUpInside];

            cell = enableRageShakeCell;
        }
        else if (row == ADVANCED_MARK_ALL_AS_READ_INDEX)
        {
            MXKTableViewCellWithButton *markAllBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!markAllBtnCell)
            {
                markAllBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                markAllBtnCell.mxkButton.titleLabel.text = nil;
            }
            
            NSString *btnTitle = [VectorL10n settingsMarkAllAsRead];
            [markAllBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [markAllBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [markAllBtnCell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
            markAllBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [markAllBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [markAllBtnCell.mxkButton addTarget:self action:@selector(markAllAsRead:) forControlEvents:UIControlEventTouchUpInside];
            markAllBtnCell.mxkButton.accessibilityIdentifier = nil;
            
            cell = markAllBtnCell;
        }
        else if (row == ADVANCED_CLEAR_CACHE_INDEX)
        {
            MXKTableViewCellWithButton *clearCacheBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!clearCacheBtnCell)
            {
                clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                clearCacheBtnCell.mxkButton.titleLabel.text = nil;
            }
            
            NSString *btnTitle = [VectorL10n settingsClearCache];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [clearCacheBtnCell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
            clearCacheBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [clearCacheBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [clearCacheBtnCell.mxkButton addTarget:self action:@selector(clearCache:) forControlEvents:UIControlEventTouchUpInside];
            clearCacheBtnCell.mxkButton.accessibilityIdentifier = nil;
            
            cell = clearCacheBtnCell;
        }
        else if (row == ADVANCED_REPORT_BUG_INDEX)
        {
            MXKTableViewCellWithButton *reportBugBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!reportBugBtnCell)
            {
                reportBugBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            else
            {
                // Fix https://github.com/vector-im/riot-ios/issues/1354
                reportBugBtnCell.mxkButton.titleLabel.text = nil;
            }

            NSString *btnTitle = [VectorL10n settingsReportBug];
            [reportBugBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [reportBugBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [reportBugBtnCell.mxkButton setTintColor:ThemeService.shared.theme.tintColor];
            reportBugBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];

            [reportBugBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [reportBugBtnCell.mxkButton addTarget:self action:@selector(reportBug:) forControlEvents:UIControlEventTouchUpInside];
            reportBugBtnCell.mxkButton.accessibilityIdentifier = nil;

            cell = reportBugBtnCell;
        }
    }
    else if (section == SECTION_TAG_ABOUT)
    {
        if (row == ABOUT_ACCEPTABLE_USE_INDEX)
        {
            MXKTableViewCell *termAndConditionCell = [self getDefaultTableViewCell:tableView];

            termAndConditionCell.textLabel.text = [VectorL10n settingsAcceptableUse];
            
            [termAndConditionCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            
            cell = termAndConditionCell;
        }
        else if (row == ABOUT_COPYRIGHT_INDEX)
        {
            MXKTableViewCell *copyrightCell = [self getDefaultTableViewCell:tableView];

            copyrightCell.textLabel.text = [VectorL10n settingsCopyright];
            
            [copyrightCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            
            cell = copyrightCell;
        }
        else if (row == ABOUT_PRIVACY_INDEX)
        {
            MXKTableViewCell *privacyPolicyCell = [self getDefaultTableViewCell:tableView];
            
            privacyPolicyCell.textLabel.text = [VectorL10n settingsPrivacyPolicy];
            
            [privacyPolicyCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            
            cell = privacyPolicyCell;
        }
        else if (row == ABOUT_THIRD_PARTY_INDEX)
        {
            MXKTableViewCell *thirdPartyCell = [self getDefaultTableViewCell:tableView];
            
            thirdPartyCell.textLabel.text = [VectorL10n settingsThirdPartyNotices];
            
            [thirdPartyCell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
            
            cell = thirdPartyCell;
        }
    }
    else if (section == SECTION_TAG_LABS)
    {
        if (row == LABS_ENABLE_RINGING_FOR_GROUP_CALLS_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableRingingForGroupCalls];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableRingingForGroupCalls;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableRingingForGroupCalls:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == LABS_ENABLE_THREADS_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableThreads];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableThreads;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            
            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableThreads:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = labelAndSwitchCell;
        }
        else if (row == LABS_ENABLE_AUTO_REPORT_DECRYPTION_ERRORS)
        {
            cell = [self buildAutoReportDecryptionErrorsCellForTableView:tableView atIndexPath:indexPath];
        }
        else if (row == LABS_ENABLE_LIVE_LOCATION_SHARING)
        {
            cell = [self buildLiveLocationSharingCellForTableView:tableView atIndexPath:indexPath];
        }
        else if (row == LABS_ENABLE_NEW_SESSION_MANAGER)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableNewSessionManager];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableNewSessionManager;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;

            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableNewSessionManager:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        else if (row == LABS_ENABLE_NEW_CLIENT_INFO_FEATURE)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableNewClientInfoFeature];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableClientInformationFeature;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;

            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableNewClientInfoFeature:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        else if (row == LABS_ENABLE_WYSIWYG_COMPOSER)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableWysiwygComposer];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableWysiwygComposer;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;

            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableWysiwygComposerFeature:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
        
        else if (row == LABS_ENABLE_VOICE_BROADCAST)
        {
            MXKTableViewCellWithLabelAndSwitch *labelAndSwitchCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            labelAndSwitchCell.mxkLabel.text = [VectorL10n settingsLabsEnableVoiceBroadcast];
            labelAndSwitchCell.mxkSwitch.on = RiotSettings.shared.enableVoiceBroadcast;
            labelAndSwitchCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;

            [labelAndSwitchCell.mxkSwitch addTarget:self action:@selector(toggleEnableVoiceBroadcastFeature:) forControlEvents:UIControlEventTouchUpInside];

            cell = labelAndSwitchCell;
        }
    }
    else if (section == SECTION_TAG_SECURITY)
    {
        switch (row)
        {
            case SECURITY_BUTTON_INDEX:
                cell = [self getDefaultTableViewCell:tableView];
                cell.textLabel.text = [VectorL10n securitySettingsTitle];
                [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
                break;
            case DEVICE_MANAGER_INDEX:
                cell = [self getDefaultTableViewCell:tableView];
                cell.textLabel.text = [VectorL10n userSessionsSettings];
                [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
                break;
        }
    }
    else if (section == SECTION_TAG_DEACTIVATE_ACCOUNT)
    {
        MXKTableViewCellWithButton *deactivateAccountBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        
        if (!deactivateAccountBtnCell)
        {
            deactivateAccountBtnCell = [[MXKTableViewCellWithButton alloc] init];
        }
        else
        {
            // Fix https://github.com/vector-im/riot-ios/issues/1354
            deactivateAccountBtnCell.mxkButton.titleLabel.text = nil;
        }
        
        NSString *btnTitle = [VectorL10n settingsDeactivateMyAccount];
        [deactivateAccountBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
        [deactivateAccountBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
        [deactivateAccountBtnCell.mxkButton setTintColor:ThemeService.shared.theme.warningColor];
        deactivateAccountBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
        
        [deactivateAccountBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [deactivateAccountBtnCell.mxkButton addTarget:self action:@selector(deactivateAccountAction) forControlEvents:UIControlEventTouchUpInside];
        deactivateAccountBtnCell.mxkButton.accessibilityIdentifier = nil;
        
        cell = deactivateAccountBtnCell;
    }
    else if (section == SECTION_TAG_ACCOUNT)
    {
        switch (row)
        {
            case ACCOUNT_MANAGE_INDEX:
                cell = [self getDefaultTableViewCell:tableView];
                cell.textLabel.text = [VectorL10n settingsManageAccountAction];
                [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];
                break;
        }
    }

    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    Section *sectionObj = [_tableViewSections sectionAtIndex:section];
    return sectionObj.headerTitle;
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
    NSAttributedString *attributedFooterTitle = [_tableViewSections sectionAtIndex:section].attributedFooterTitle;
    
    if (!attributedFooterTitle)
    {
        return nil;
    }
    
    SectionFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionFooterView.defaultReuseIdentifier];
    [view updateWithTheme:ThemeService.shared.theme];
    view.leadingInset = tableView.vc_separatorInset.left;
    [view updateWithAttributedText:attributedFooterTitle];
    
    if (section == SECTION_TAG_USER_SETTINGS)
    {
        UIGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToDiscoverySection)];
        [view addGestureRecognizer:recognizer];
    }
    else if (section == SECTION_TAG_DISCOVERY && self.settingsDiscoveryTableViewSection.footerShouldScrollToUserSettings)
    {
        UIGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollToUserSettingsSection)];
        [view addGestureRecognizer:recognizer];
    }
    
    return view;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;
    
    if (section == SECTION_TAG_USER_SETTINGS)
    {
        return row >= USER_SETTINGS_PHONENUMBERS_OFFSET;
    }
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
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

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;
    
    NSMutableArray* actions;
    
    // Add the swipe to delete user's email or phone number
    if (section == SECTION_TAG_USER_SETTINGS)
    {
        if (row >= USER_SETTINGS_PHONENUMBERS_OFFSET)
        {
            actions = [[NSMutableArray alloc] init];
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            CGFloat cellHeight = cell ? cell.frame.size.height : 50;
            
            // Patch: Force the width of the button by adding whitespace characters into the title string.
            UITableViewRowAction *leaveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"    "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self onRemove3PID:indexPath];
                
            }];
            
            leaveAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon_pink" backgroundColor:ThemeService.shared.theme.headerBackgroundColor patternSize:CGSizeMake(50, cellHeight) resourceSize:CGSizeMake(24, 24)];
            [actions insertObject:leaveAction atIndex:0];
        }
    }
    
    return actions;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
        NSInteger section = tagsIndexPath.section;
        NSInteger row = tagsIndexPath.row;

        if (section == SECTION_TAG_USER_INTERFACE)
        {
            if (row == USER_INTERFACE_LANGUAGE_INDEX)
            {
                // Display the language picker
                LanguagePickerViewController *languagePickerViewController = [LanguagePickerViewController languagePickerViewController];
                languagePickerViewController.selectedLanguage = [NSBundle mxk_language];
                languagePickerViewController.delegate = self;
                [self pushViewController:languagePickerViewController];
            }
            else if (row == USER_INTERFACE_THEME_INDEX)
            {
                [self showThemePicker];
            }
        }
        else if (section == SECTION_TAG_NOTIFICATIONS && row == NOTIFICATION_SETTINGS_SYSTEM_SETTINGS)
        {
            [self openSystemSettingsApp];
        }
        else if (section == SECTION_TAG_DISCOVERY)
        {
            [self.settingsDiscoveryTableViewSection selectRow:row];
        }
        else if (section == SECTION_TAG_IDENTITY_SERVER)
        {
            switch (row)
            {
                case IDENTITY_SERVER_INDEX:
                    [self showIdentityServerSettingsScreen];
                    break;
            }
        }
        else if (section == SECTION_TAG_IGNORED_USERS)
        {
            MXSession* session = self.mainSession;

            NSString *ignoredUserId = session.ignoredUsers[row];

            if (ignoredUserId)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];

                __weak typeof(self) weakSelf = self;
                
                UIAlertController *unignorePrompt = [UIAlertController alertControllerWithTitle:[VectorL10n settingsUnignoreUser:ignoredUserId] message:nil preferredStyle:UIAlertControllerStyleAlert];

                [unignorePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       MXSession* session = self.mainSession;
                                                                       
                                                                       // Remove the member from the ignored user list
                                                                       [self startActivityIndicator];
                                                                       [session unIgnoreUsers:@[ignoredUserId] success:^{
                                                                           
                                                                           [self stopActivityIndicator];
                                                                           
                                                                       } failure:^(NSError *error) {
                                                                           
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           MXLogDebug(@"[SettingsViewController] Unignore %@ failed", ignoredUserId);
                                                                           
                                                                           NSString *myUserId = session.myUser.userId;
                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                           
                                                                       }];
                                                                   }
                                                                   
                                                               }]];
                
                [unignorePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                   }
                                                                   
                                                               }]];
                
                [unignorePrompt mxk_setAccessibilityIdentifier: @"SettingsVCUnignoreAlert"];
                [self presentViewController:unignorePrompt animated:YES completion:nil];
                currentAlert = unignorePrompt;
            }
        }
        else if (section == SECTION_TAG_ABOUT)
        {
            if (row == ABOUT_COPYRIGHT_INDEX)
            {
                WebViewViewController *webViewViewController = [[WebViewViewController alloc] initWithURL:BuildSettings.applicationCopyrightUrlString];
                
                webViewViewController.title = [VectorL10n settingsCopyright];
                [webViewViewController vc_setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
                
                [self pushViewController:webViewViewController];
            }
            else if (row == ABOUT_ACCEPTABLE_USE_INDEX)
            {
                WebViewViewController *webViewViewController = [[WebViewViewController alloc] initWithURL:BuildSettings.applicationAcceptableUsePolicyUrlString];
                
                webViewViewController.title = [VectorL10n settingsAcceptableUse];
                [webViewViewController vc_setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
                
                [self pushViewController:webViewViewController];
            }
            else if (row == ABOUT_PRIVACY_INDEX)
            {
                WebViewViewController *webViewViewController = [[WebViewViewController alloc] initWithURL:BuildSettings.applicationPrivacyPolicyUrlString];
                
                webViewViewController.title = [VectorL10n settingsPrivacyPolicy];
                [webViewViewController vc_setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
                
                [self pushViewController:webViewViewController];
            }
            else if (row == ABOUT_THIRD_PARTY_INDEX)
            {
                NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"third_party_licenses" ofType:@"html" inDirectory:nil];

                WebViewViewController *webViewViewController = [[WebViewViewController alloc] initWithLocalHTMLFile:htmlFile];
                
                webViewViewController.title = [VectorL10n settingsThirdPartyNotices];
                [webViewViewController vc_setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
                
                [self pushViewController:webViewViewController];
            }
        }
        else if (section == SECTION_TAG_USER_SETTINGS)
        {
            if (row == USER_SETTINGS_PROFILE_PICTURE_INDEX)
            {
                [self onProfileAvatarTap:nil];
            }
            else if (row == USER_SETTINGS_CHANGE_PASSWORD_INDEX)
            {
                [self displayPasswordAlert];
            }
            else if (row == USER_SETTINGS_ADD_EMAIL_INDEX)
            {
                if (!self.newEmailEditingEnabled)
                {
                    // Enable the new email text field
                    self.newEmailEditingEnabled = YES;
                }
                else if (newEmailTextField)
                {
                    [self onAddNewEmail:newEmailTextField];
                }
            }
            else if (row == USER_SETTINGS_ADD_PHONENUMBER_INDEX)
            {
                if (!self.newPhoneEditingEnabled)
                {
                    // Enable the new phone text field
                    self.newPhoneEditingEnabled = YES;
                }
                else if (newPhoneNumberCell.mxkTextField)
                {
                    [self onAddNewPhone:newPhoneNumberCell.mxkTextField];
                }
            }
        }
        else if (section == SECTION_TAG_LOCAL_CONTACTS)
        {
            if (row == LOCAL_CONTACTS_PHONEBOOK_COUNTRY_INDEX)
            {
                CountryPickerViewController *countryPicker = [CountryPickerViewController countryPickerViewController];
                countryPicker.view.tag = SECTION_TAG_LOCAL_CONTACTS;
                countryPicker.delegate = self;
                countryPicker.showCountryCallingCode = YES;
                [self pushViewController:countryPicker];
            }
        }
        else if (section == SECTION_TAG_SECURITY)
        {
            switch (row)
            {
                case SECURITY_BUTTON_INDEX:
                {
                    SecurityViewController *securityViewController = [SecurityViewController instantiateWithMatrixSession:self.mainSession];

                    [self pushViewController:securityViewController];
                    break;
                }
                case DEVICE_MANAGER_INDEX:
                {
                    [self showUserSessionsFlow];
                    break;
                }
            }
        }
        else if (section == SECTION_TAG_NOTIFICATIONS)
        {
            switch (row) {
                case NOTIFICATION_SETTINGS_DEFAULT_SETTINGS_INDEX:
                    [self showNotificationSettings:NotificationSettingsScreenDefaultNotifications];
                    break;
                case NOTIFICATION_SETTINGS_MENTION_AND_KEYWORDS_SETTINGS_INDEX:
                    [self showNotificationSettings:NotificationSettingsScreenMentionsAndKeywords];
                    break;
                case NOTIFICATION_SETTINGS_OTHER_SETTINGS_INDEX:
                    [self showNotificationSettings:NotificationSettingsScreenOther];
                    break;
            }
        }
        else if (section == SECTION_TAG_ACCOUNT)
        {
            switch(row) {
                case ACCOUNT_MANAGE_INDEX:
                    [self onManageAccountTap];
                    break;
            }
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - actions


- (void)onSignout:(id)sender
{
    self.signOutButton = (UIButton*)sender;
    
    SignOutFlowPresenter *flowPresenter = [[SignOutFlowPresenter alloc] initWithSession:self.mainSession presentingViewController:self];
    flowPresenter.delegate = self;
    
    [flowPresenter startWithSourceView:self.signOutButton];
    self.signOutFlowPresenter = flowPresenter;
}

- (void)onRemove3PID:(NSIndexPath*)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;
    
    if (section == SECTION_TAG_USER_SETTINGS)
    {
        NSString *address, *medium;
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        NSString *promptMsg;
        
        if (row >= USER_SETTINGS_EMAILS_OFFSET)
        {
            medium = kMX3PIDMediumEmail;
            row = row - USER_SETTINGS_EMAILS_OFFSET;
            NSArray<NSString *> *linkedEmails = account.linkedEmails;
            if (row < linkedEmails.count)
            {
                address = linkedEmails[row];
                promptMsg = [VectorL10n settingsRemoveEmailPromptMsg:address];
            }
        }
        else if (row >= USER_SETTINGS_PHONENUMBERS_OFFSET)
        {
            medium = kMX3PIDMediumMSISDN;
            row = row - USER_SETTINGS_PHONENUMBERS_OFFSET;
            NSArray<NSString *> *linkedPhones = account.linkedPhoneNumbers;
            if (row < linkedPhones.count)
            {
                address = linkedPhones[row];
                NSString *e164 = [NSString stringWithFormat:@"+%@", address];
                NBPhoneNumber *phoneNb = [[NBPhoneNumberUtil sharedInstance] parse:e164 defaultRegion:nil error:nil];
                NSString *phoneNumber = [[NBPhoneNumberUtil sharedInstance] format:phoneNb numberFormat:NBEPhoneNumberFormatINTERNATIONAL error:nil];
                
                promptMsg = [VectorL10n settingsRemovePhonePromptMsg:phoneNumber];
            }
        }
        
        if (address && medium)
        {
            __weak typeof(self) weakSelf = self;
            
            if (currentAlert)
            {
                [currentAlert dismissViewControllerAnimated:NO completion:nil];
                currentAlert = nil;
            }
            
            // Remove ?
            UIAlertController *removePrompt = [UIAlertController alertControllerWithTitle:[VectorL10n settingsRemovePromptTitle] message:promptMsg preferredStyle:UIAlertControllerStyleAlert];
            
            [removePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                               }
                                                               
                                                           }]];
            
            [removePrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n remove]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   [self startActivityIndicator];
                                                                   
                                                                   [self.mainSession.matrixRestClient remove3PID:address medium:medium success:^{
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           // Update linked 3pids
                                                                           [self loadAccount3PIDs];
                                                                       }
                                                                       
                                                                   } failure:^(NSError *error) {
                                                                       
                                                                       MXLogDebug(@"[SettingsViewController] Remove 3PID: %@ failed", address);
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           
                                                                           [self stopActivityIndicator];
                                                                           
                                                                           NSString *myUserId = self.mainSession.myUser.userId; // TODO: Hanlde multi-account
                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                       }
                                                                   }];
                                                               }
                                                               
                                                           }]];
            
            [removePrompt mxk_setAccessibilityIdentifier: @"SettingsVCRemove3PIDAlert"];
            [self presentViewController:removePrompt animated:YES completion:nil];
            currentAlert = removePrompt;
        }
    }
}

- (void)toggleConfirmMediaSize:(UISwitch *)sender
{
    RiotSettings.shared.showMediaCompressionPrompt = sender.on;
}

- (void)togglePushNotifications:(UISwitch *)sender
{
    // Check first whether the user allow notification from system settings
    if (self.systemNotificationSettings.authorizationStatus == UNAuthorizationStatusDenied)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        __weak typeof(self) weakSelf = self;
        
        NSString *title = [VectorL10n settingsNotificationsDisabledAlertTitle];
        NSString *message = [VectorL10n settingsNotificationsDisabledAlertMessage];
        
        UIAlertController *showSettingsPrompt = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [showSettingsPrompt addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:[VectorL10n settings]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                            if (weakSelf)
                                                            {
                                                                typeof(self) self = weakSelf;
                                                                self->currentAlert = nil;
                                                                
                                                                [self openSystemSettingsApp];
                                                            }
                                                        }];
        
        [showSettingsPrompt addAction:settingsAction];
        showSettingsPrompt.preferredAction = settingsAction;
        
        [showSettingsPrompt mxk_setAccessibilityIdentifier: @"SettingsVCPushNotificationsAlert"];
        [self presentViewController:showSettingsPrompt animated:YES completion:nil];
        currentAlert = showSettingsPrompt;
        
        // Keep the the switch off.
        sender.on = NO;
    }
    else if ([MXKAccountManager sharedManager].activeAccounts.count)
    {
        [self startActivityIndicator];
        
        MXKAccountManager *accountManager = [MXKAccountManager sharedManager];
        MXKAccount* account = accountManager.activeAccounts.firstObject;

        if (accountManager.apnsDeviceToken)
        {
            [account enablePushNotifications:!account.pushNotificationServiceIsActive success:^{
                [self stopActivityIndicator];
            } failure:^(NSError *error) {
                [self stopActivityIndicator];
            }];
        }
        else
        {
            // Obtain device token when user has just enabled access to notifications from system settings
            [[AppDelegate theDelegate] registerForRemoteNotificationsWithCompletion:^(NSError * error) {
                if (error)
                {
                    [sender setOn:NO animated:YES];
                    [self stopActivityIndicator];
                }
                else
                {
                    [account enablePushNotifications:YES success:^{
                        [self stopActivityIndicator];
                    } failure:^(NSError *error) {
                        [self stopActivityIndicator];
                    }];
                }
            }];
        }
    }
}

- (void)toggleShowInAppNotifications:(UISwitch *)sender
{
    RiotSettings.shared.showInAppNotifications = sender.isOn;
}

- (void)openSystemSettingsApp
{
    NSURL *settingsAppURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:settingsAppURL options:@{} completionHandler:nil];
}

- (void)toggleCallKit:(UISwitch *)sender
{
    [MXKAppSettings standardAppSettings].enableCallKit = sender.isOn;
}

- (void)toggleStunServerFallback:(UISwitch *)sender
{
    RiotSettings.shared.allowStunServerFallback = sender.isOn;

    self.mainSession.callManager.fallbackSTUNServer = RiotSettings.shared.allowStunServerFallback ? BuildSettings.stunServerFallbackUrlString : nil;
}

- (void)toggleAllowIntegrations:(UISwitch *)sender
{
    MXSession *session = self.mainSession;
    [self startActivityIndicator];
    
    __block RiotSharedSettings *sharedSettings = [[RiotSharedSettings alloc] initWithSession:session];
    [sharedSettings setIntegrationProvisioningWithEnabled:sender.isOn success:^{
        sharedSettings = nil;
        [self stopActivityIndicator];
    } failure:^(NSError * _Nullable error) {
        sharedSettings = nil;
        [sender setOn:!sender.isOn animated:YES];
        [self stopActivityIndicator];
    }];
}

- (void)toggleShowDecodedContent:(UISwitch *)sender
{
    RiotSettings.shared.showDecryptedContentInNotifications = sender.isOn;
}

- (void)toggleLocalContactsSync:(UISwitch *)sender
{
    if (sender.on)
    {
        // First check if the service terms have already been accepted
        MXSession *session = self.mxSessions.firstObject;
        if (session.identityService.areAllTermsAgreed)
        {
            // If they have we only require local contacts access.
            [self checkAccessForContacts];
        }
        else
        {
            [self prepareIdentityServiceAndPresentTermsWithSession:session checkingAccessForContactsOnAccept:YES];
        }
    }
    else
    {
        [MXKAppSettings standardAppSettings].syncLocalContacts = NO;
        [self updateSections];
    }
}

- (void)toggleEnableURLPreviews:(UISwitch *)sender
{
    RiotSettings.shared.roomScreenShowsURLPreviews = sender.on;
    
    // Any loaded cell data is now invalid and should be refreshed for the new value.
    [[MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession] reset];
}

- (void)toggleAnalytics:(UISwitch *)sender
{
    if (sender.isOn)
    {
        MXLogDebug(@"[SettingsViewController] enable automatic crash report and analytics sending");
        [Analytics.shared optInWith:self.mainSession];
    }
    else
    {
        MXLogDebug(@"[SettingsViewController] disable automatic crash report and analytics sending");
        [Analytics.shared optOut];
        
        // Remove potential crash file.
        [MXLogger deleteCrashLog];
    }
}

- (void)toggleEnableRageShake:(UISwitch *)sender
{
    RiotSettings.shared.enableRageShake = sender.isOn;
    
    [self updateSections];
}

- (void)toggleEnableRingingForGroupCalls:(UISwitch *)sender
{
    RiotSettings.shared.enableRingingForGroupCalls = sender.isOn;
}

- (void)toggleEnableThreads:(UISwitch *)sender
{
    if (sender.isOn && !self.mainSession.store.supportedMatrixVersions.supportsThreads)
    {
        //  user wants to turn on the threads setting but the server does not support it
        if (self.threadsBetaBridgePresenter)
        {
            [self.threadsBetaBridgePresenter dismissWithAnimated:YES completion:nil];
            self.threadsBetaBridgePresenter = nil;
        }

        self.threadsBetaBridgePresenter = [[ThreadsBetaCoordinatorBridgePresenter alloc] initWithThreadId:@""
                                                                                                 infoText:VectorL10n.threadsDiscourageInformation1
                                                                                           additionalText:VectorL10n.threadsDiscourageInformation2];
        self.threadsBetaBridgePresenter.delegate = self;

        [self.threadsBetaBridgePresenter presentFrom:self.presentedViewController?:self animated:YES];
        return;
    }

    [self enableThreads:sender.isOn];
}

- (void)enableThreads:(BOOL)enable
{
    RiotSettings.shared.enableThreads = enable;
    MXSDKOptions.sharedInstance.enableThreads = enable;
    [[MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession] reset];
    [[AppDelegate theDelegate] restoreEmptyDetailsViewController];
}

- (void)toggleEnableNewSessionManager:(UISwitch *)sender
{
    RiotSettings.shared.enableNewSessionManager = sender.isOn;
    [self updateSections];
}

- (void)toggleEnableNewClientInfoFeature:(UISwitch *)sender
{
    BOOL isEnabled = sender.isOn;
    RiotSettings.shared.enableClientInformationFeature = isEnabled;
    MXSDKOptions.sharedInstance.enableNewClientInformationFeature = isEnabled;
    [self.mainSession updateClientInformation];
}

- (void)toggleEnableWysiwygComposerFeature:(UISwitch *)sender
{
    RiotSettings.shared.enableWysiwygComposer = sender.isOn;
}

- (void)toggleEnableVoiceBroadcastFeature:(UISwitch *)sender
{
    RiotSettings.shared.enableVoiceBroadcast = sender.isOn;
}

- (void)togglePinRoomsWithMissedNotif:(UISwitch *)sender
{
    RiotSettings.shared.pinRoomsWithMissedNotificationsOnHome = sender.isOn;
}

- (void)togglePinRoomsWithUnread:(UISwitch *)sender
{
    RiotSettings.shared.pinRoomsWithUnreadMessagesOnHome = sender.on;
}

- (void)toggleUseOnlyLatestUserAvatarAndName:(UISwitch *)sender
{
    RiotSettings.shared.roomScreenUseOnlyLatestUserAvatarAndName = sender.isOn;
}

- (void)markAllAsRead:(id)sender
{
    // Feedback: disable button and run activity indicator
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;
    [self startActivityIndicator];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [[AppDelegate theDelegate] markAllMessagesAsRead];
        
        [self stopActivityIndicator];
        button.enabled = YES;
        
    });
}

- (void)clearCache:(id)sender
{
    // Feedback: disable button and run activity indicator
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;

    [self launchClearCache];
}

- (void)launchClearCache
{
    [self startActivityIndicator];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

        [[AppDelegate theDelegate] reloadMatrixSessions:YES];

    });
}

- (void)reportBug:(id)sender
{
    BugReportViewController *bugReportViewController = [BugReportViewController bugReportViewController];
    [bugReportViewController showInViewController:self];
}

- (void)selectPhoneNumberCountry:(id)sender
{
    newPhoneNumberCountryPicker = [CountryPickerViewController countryPickerViewController];
    newPhoneNumberCountryPicker.view.tag = SECTION_TAG_USER_SETTINGS;
    newPhoneNumberCountryPicker.delegate = self;
    newPhoneNumberCountryPicker.showCountryCallingCode = YES;
    [self pushViewController:newPhoneNumberCountryPicker];
}

- (void)onSave:(id)sender
{
    // sanity check
    if ([MXKAccountManager sharedManager].activeAccounts.count == 0)
    {
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self startActivityIndicator];
    isSavingInProgress = YES;
    __weak typeof(self) weakSelf = self;
    
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    MXMyUser* myUser = account.mxSession.myUser;
    
    if (newDisplayName && ![myUser.displayname isEqualToString:newDisplayName])
    {
        // Save display name
        [account setUserDisplayName:newDisplayName success:^{
            
            if (weakSelf)
            {
                // Update the current displayname
                typeof(self) self = weakSelf;
                self->newDisplayName = nil;
                
                // Go to the next change saving step
                [self onSave:nil];
            }
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[SettingsViewController] Failed to set displayName");
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                [self handleErrorDuringProfileChangeSaving:error];
            }
            
        }];
        
        return;
    }
    
    if (newAvatarImage)
    {
        // Retrieve the current picture and make sure its orientation is up
        UIImage *updatedPicture = [MXKTools forceImageOrientationUp:newAvatarImage];
        
        // Upload picture
        MXMediaLoader *uploader = [MXMediaManager prepareUploaderWithMatrixSession:account.mxSession initialRange:0 andRange:1.0];
        
        [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url) {
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                
                // Store uploaded picture url and trigger picture saving
                self->uploadedAvatarURL = url;
                self->newAvatarImage = nil;
                [self onSave:nil];
            }
            
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[SettingsViewController] Failed to upload image");
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                [self handleErrorDuringProfileChangeSaving:error];
            }
            
        }];
        
        return;
    }
    else if (uploadedAvatarURL)
    {
        [account setUserAvatarUrl:uploadedAvatarURL
                             success:^{
                                 
                                 if (weakSelf)
                                 {
                                     typeof(self) self = weakSelf;
                                     self->uploadedAvatarURL = nil;
                                     [self onSave:nil];
                                 }
                                 
                             }
                             failure:^(NSError *error) {
                                 
                                 MXLogDebug(@"[SettingsViewController] Failed to set avatar url");
                                
                                 if (weakSelf)
                                 {
                                     typeof(self) self = weakSelf;
                                     [self handleErrorDuringProfileChangeSaving:error];
                                 }
                                 
                             }];
        
        return;
    }
    
    // Backup is complete
    isSavingInProgress = NO;
    [self stopActivityIndicator];
    
    // Check whether destroy has been called durign saving
    if (onReadyToDestroyHandler)
    {
        // Ready to destroy
        onReadyToDestroyHandler();
        onReadyToDestroyHandler = nil;
    }
    else
    {
        [self updateSections];
    }
}

- (void)handleErrorDuringProfileChangeSaving:(NSError*)error
{
    // Sanity check: retrieve the current root view controller
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (rootViewController)
    {
        __weak typeof(self) weakSelf = self;
        
        // Alert user
        NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
        if (!title)
        {
            title = [VectorL10n settingsFailToUpdateProfile];
        }
        NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
        
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               self->currentAlert = nil;
                                                               
                                                               // Reset the updated displayname
                                                               self->newDisplayName = nil;
                                                               
                                                               // Discard picture change
                                                               self->uploadedAvatarURL = nil;
                                                               self->newAvatarImage = nil;
                                                               
                                                               // Loop to end saving
                                                               [self onSave:nil];
                                                           }
                                                           
                                                       }]];
        
        [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n retry]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               self->currentAlert = nil;
                                                               
                                                               // Loop to retry saving
                                                               [self onSave:nil];
                                                           }
                                                           
                                                       }]];
        
        [errorAlert mxk_setAccessibilityIdentifier: @"SettingsVCSaveChangesFailedAlert"];
        [rootViewController presentViewController:errorAlert animated:YES completion:nil];
        currentAlert = errorAlert;
    }
}

- (IBAction)onAddNewEmail:(id)sender
{
    // Ignore empty field
    if (!newEmailTextField.text.length)
    {
        // Reset new email adding
        self.newEmailEditingEnabled = NO;
        return;
    }
    
    // Email check
    if (![MXTools isEmailAddress:newEmailTextField.text])
    {
         __weak typeof(self) weakSelf = self;
        
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:[VectorL10n accountErrorEmailWrongTitle]
                                                                            message:[VectorL10n accountErrorEmailWrongDescription]
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        
        [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        [errorAlert mxk_setAccessibilityIdentifier: @"SettingsVCAddEmailAlert"];
        [self presentViewController:errorAlert animated:YES completion:nil];
        currentAlert = errorAlert;

        return;
    }

    // Dismiss the keyboard
    [newEmailTextField resignFirstResponder];

    MXSession* session = self.mainSession;

    [self showAuthenticationIfNeededForAdding:kMX3PIDMediumEmail withSession:session completion:^(NSDictionary *authParams) {
        [self startActivityIndicator];

        __block MX3PidAddSession *thirdPidAddSession;
        thirdPidAddSession = [session.threePidAddManager startAddEmailSessionWithEmail:self->newEmailTextField.text nextLink:nil success:^{

            [self showValidationEmailDialogWithMessage:[VectorL10n accountEmailValidationMessage]
                                     for3PidAddSession:thirdPidAddSession
                                    threePidAddManager:session.threePidAddManager
                                              authenticationParameters:authParams];

        } failure:^(NSError * _Nonnull error) {

            [self stopActivityIndicator];

            MXLogDebug(@"[SettingsViewController] Failed to request email token");

            // Translate the potential MX error.
            MXError *mxError = [[MXError alloc] initWithNSError:error];
            if (mxError
                && ([mxError.errcode isEqualToString:kMXErrCodeStringThreePIDInUse]
                    || [mxError.errcode isEqualToString:kMXErrCodeStringServerNotTrusted]))
            {
                NSMutableDictionary *userInfo;
                if (error.userInfo)
                {
                    userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                }
                else
                {
                    userInfo = [NSMutableDictionary dictionary];
                }

                userInfo[NSLocalizedFailureReasonErrorKey] = nil;

                if ([mxError.errcode isEqualToString:kMXErrCodeStringThreePIDInUse])
                {
                    userInfo[NSLocalizedDescriptionKey] = [VectorL10n authEmailInUse];
                    userInfo[@"error"] = [VectorL10n authEmailInUse];
                }
                else
                {
                    userInfo[NSLocalizedDescriptionKey] = [VectorL10n authUntrustedIdServer];
                    userInfo[@"error"] = [VectorL10n authUntrustedIdServer];
                }

                error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
            }
            else if ([error.domain isEqualToString:MX3PidAddManagerErrorDomain]
                     && error.code == MX3PidAddManagerErrorDomainIdentityServerRequired)
            {
                error = [NSError errorWithDomain:error.domain
                                            code:error.code
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey: [VectorL10n authEmailIsRequired]
                                                   }];
            }

            // Notify user
            NSString *myUserId = session.myUser.userId; // TODO: Hanlde multi-account
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];

        }];
    }];
}

- (IBAction)onAddNewPhone:(id)sender
{
    // Ignore empty field
    if (!newPhoneNumberCell.mxkTextField.text.length)
    {
        // Disable the new phone edition if the text field is empty
        self.newPhoneEditingEnabled = NO;
        return;
    }

    // Phone check
    if (![[NBPhoneNumberUtil sharedInstance] isValidNumber:newPhoneNumber])
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        __weak typeof(self) weakSelf = self;

        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:[VectorL10n accountErrorMsisdnWrongTitle]
                                                                            message:[VectorL10n accountErrorMsisdnWrongDescription]
                                                                     preferredStyle:UIAlertControllerStyleAlert];

        [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {

                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }

                                                       }]];

        [errorAlert mxk_setAccessibilityIdentifier: @"SettingsVCAddMsisdnAlert"];
        [self presentViewController:errorAlert animated:YES completion:nil];
        currentAlert = errorAlert;

        return;
    }

    // Dismiss the keyboard
    [newPhoneNumberCell.mxkTextField resignFirstResponder];

    MXSession* session = self.mainSession;

    NSString *e164 = [[NBPhoneNumberUtil sharedInstance] format:newPhoneNumber numberFormat:NBEPhoneNumberFormatE164 error:nil];
    NSString *msisdn;
    if ([e164 hasPrefix:@"+"])
    {
        msisdn = e164;
    }
    else if ([e164 hasPrefix:@"00"])
    {
        msisdn = [NSString stringWithFormat:@"+%@", [e164 substringFromIndex:2]];
    }
    
    NSString *countryCode = newPhoneNumberCell.isoCountryCode;

    [self showAuthenticationIfNeededForAdding:kMX3PIDMediumMSISDN withSession:session completion:^(NSDictionary *authParams) {
        [self startActivityIndicator];

        __block MX3PidAddSession *new3Pid;
        new3Pid = [session.threePidAddManager startAddPhoneNumberSessionWithPhoneNumber:msisdn countryCode:countryCode success:^{

            [self showValidationMsisdnDialogWithMessage:[VectorL10n accountMsisdnValidationMessage] for3PidAddSession:new3Pid threePidAddManager:session.threePidAddManager authenticationParameters:authParams];

        } failure:^(NSError *error) {

            [self stopActivityIndicator];

            MXLogDebug(@"[SettingsViewController] Failed to request msisdn token");

            // Translate the potential MX error.
            MXError *mxError = [[MXError alloc] initWithNSError:error];
            if (mxError
                && ([mxError.errcode isEqualToString:kMXErrCodeStringThreePIDInUse]
                    || [mxError.errcode isEqualToString:kMXErrCodeStringServerNotTrusted]))
            {
                NSMutableDictionary *userInfo;
                if (error.userInfo)
                {
                    userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                }
                else
                {
                    userInfo = [NSMutableDictionary dictionary];
                }

                userInfo[NSLocalizedFailureReasonErrorKey] = nil;

                if ([mxError.errcode isEqualToString:kMXErrCodeStringThreePIDInUse])
                {
                    userInfo[NSLocalizedDescriptionKey] = [VectorL10n authPhoneInUse];
                    userInfo[@"error"] = [VectorL10n authPhoneInUse];
                }
                else
                {
                    userInfo[NSLocalizedDescriptionKey] = [VectorL10n authUntrustedIdServer];
                    userInfo[@"error"] = [VectorL10n authUntrustedIdServer];
                }

                error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
            }
            else if ([error.domain isEqualToString:MX3PidAddManagerErrorDomain]
                     && error.code == MX3PidAddManagerErrorDomainIdentityServerRequired)
            {
                error = [NSError errorWithDomain:error.domain
                                            code:error.code
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey: [VectorL10n authPhoneIsRequired]
                                                   }];
            }

            // Notify user
            NSString *myUserId = session.myUser.userId;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
        }];
    }];
}

- (void)updateSaveButtonStatus
{
    if ([AppDelegate theDelegate].mxSessions.count > 0)
    {
        MXSession* session = self.mainSession;
        MXMyUser* myUser = session.myUser;
        
        BOOL saveButtonEnabled = (nil != newAvatarImage);
        
        if (!saveButtonEnabled)
        {
            if (newDisplayName)
            {
                saveButtonEnabled = ![myUser.displayname isEqualToString:newDisplayName];
            }
        }
        
        self.navigationItem.rightBarButtonItem.enabled = saveButtonEnabled;
    }
}

- (void)onProfileAvatarTap:(UITapGestureRecognizer *)recognizer
{
    SingleImagePickerPresenter *singleImagePickerPresenter = [[SingleImagePickerPresenter alloc] initWithSession:self.mainSession];
    singleImagePickerPresenter.delegate = self;
    
    NSIndexPath *indexPath = [_tableViewSections exactIndexPathForRowTag:USER_SETTINGS_PROFILE_PICTURE_INDEX
                                                              sectionTag:SECTION_TAG_USER_SETTINGS];
    if (indexPath)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        UIView *sourceView = cell;
        
        [singleImagePickerPresenter presentFrom:self sourceView:sourceView sourceRect:sourceView.bounds animated:YES];
        
        self.imagePickerPresenter = singleImagePickerPresenter;
    }
}

- (void)onManageAccountTap
{
    NSURL *url = [NSURL URLWithString: self.mainSession.homeserverWellknown.authentication.account];
    if (url) {
        SSOAccountService *service = [[SSOAccountService alloc] initWithAccountURL:url];
        SSOAuthenticationPresenter *presenter = [[SSOAuthenticationPresenter alloc] initWithSsoAuthenticationService:service];
        presenter.delegate = self;
        self.ssoAuthenticationPresenter = presenter;
        
        [presenter presentForIdentityProvider:nil with:@"" from:self animated:YES];
    }
}

- (void)showThemePicker
{
    __weak typeof(self) weakSelf = self;

    __block UIAlertAction *autoAction, *lightAction, *darkAction, *blackAction;
    NSString *themePickerMessage;

    void (^actionBlock)(UIAlertAction *action) = ^(UIAlertAction * action) {

        if (weakSelf)
        {
            typeof(self) self = weakSelf;

            NSString *newTheme;
            if (action == autoAction)
            {
                newTheme = @"auto";
            }
            else  if (action == lightAction)
            {
                newTheme = @"light";
            }
            else if (action == darkAction)
            {
                newTheme = @"dark";
            }
            else if (action == blackAction)
            {
                newTheme = @"black";
            }

            NSString *theme = RiotSettings.shared.userInterfaceTheme;
            if (newTheme && ![newTheme isEqualToString:theme])
            {
                // Clear fake Riot Avatars based on the previous theme.
                [AvatarGenerator clear];

                // The user wants to select this theme
                RiotSettings.shared.userInterfaceTheme = newTheme;
                ThemeService.shared.themeId = newTheme;
                
                // This is a hack to force the background colour of the container view of the navigation controller
                // This is needed only for hot theme update as the UIViewControllerWrapperView of the RioNavigationController is not updated
                self.view.superview.backgroundColor = ThemeService.shared.theme.backgroundColor;

                [self updateSections];
            }
        }
    };
    
    // Show "auto" only from iOS 11
    autoAction = [UIAlertAction actionWithTitle:[VectorL10n settingsUiThemeAuto]
                                          style:UIAlertActionStyleDefault
                                        handler:actionBlock];

    // Explain what is "auto"
    if (@available(iOS 13, *))
    {
        // Observe application did become active for iOS appearance setting changes
        themePickerMessage = [VectorL10n settingsUiThemePickerMessageMatchSystemTheme];
    }
    else
    {
        // Observe "Invert Colours" settings changes (available since iOS 11)
        themePickerMessage = [VectorL10n settingsUiThemePickerMessageInvertColours];
    }
    
    lightAction = [UIAlertAction actionWithTitle:[VectorL10n settingsUiThemeLight]
                                           style:UIAlertActionStyleDefault
                                         handler:actionBlock];
    
    darkAction = [UIAlertAction actionWithTitle:[VectorL10n settingsUiThemeDark]
                                          style:UIAlertActionStyleDefault
                                        handler:actionBlock];
    blackAction = [UIAlertAction actionWithTitle:[VectorL10n settingsUiThemeBlack]
                                           style:UIAlertActionStyleDefault
                                         handler:actionBlock];


    UIAlertController *themePicker = [UIAlertController alertControllerWithTitle:[VectorL10n settingsUiThemePickerTitle]
                                                                         message:themePickerMessage
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];

    if (autoAction)
    {
        [themePicker addAction:autoAction];
    }
    [themePicker addAction:lightAction];
    [themePicker addAction:darkAction];
    [themePicker addAction:blackAction];

    // Cancel button
    [themePicker addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];

    NSIndexPath *indexPath = [_tableViewSections exactIndexPathForRowTag:USER_INTERFACE_THEME_INDEX
                                                sectionTag:SECTION_TAG_USER_INTERFACE];
    if (indexPath)
    {
        UIView *fromCell = [self.tableView cellForRowAtIndexPath:indexPath];
        [themePicker popoverPresentationController].sourceView = fromCell;
        [themePicker popoverPresentationController].sourceRect = fromCell.bounds;
        [self presentViewController:themePicker animated:YES completion:nil];
    }
}

- (void)deactivateAccountAction
{
    DeactivateAccountViewController *deactivateAccountViewController = [DeactivateAccountViewController instantiateWithMatrixSession:self.mainSession];
    
    UINavigationController *navigationController = [[RiotNavigationController alloc] initWithRootViewController:deactivateAccountViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:navigationController animated:YES completion:nil];
    
    deactivateAccountViewController.delegate = self;
    
    self.deactivateAccountViewController = deactivateAccountViewController;
}

- (void)toggleShowRedacted:(UISwitch *)sender
{
    [MXKAppSettings standardAppSettings].showRedactionsInRoomHistory = sender.isOn;
}

- (void)togglePresenceOfflineMode:(UISwitch *)sender
{
    MXKAccount *account = MXKAccountManager.sharedManager.accounts.firstObject;
    if (sender.isOn)
    {
        account.preferredSyncPresence = MXPresenceOffline;
    }
    else
    {
        account.preferredSyncPresence = MXPresenceOnline;
    }
}

- (void)toggleEnableRoomMessageBubbles:(UISwitch *)sender
{
    RiotSettings.shared.roomScreenEnableMessageBubbles = sender.isOn;
            
    [[RoomTimelineConfiguration shared] updateStyleWithIdentifier:RiotSettings.shared.roomTimelineStyleIdentifier];
    
    // Close all room data sources
    // Be sure to use new room timeline style configurations
    MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:self.mainSession];
    [roomDataSourceManager reset];
}


- (void)toggleEnableAutoReportDecryptionErrors:(UISwitch *)sender
{
    RiotSettings.shared.enableUISIAutoReporting = sender.isOn;
}

- (void)toggleEnableLiveLocationSharing:(UISwitch *)sender
{
    RiotSettings.shared.enableLiveLocationSharing = sender.isOn;
}

#pragma mark - TextField listener

- (IBAction)textFieldDidChange:(id)sender
{
    UITextField* textField = (UITextField*)sender;
    
    if (textField.tag == USER_SETTINGS_DISPLAYNAME_INDEX)
    {
        // Remove white space from both ends
        newDisplayName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self updateSaveButtonStatus];
    }
    else if (textField.tag == USER_SETTINGS_ADD_PHONENUMBER_INDEX)
    {
        newPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:textField.text defaultRegion:newPhoneNumberCell.isoCountryCode error:nil];
        
        [self formatNewPhoneNumber];
    }
}

- (IBAction)textFieldDidEnd:(id)sender
{
    UITextField* textField = (UITextField*)sender;

    // Disable the new email edition if the user leaves the text field empty
    if (textField.tag == USER_SETTINGS_ADD_EMAIL_INDEX && textField.text.length == 0 && !keepNewEmailEditing)
    {
        self.newEmailEditingEnabled = NO;
    }
    else if (textField.tag == USER_SETTINGS_ADD_PHONENUMBER_INDEX && textField.text.length == 0 && !keepNewPhoneNumberEditing && !newPhoneNumberCountryPicker)
    {
        // Disable the new phone edition if the user leaves the text field empty
        self.newPhoneEditingEnabled = NO;
    }
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == USER_SETTINGS_DISPLAYNAME_INDEX)
    {
        textField.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == USER_SETTINGS_DISPLAYNAME_INDEX)
    {
        textField.textAlignment = NSTextAlignmentRight;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == USER_SETTINGS_DISPLAYNAME_INDEX)
    {
        [textField resignFirstResponder];
    }
    else if (textField.tag == USER_SETTINGS_ADD_EMAIL_INDEX)
    {
        [self onAddNewEmail:textField];
    }
    
    return YES;
}

#pragma password update management

- (void)displayPasswordAlert
{
    self.changePasswordBridgePresenter = [[ChangePasswordCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
    self.changePasswordBridgePresenter.delegate = self;

    [self.changePasswordBridgePresenter presentFrom:self animated:YES];
}

#pragma mark - MXKCountryPickerViewControllerDelegate

- (void)countryPickerViewController:(MXKCountryPickerViewController *)countryPickerViewController didSelectCountry:(NSString *)isoCountryCode
{
    if (countryPickerViewController.view.tag == SECTION_TAG_LOCAL_CONTACTS)
    {
        [MXKAppSettings standardAppSettings].phonebookCountryCode = isoCountryCode;
    }
    else if (countryPickerViewController.view.tag == SECTION_TAG_USER_SETTINGS)
    {
        if (newPhoneNumberCell)
        {
            newPhoneNumberCell.isoCountryCode = isoCountryCode;
            
            newPhoneNumber = [[NBPhoneNumberUtil sharedInstance] parse:newPhoneNumberCell.mxkTextField.text defaultRegion:isoCountryCode error:nil];
            [self formatNewPhoneNumber];
        }
    }
    
    [countryPickerViewController withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - MXKCountryPickerViewControllerDelegate

- (void)languagePickerViewController:(MXKLanguagePickerViewController *)languagePickerViewController didSelectLangugage:(NSString *)language
{
    if (![language isEqualToString:[NSBundle mxk_language]]
        || (language == nil && [NSBundle mxk_language]))
    {
        [NSBundle mxk_setLanguage:language];
        UIApplication.sharedApplication.accessibilityLanguage = language;

        // Store user settings
        NSUserDefaults *sharedUserDefaults = [MXKAppSettings standardAppSettings].sharedUserDefaults;
        [sharedUserDefaults setObject:language forKey:@"appLanguage"];

        // Do a reload in order to recompute strings in the new language
        // Note that "reloadMatrixSessions:NO" will reset room summaries
        [self startActivityIndicator];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

            [[AppDelegate theDelegate] reloadMatrixSessions:NO];
        });
    }
}

#pragma mark - DeactivateAccountViewControllerDelegate

- (void)deactivateAccountViewControllerDidDeactivateWithSuccess:(DeactivateAccountViewController *)deactivateAccountViewController
{
    MXLogDebug(@"[SettingsViewController] Deactivate account with success");
    
    [[AppDelegate theDelegate] logoutSendingRequestServer:NO completion:^(BOOL isLoggedOut) {
        MXLogDebug(@"[SettingsViewController] Complete clear user data after account deactivation");
    }];
}

- (void)deactivateAccountViewControllerDidCancel:(DeactivateAccountViewController *)deactivateAccountViewController
{
    [deactivateAccountViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NotificationSettingsCoordinatorBridgePresenter

- (void)showNotificationSettings: (NotificationSettingsScreen)screen API_AVAILABLE(ios(14.0))
{
    NotificationSettingsCoordinatorBridgePresenter *notificationSettingsBridgePresenter = [[NotificationSettingsCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];
    notificationSettingsBridgePresenter.delegate = self;
    
    MXWeakify(self);
    [notificationSettingsBridgePresenter pushFrom:self.navigationController animated:YES screen:screen popCompletion:^{
        MXStrongifyAndReturnIfNil(self);
        self.notificationSettingsBridgePresenter = nil;
    }];
    
    self.notificationSettingsBridgePresenter = notificationSettingsBridgePresenter;
}

#pragma mark - NotificationSettingsCoordinatorBridgePresenterDelegate

- (void)notificationSettingsCoordinatorBridgePresenterDelegateDidComplete:(NotificationSettingsCoordinatorBridgePresenter *)coordinatorBridgePresenter API_AVAILABLE(ios(14.0))
{
    [self.notificationSettingsBridgePresenter dismissWithAnimated:YES completion:nil];
    self.notificationSettingsBridgePresenter = nil;
}

#pragma mark - SignOutFlowPresenterDelegate

- (void)signOutFlowPresenterDidStartLoading:(SignOutFlowPresenter *)presenter
{
    [self startActivityIndicator];
    self.view.userInteractionEnabled = NO;
    self.signOutButton.enabled = NO;
}

- (void)signOutFlowPresenterDidStopLoading:(SignOutFlowPresenter *)presenter
{
    [self stopActivityIndicator];
    self.view.userInteractionEnabled = YES;
    self.signOutButton.enabled = YES;
}

- (void)signOutFlowPresenter:(SignOutFlowPresenter *)presenter didFailWith:(NSError *)error
{
    [[AppDelegate theDelegate] showErrorAsAlert:error];
}

#pragma mark - SingleImagePickerPresenterDelegate

- (void)singleImagePickerPresenterDidCancel:(SingleImagePickerPresenter *)presenter
{
    [presenter dismissWithAnimated:YES completion:nil];
    self.imagePickerPresenter = nil;
}

- (void)singleImagePickerPresenter:(SingleImagePickerPresenter *)presenter didSelectImageData:(NSData *)imageData withUTI:(MXKUTI *)uti
{
    [presenter dismissWithAnimated:YES completion:nil];
    self.imagePickerPresenter = nil;
    
    newAvatarImage = [UIImage imageWithData:imageData];
    
    [self updateSections];
}


#pragma mark - Identity server updates

- (void)registerAccountDataDidChangeIdentityServerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountDataDidChangeIdentityServerNotification:) name:kMXSessionAccountDataDidChangeIdentityServerNotification object:nil];
}

- (void)handleAccountDataDidChangeIdentityServerNotification:(NSNotification*)notification
{
    [self refreshSettings];
}

#pragma mark - SettingsDiscoveryTableViewSectionDelegate

- (void)settingsDiscoveryTableViewSectionDidUpdate:(SettingsDiscoveryTableViewSection *)settingsDiscoveryTableViewSection
{
    [self updateSections];
}

- (MXKTableViewCell *)settingsDiscoveryTableViewSection:(SettingsDiscoveryTableViewSection *)settingsDiscoveryTableViewSection tableViewCellClass:(Class)tableViewCellClass forRow:(NSInteger)forRow
{
    MXKTableViewCell *tableViewCell;
    
    if ([tableViewCellClass isEqual:[MXKTableViewCell class]])
    {
        tableViewCell = [self getDefaultTableViewCell:self.tableView];
    }
    else if ([tableViewCellClass isEqual:[MXKTableViewCellWithTextView class]])
    {
        NSIndexPath *indexPath = [_tableViewSections exactIndexPathForRowTag:forRow sectionTag:SECTION_TAG_DISCOVERY];
        if (indexPath)
        {
            tableViewCell = [self textViewCellForTableView:self.tableView atIndexPath:indexPath];
        }
    }
    else if ([tableViewCellClass isEqual:[MXKTableViewCellWithButton class]])
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
        
        tableViewCell = cell;
    }
    else if ([tableViewCellClass isEqual:[MXKTableViewCellWithLabelAndSwitch class]])
    {
        NSIndexPath *indexPath = [_tableViewSections exactIndexPathForRowTag:forRow sectionTag:SECTION_TAG_DISCOVERY];
        if (indexPath)
        {
            tableViewCell = [self getLabelAndSwitchCell:self.tableView forIndexPath:indexPath];
        }
    }
    
    return tableViewCell;
}

#pragma mark - SettingsDiscoveryViewModelCoordinatorDelegate

- (void)settingsDiscoveryViewModel:(SettingsDiscoveryViewModel *)viewModel didSelectThreePidWith:(NSString *)medium and:(NSString *)address
{
    SettingsDiscoveryThreePidDetailsCoordinatorBridgePresenter *discoveryThreePidDetailsPresenter = [[SettingsDiscoveryThreePidDetailsCoordinatorBridgePresenter alloc] initWithSession:self.mainSession medium:medium adress:address];
    
    MXWeakify(self);
    
    [discoveryThreePidDetailsPresenter pushFrom:self.navigationController animated:YES popCompletion:^{
        MXStrongifyAndReturnIfNil(self);
        
        self.discoveryThreePidDetailsPresenter = nil;
    }];
    
    self.discoveryThreePidDetailsPresenter = discoveryThreePidDetailsPresenter;
}

- (void)settingsDiscoveryViewModelDidTapAcceptIdentityServerTerms:(SettingsDiscoveryViewModel *)viewModel
{
    MXSession *session = self.mainSession;
    if (!session.identityService.areAllTermsAgreed)
    {
        [self prepareIdentityServiceAndPresentTermsWithSession:session checkingAccessForContactsOnAccept:NO];
    }
}

#pragma mark - Local Contacts Sync
    
 - (void)checkAccessForContacts
{
    MXWeakify(self);
    
    // Check for contacts access, showing a pop-up if necessary.
    [MXKTools checkAccessForContacts:VectorL10n.contactsAddressBookPermissionDeniedAlertTitle
             withManualChangeMessage:VectorL10n.contactsAddressBookPermissionDeniedAlertMessage
           showPopUpInViewController:self
                   completionHandler:^(BOOL granted) {
        
        MXStrongifyAndReturnIfNil(self);
        
        if (granted)
        {
            // When granted, local contacts can be shown.
            [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
            [self updateSections];
        }
    }];
}

#pragma mark - Identity server

- (void)showIdentityServerSettingsScreen
{
    identityServerSettingsCoordinatorBridgePresenter = [[SettingsIdentityServerCoordinatorBridgePresenter alloc] initWithSession:self.mainSession];

    [identityServerSettingsCoordinatorBridgePresenter pushFrom:self.navigationController animated:YES popCompletion:nil];
    identityServerSettingsCoordinatorBridgePresenter.delegate = self;
}

- (void)prepareIdentityServiceAndPresentTermsWithSession:(MXSession *)session
                       checkingAccessForContactsOnAccept:(BOOL)checkAccessForContacts
{
    if (self.isPreparingIdentityService)
    {
        return;
    }
    
    self.isPreparingIdentityService = YES;
    self.serviceTermsModalShouldCheckAccessForContactsOnAccept = checkAccessForContacts;
    
    MXWeakify(self);
    
    // The preparation can take some time so indicate this to the user
    [self startActivityIndicator];
    
    [session prepareIdentityServiceForTermsWithDefault:RiotSettings.shared.identityServerUrlString
                                               success:^(MXSession *session, NSString *baseURL, NSString *accessToken) {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        self.isPreparingIdentityService = NO;
        
        // Present the terms of the identity server.
        [self presentIdentityServerTermsWithSession:session baseURL:baseURL andAccessToken:accessToken];
    } failure:^(NSError *error) {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        self.isPreparingIdentityService = NO;
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:VectorL10n.findYourContactsIdentityServiceError
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:VectorL10n.ok
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil]];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        [MXKAppSettings standardAppSettings].syncLocalContacts = NO;
        [self updateSections];
    }];
}

- (void)presentIdentityServerTermsWithSession:(MXSession*)mxSession baseURL:(NSString*)baseURL andAccessToken:(NSString*)accessToken
{
    if (!mxSession || !baseURL || !accessToken || self.serviceTermsModalCoordinatorBridgePresenter.isPresenting)
    {
        return;
    }
    
    self.serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:mxSession
                                                                                                                    baseUrl:baseURL
                                                                                                                serviceType:MXServiceTypeIdentityService
                                                                                                                accessToken:accessToken];
    
    self.serviceTermsModalCoordinatorBridgePresenter.delegate = self;
    [self.serviceTermsModalCoordinatorBridgePresenter presentFrom:self animated:YES];
}

#pragma mark SettingsIdentityServerCoordinatorBridgePresenterDelegate

- (void)settingsIdentityServerCoordinatorBridgePresenterDelegateDidComplete:(SettingsIdentityServerCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    identityServerSettingsCoordinatorBridgePresenter = nil;
    [self refreshSettings];
}

#pragma mark ServiceTermsModalCoordinatorBridgePresenterDelegate

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        [self.settingsDiscoveryTableViewSection reload];
        if (self.serviceTermsModalShouldCheckAccessForContactsOnAccept)
        {
            [self checkAccessForContacts];
        }
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter session:(MXSession *)session
{
    // Terms weren't accepted: disable contacts toggle and refresh discovery
    [self updateSections];
    [self.settingsDiscoveryTableViewSection reload];
    
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidClose:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    // Terms weren't accepted: disable contacts toggle and refresh discovery
    [self updateSections];
    [self.settingsDiscoveryTableViewSection reload];
    
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

#pragma mark - TableViewSectionsDelegate

- (void)tableViewSectionsDidUpdateSections:(TableViewSections *)sections
{
    [self.tableView reloadData];
}

#pragma mark - ThreadsBetaCoordinatorBridgePresenterDelegate

- (void)threadsBetaCoordinatorBridgePresenterDelegateDidTapEnable:(ThreadsBetaCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    MXWeakify(self);
    [self.threadsBetaBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        [self enableThreads:YES];
    }];
}

- (void)threadsBetaCoordinatorBridgePresenterDelegateDidTapCancel:(ThreadsBetaCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    MXWeakify(self);
    [self.threadsBetaBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        [self updateSections];
    }];
}

#pragma mark - ChangePasswordCoordinatorBridgePresenterDelegate

- (void)changePasswordCoordinatorBridgePresenterDidComplete:(ChangePasswordCoordinatorBridgePresenter *)bridgePresenter
{
    [bridgePresenter dismissWithAnimated:YES completion:^{
        self.changePasswordBridgePresenter = nil;
    }];
}

- (void)changePasswordCoordinatorBridgePresenterDidCancel:(ChangePasswordCoordinatorBridgePresenter *)bridgePresenter
{
    [bridgePresenter dismissWithAnimated:YES completion:nil];
    self.changePasswordBridgePresenter = nil;
}

#pragma mark - User sessions management

- (void)showUserSessionsFlow
{
    if (!self.mainSession)
    {
        MXLogError(@"[SettingsViewController] Cannot show user sessions flow, no user session available");
        return;
    }
    
    if (!self.navigationController)
    {
        MXLogError(@"[SettingsViewController] Cannot show user sessions flow, no navigation controller available");
        return;
    }
    
    UserSessionsFlowCoordinatorBridgePresenter *userSessionsFlowCoordinatorBridgePresenter = [[UserSessionsFlowCoordinatorBridgePresenter alloc] initWithMxSession:self.mainSession];
    
    MXWeakify(self);
    
    userSessionsFlowCoordinatorBridgePresenter.completion = ^{
        MXStrongifyAndReturnIfNil(self);
        
        self.userSessionsFlowCoordinatorBridgePresenter = nil;
    };

    self.userSessionsFlowCoordinatorBridgePresenter = userSessionsFlowCoordinatorBridgePresenter;

    [self.userSessionsFlowCoordinatorBridgePresenter pushFrom:self.navigationController animated:YES];
}

#pragma mark - SSOAuthenticationPresenterDelegate

- (void)ssoAuthenticationPresenterDidCancel:(SSOAuthenticationPresenter *)presenter
{
    self.ssoAuthenticationPresenter = nil;
    MXLogDebug(@"OIDC account management complete.")
}

- (void)ssoAuthenticationPresenter:(SSOAuthenticationPresenter *)presenter authenticationDidFailWithError:(NSError *)error
{
    self.ssoAuthenticationPresenter = nil;
    MXLogError(@"OIDC account management failed.")
}

- (void)ssoAuthenticationPresenter:(SSOAuthenticationPresenter *)presenter
  authenticationSucceededWithToken:(NSString *)token
             usingIdentityProvider:(SSOIdentityProvider *)identityProvider
{
    self.ssoAuthenticationPresenter = nil;
    MXLogWarning(@"Unexpected callback after OIDC account management.")
}

@end
