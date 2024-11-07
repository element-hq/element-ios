/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomSettingsViewController.h"

#import "TableViewCellWithLabelAndLargeTextView.h"
#import "TableViewCellWithCheckBoxAndLabel.h"

#import "SegmentedViewController.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "MXRoom+Riot.h"
#import "MXRoomSummary+Riot.h"

#import "GeneratedInterface-Swift.h"

#import "RoomMemberDetailsViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

enum
{
    SECTION_TAG_MAIN,
    SECTION_TAG_ACCESS,
    SECTION_TAG_PROMOTION,
    SECTION_TAG_HISTORY,
    SECTION_TAG_ADDRESSES,
    SECTION_TAG_BANNED_USERS,
    SECTION_TAG_BANNED_ADVANCED
};

enum
{
    ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO,
    ROOM_SETTINGS_MAIN_SECTION_ROW_NAME,
    ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC,
    ROOM_SETTINGS_MAIN_SECTION_ROW_TAG,
    ROOM_SETTINGS_MAIN_SECTION_ROW_DIRECT_CHAT,
    ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS
};

enum
{
    ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ACCESS,
    ROOM_SETTINGS_ROOM_ACCESS_DIRECTORY_VISIBILITY,
    ROOM_SETTINGS_ROOM_ACCESS_MISSING_ADDRESS_WARNING
};

enum
{
    ROOM_SETTINGS_ROOM_PROMOTE_SECTION_ROW_SUGGEST
};

enum
{
    ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE,
    ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY,
    ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED,
    ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED
};

enum
{
    ROOM_SETTINGS_ADVANCED_ROOM_ID,
    ROOM_SETTINGS_ADVANCED_ENCRYPT_TO_VERIFIED,
    ROOM_SETTINGS_ADVANCED_ENCRYPTION_ENABLED,
    ROOM_SETTINGS_ADVANCED_ENABLE_ENCRYPTION,
    ROOM_SETTINGS_ADVANCED_ENCRYPTION_DISABLED
};

enum
{
    ROOM_SETTINGS_ROOM_ADDRESS_NEW_ALIAS,
    ROOM_SETTINGS_ROOM_ADDRESS_NO_LOCAL_ADDRESS,
    ROOM_SETTINGS_ROOM_ADDRESS_ALIAS_OFFSET = 1000
};

#define ROOM_TOPIC_CELL_HEIGHT 124

NSString *const kRoomSettingsAvatarKey = @"kRoomSettingsAvatarKey";
NSString *const kRoomSettingsAvatarURLKey = @"kRoomSettingsAvatarURLKey";
NSString *const kRoomSettingsNameKey = @"kRoomSettingsNameKey";
NSString *const kRoomSettingsTopicKey = @"kRoomSettingsTopicKey";
NSString *const kRoomSettingsTagKey = @"kRoomSettingsTagKey";
NSString *const kRoomSettingsMuteNotifKey = @"kRoomSettingsMuteNotifKey";
NSString *const kRoomSettingsDirectChatKey = @"kRoomSettingsDirectChatKey";
NSString *const kRoomSettingsJoinRuleKey = @"kRoomSettingsJoinRuleKey";
NSString *const kRoomSettingsGuestAccessKey = @"kRoomSettingsGuestAccessKey";
NSString *const kRoomSettingsDirectoryKey = @"kRoomSettingsDirectoryKey";
NSString *const kRoomSettingsHistoryVisibilityKey = @"kRoomSettingsHistoryVisibilityKey";
NSString *const kRoomSettingsNewAliasesKey = @"kRoomSettingsNewAliasesKey";
NSString *const kRoomSettingsRemovedAliasesKey = @"kRoomSettingsRemovedAliasesKey";
NSString *const kRoomSettingsCanonicalAliasKey = @"kRoomSettingsCanonicalAliasKey";
NSString *const kRoomSettingsEncryptionKey = @"kRoomSettingsEncryptionKey";
NSString *const kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey = @"kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey";

NSString *const kRoomSettingsNameCellViewIdentifier = @"kRoomSettingsNameCellViewIdentifier";
NSString *const kRoomSettingsTopicCellViewIdentifier = @"kRoomSettingsTopicCellViewIdentifier";
NSString *const kRoomSettingsWarningCellViewIdentifier = @"kRoomSettingsWarningCellViewIdentifier";
NSString *const kRoomSettingsNewAddressCellViewIdentifier = @"kRoomSettingsNewAddressCellViewIdentifier";
NSString *const kRoomSettingsAddressCellViewIdentifier = @"kRoomSettingsAddressCellViewIdentifier";
NSString *const kRoomSettingsAdvancedCellViewIdentifier = @"kRoomSettingsAdvancedCellViewIdentifier";
NSString *const kRoomSettingsAdvancedEnableE2eCellViewIdentifier = @"kRoomSettingsAdvancedEnableE2eCellViewIdentifier";
NSString *const kRoomSettingsAdvancedE2eEnabledCellViewIdentifier = @"kRoomSettingsAdvancedE2eEnabledCellViewIdentifier";

@interface RoomSettingsViewController () <SingleImagePickerPresenterDelegate, TableViewSectionsDelegate, RoomAccessCoordinatorBridgePresenterDelegate, RoomSuggestionCoordinatorBridgePresenterDelegate>
{
    // The updated user data
    NSMutableDictionary<NSString*, id> *updatedItemsDict;
    
    // The current table items
    UITextField* nameTextField;
    UITextView* topicTextView;
    
    // The room tag items
    TableViewCellWithCheckBoxes *roomTagCell;
    
    // Room Access items
    
    UISwitch *directoryVisibilitySwitch;
    MXRoomDirectoryVisibility actualDirectoryVisibility;
    MXHTTPOperation* actualDirectoryVisibilityRequest;
    
    // History Visibility items
    NSMutableDictionary<MXRoomHistoryVisibility, TableViewCellWithCheckBoxAndLabel*> *historyVisibilityTickCells;
    
    // Room aliases
    NSMutableArray<NSString *> *roomAddresses;
    NSUInteger localAddressesCount;
    UITextField* addAddressTextField;
    
    // The potential image loader
    MXMediaLoader *uploader;
    
    // The pending http operation
    MXHTTPOperation* pendingOperation;
    
    UIAlertController *currentAlert;
    
    // listen to more events than the mother class
    id extraEventsListener;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id appDelegateDidTapStatusBarNotificationObserver;
    
    // A copy of the banned members
    NSArray<MXRoomMember*> *bannedMembers;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    RoomAccessCoordinatorBridgePresenter *roomAccessPresenter;
    
    RoomSuggestionCoordinatorBridgePresenter *roomSuggestionPresenter;
}

@property (nonatomic, strong) SingleImagePickerPresenter *imagePickerPresenter;

@property (nonatomic, strong) TableViewSections *tableViewSections;

@end

@implementation RoomSettingsViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    _selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)initWithSession:(MXSession *)session andRoomId:(NSString *)roomId
{
    [super initWithSession:session andRoomId:roomId];
    
    // Add an additional listener to update banned users
    self->extraEventsListener = [mxRoom listenToEventsOfTypes:@[kMXEventTypeStringRoomMember] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

        if (direction == MXTimelineDirectionForwards)
        {
            [self updateRoomState:roomState];
        }
    }];
}

- (void)updateRoomState:(MXRoomState *)newRoomState
{
    [super updateRoomState:newRoomState];
    
    bannedMembers = [mxRoomState.members membersWithMembership:MXMembershipBan];
}

- (UINavigationItem*)getNavigationItem
{
    // Check whether the view controller is currently displayed inside a segmented view controller or not.
    UIViewController* topViewController = ((self.parentViewController) ? self.parentViewController : self);
    
    return topViewController.navigationItem;
}

- (void)setNavBarButtons
{
    [self getNavigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSave:)];
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    [self getNavigationItem].leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    updatedItemsDict = [[NSMutableDictionary alloc] init];
    historyVisibilityTickCells = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    roomAddresses = [NSMutableArray array];
    
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndMXKImageView.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
    
    // Use a specific cell identifier for the room name, the topic and the address in order to be able to keep reference
    // on the text input field without being disturbed by the cell dequeuing process.
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:kRoomSettingsNameCellViewIdentifier];
    [self.tableView registerClass:TableViewCellWithLabelAndLargeTextView.class forCellReuseIdentifier:kRoomSettingsTopicCellViewIdentifier];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:kRoomSettingsNewAddressCellViewIdentifier];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kRoomSettingsAddressCellViewIdentifier];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kRoomSettingsWarningCellViewIdentifier];
    
    [self.tableView registerClass:MXKTableViewCellWithButton.class forCellReuseIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithCheckBoxes.class forCellReuseIdentifier:[TableViewCellWithCheckBoxes defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithCheckBoxAndLabel.class forCellReuseIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCell.class forCellReuseIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    [self.tableView registerClass:TitleAndRightDetailTableViewCell.class forCellReuseIdentifier:[TitleAndRightDetailTableViewCell defaultReuseIdentifier]];
    
    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
    
    [self setNavBarButtons];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
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
    
    [self.screenTracker trackScreen];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateRules:) name:kMXNotificationCenterDidUpdateRules object:nil];
    
    // Observe appDelegateDidTapStatusBarNotificationObserver.
    appDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.adjustedContentInset.left, -self.tableView.adjustedContentInset.top) animated:YES];
        
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Edit the selected field if any
    if (_selectedRoomSettingsField != RoomSettingsViewControllerFieldNone)
    {
        self.selectedRoomSettingsField = _selectedRoomSettingsField;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXNotificationCenterDidUpdateRules object:nil];
    
    if (appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegateDidTapStatusBarNotificationObserver];
        appDelegateDidTapStatusBarNotificationObserver = nil;
    }
}

// Those methods are called when the viewcontroller is added or removed from a container view controller.
- (void)willMoveToParentViewController:(nullable UIViewController *)parent
{
    // Check whether the view is removed from its parent.
    if (!parent)
    {
        [self dismissFirstResponder];
        
        // Prompt user to save changes (if any).
        if (updatedItemsDict.count)
        {
            [self promptUserToSaveChanges];
        }
    }
    
    [super willMoveToParentViewController:parent];
}
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    [self setNavBarButtons];
}

- (void)destroy
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (uploader)
    {
        [uploader cancel];
        uploader = nil;
    }
    
    if (pendingOperation)
    {
        [pendingOperation cancel];
        pendingOperation = nil;
    }
    
    if (actualDirectoryVisibilityRequest)
    {
        [actualDirectoryVisibilityRequest cancel];
        actualDirectoryVisibilityRequest = nil;
    }
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    if (appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegateDidTapStatusBarNotificationObserver];
        appDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    updatedItemsDict = nil;
    historyVisibilityTickCells = nil;
    
    roomAddresses = nil;
    
    if (extraEventsListener)
    {
        MXWeakify(self);
        [mxRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->extraEventsListener];
            self->extraEventsListener = nil;
        }];
    }
    
    [super destroy];
}

- (void)withdrawViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    // Check whether the current view controller is displayed inside a segmented view controller in order to withdraw the right item
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) withdrawViewControllerAnimated:animated completion:completion];
    }
    else
    {
        [super withdrawViewControllerAnimated:animated completion:completion];
    }
}

- (void)refreshRoomSettings
{
    [self retrieveActualDirectoryVisibility];
    
    // Check whether a text input is currently edited
    BOOL isNameEdited = nameTextField ? nameTextField.isFirstResponder : NO;
    BOOL isTopicEdited = topicTextView ? topicTextView.isFirstResponder : NO;
    BOOL isAddressEdited = addAddressTextField ? addAddressTextField.isFirstResponder : NO;
    
    // Trigger a full table reloadData
    [self updateSections];
    
    // Restore the previous edited field
    if (isNameEdited)
    {
        [self editRoomName];
    }
    else if (isTopicEdited)
    {
        [self editRoomTopic];
    }
    else if (isAddressEdited)
    {
        [self editAddRoomAddress];
    }
}

- (void)updateSections
{
    //  update local data
    // Refresh here the room addresses list.
    [roomAddresses removeAllObjects];
    localAddressesCount = 0;
    
    NSArray *removedAliases = updatedItemsDict[kRoomSettingsRemovedAliasesKey];
    
    NSArray *aliases = mxRoomState.aliases;
    if (aliases)
    {
        for (NSString *alias in aliases)
        {
            // Check whether the user did not remove it
            if (!removedAliases || [removedAliases indexOfObject:alias] == NSNotFound)
            {
                // Add it
                if ([alias hasSuffix:self.mainSession.matrixRestClient.homeserverSuffix])
                {
                    [roomAddresses insertObject:alias atIndex:localAddressesCount];
                    localAddressesCount++;
                }
                else
                {
                    [roomAddresses addObject:alias];
                }
            }
        }
    }
    
    aliases = updatedItemsDict[kRoomSettingsNewAliasesKey];
    for (NSString *alias in aliases)
    {
        // Add this new alias to local addresses
        [roomAddresses insertObject:alias atIndex:localAddressesCount];
        localAddressesCount++;
    }
    
    //  create sections
    NSMutableArray<Section*> *tmpSections = [NSMutableArray arrayWithCapacity:SECTION_TAG_BANNED_ADVANCED + 1];
    
    Section *sectionMain = [Section sectionWithTag:SECTION_TAG_MAIN];
    [sectionMain addRowWithTag:ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO];
    [sectionMain addRowWithTag:ROOM_SETTINGS_MAIN_SECTION_ROW_NAME];
    [sectionMain addRowWithTag:ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC];
    [sectionMain addRowWithTag:ROOM_SETTINGS_MAIN_SECTION_ROW_TAG];
    if (RiotSettings.shared.roomSettingsScreenShowDirectChatOption)
    {
        [sectionMain addRowWithTag:ROOM_SETTINGS_MAIN_SECTION_ROW_DIRECT_CHAT];
    }
    if (!BuildSettings.showNotificationsV2)
    {
        [sectionMain addRowWithTag:ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS];
    }
    [tmpSections addObject:sectionMain];
    
    if (RiotSettings.shared.roomSettingsScreenAllowChangingAccessSettings)
    {
        Section *sectionAccess = [Section sectionWithTag:SECTION_TAG_ACCESS];
        [sectionAccess addRowWithTag:ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ACCESS];
        
        // Check whether a room address is required for the current join rule
        NSString *joinRule = updatedItemsDict[kRoomSettingsJoinRuleKey];
        if (!joinRule)
        {
            // Use the actual values if no change is pending.
            joinRule = mxRoomState.joinRule;
        }
        
        if ([joinRule isEqualToString:kMXRoomJoinRulePublic] && !roomAddresses.count)
        {
            // Notify the user that a room address is required.
            [sectionAccess addRowWithTag:ROOM_SETTINGS_ROOM_ACCESS_MISSING_ADDRESS_WARNING];
        }
        
        if (mxRoom.isDirect)
        {
            sectionAccess.headerTitle = [VectorL10n roomDetailsAccessSectionForDm];
        }
        else
        {
            sectionAccess.headerTitle = [VectorL10n roomDetailsAccessSection];
        }
        [tmpSections addObject:sectionAccess];
        
        if (RiotSettings.shared.roomSettingsScreenAllowChangingAccessSettings)
        {
            Section *promotionAccess = [Section sectionWithTag:SECTION_TAG_PROMOTION];
            promotionAccess.headerTitle = VectorL10n.roomDetailsPromoteRoomTitle;
            [promotionAccess addRowWithTag:ROOM_SETTINGS_ROOM_ACCESS_DIRECTORY_VISIBILITY];
            [promotionAccess addRowWithTag:ROOM_SETTINGS_ROOM_PROMOTE_SECTION_ROW_SUGGEST];
            [tmpSections addObject:promotionAccess];
        }
    }
    
    if (RiotSettings.shared.roomSettingsScreenAllowChangingHistorySettings)
    {
        Section *sectionHistory = [Section sectionWithTag:SECTION_TAG_HISTORY];
        [sectionHistory addRowWithTag:ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE];
        [sectionHistory addRowWithTag:ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY];
        [sectionHistory addRowWithTag:ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED];
        [sectionHistory addRowWithTag:ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED];
        sectionHistory.headerTitle = [VectorL10n roomDetailsHistorySection];
        [tmpSections addObject:sectionHistory];
    }
    
    if (RiotSettings.shared.roomSettingsScreenShowAddressSettings)
    {
        Section *sectionAddresses = [Section sectionWithTag:SECTION_TAG_ADDRESSES];
        if (localAddressesCount)
        {
            for (NSInteger counter = 0; counter < roomAddresses.count; counter++)
            {
                [sectionAddresses addRowWithTag:ROOM_SETTINGS_ROOM_ADDRESS_ALIAS_OFFSET + counter];
            }
        }
        else
        {
            [sectionAddresses addRowWithTag:ROOM_SETTINGS_ROOM_ADDRESS_NO_LOCAL_ADDRESS];
        }
        [sectionAddresses addRowWithTag:ROOM_SETTINGS_ROOM_ADDRESS_NEW_ALIAS];
        sectionAddresses.headerTitle = [VectorL10n roomDetailsAddressesSection];
        [tmpSections addObject:sectionAddresses];
    }
    
    if (bannedMembers.count)
    {
        Section *sectionBannedUsers = [Section sectionWithTag:SECTION_TAG_BANNED_USERS];
        
        for (NSInteger counter = 0; counter < bannedMembers.count; counter++)
        {
            [sectionBannedUsers addRowWithTag:counter];
        }
        
        sectionBannedUsers.headerTitle = [VectorL10n roomDetailsBannedUsersSection];
        [tmpSections addObject:sectionBannedUsers];
    }
    
    if (RiotSettings.shared.roomSettingsScreenShowAdvancedSettings)
    {
        Section *sectionAdvanced = [Section sectionWithTag:SECTION_TAG_BANNED_ADVANCED];
        
        [sectionAdvanced addRowWithTag:ROOM_SETTINGS_ADVANCED_ROOM_ID];
        if (mxRoom.mxSession.crypto)
        {
            if (mxRoom.summary.isEncrypted)
            {
                if (RiotSettings.shared.roomSettingsScreenAdvancedShowEncryptToVerifiedOption)
                {
                    [sectionAdvanced addRowWithTag:ROOM_SETTINGS_ADVANCED_ENCRYPT_TO_VERIFIED];
                }
                [sectionAdvanced addRowWithTag:ROOM_SETTINGS_ADVANCED_ENCRYPTION_ENABLED];
            }
            else
            {
                // Check user's power level to know whether the user is allowed to turn on the encryption mode
                MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
                NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
                
                if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomEncryption])
                {
                    [sectionAdvanced addRowWithTag:ROOM_SETTINGS_ADVANCED_ENABLE_ENCRYPTION];
                }
                else
                {
                    [sectionAdvanced addRowWithTag:ROOM_SETTINGS_ADVANCED_ENCRYPTION_DISABLED];
                }
            }
        }
        
        sectionAdvanced.headerTitle = [VectorL10n roomDetailsAdvancedSection];
        [tmpSections addObject:sectionAdvanced];
    }
    
    //  update sections
    self.tableViewSections.sections = tmpSections;
}

#pragma mark -

- (void)setSelectedRoomSettingsField:(RoomSettingsViewControllerField)selectedRoomSettingsField
{
    // Check whether the view controller is already embedded inside a navigation controller
    if (self.navigationController)
    {
        [self dismissFirstResponder];
        
        // Check whether user allowed to change room info
        NSDictionary *eventTypes = @{
                                     @(RoomSettingsViewControllerFieldName): kMXEventTypeStringRoomName,
                                     @(RoomSettingsViewControllerFieldTopic): kMXEventTypeStringRoomTopic,
                                     @(RoomSettingsViewControllerFieldAvatar): kMXEventTypeStringRoomAvatar
                                     };
        
        NSString *eventTypeForSelectedField = eventTypes[@(selectedRoomSettingsField)];
        
        if (!eventTypeForSelectedField)
            return;
        
        MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
        NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
        
        if (oneSelfPowerLevel < [powerLevels minimumPowerLevelForSendingEventAsStateEvent:eventTypeForSelectedField])
            return;
        
        switch (selectedRoomSettingsField)
        {
            case RoomSettingsViewControllerFieldName:
            {
                [self editRoomName];
                break;
            }
            case RoomSettingsViewControllerFieldTopic:
            {
                [self editRoomTopic];
                break;
            }
            case RoomSettingsViewControllerFieldAvatar:
            {
                [self onRoomAvatarTap:nil];
                break;
            }
                
            default:
                break;
        }
    }
    else
    {
        // This selection will be applied when the view controller will become active (see 'viewDidAppear')
        _selectedRoomSettingsField = selectedRoomSettingsField;
    }
}

#pragma mark - private

- (void)editRoomName
{
    if (![nameTextField becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editRoomName];
            
        });
    }
}

- (void)editRoomTopic
{
    if (![topicTextView becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editRoomTopic];
            
        });
    }
}

- (void)editAddRoomAddress
{
    if (![addAddressTextField becomeFirstResponder])
    {
        // Retry asynchronously
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self editAddRoomAddress];
            
        });
    }
}

- (void)dismissFirstResponder
{
    if ([topicTextView isFirstResponder])
    {
        [topicTextView resignFirstResponder];
    }
    
    if ([nameTextField isFirstResponder])
    {
        [nameTextField resignFirstResponder];
    }
    
    if ([addAddressTextField isFirstResponder])
    {
        [addAddressTextField resignFirstResponder];
    }
    
    _selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
}

- (void)startActivityIndicator
{
    // Lock user interaction
    self.tableView.userInteractionEnabled = NO;
    
    // Check whether the current view controller is displayed inside a segmented view controller in order to run the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) startActivityIndicator];
        
        // Force stop the activity view of the view controller
        [self.activityIndicator stopAnimating];
    }
    else
    {
        [super startActivityIndicator];
    }
}

- (void)stopActivityIndicator
{
    // Check local conditions before stop the activity indicator
    if (!pendingOperation && !uploader)
    {
        // Unlock user interaction
        self.tableView.userInteractionEnabled = YES;
        
        // Check whether the current view controller is displayed inside a segmented view controller in order to stop the right activity view
        if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
        {
            [((SegmentedViewController*)self.parentViewController) stopActivityIndicator];
            
            // Force stop the activity view of the view controller
            [self.activityIndicator stopAnimating];
        }
        else
        {
            [super stopActivityIndicator];
        }
    }
}

- (void)promptUserToSaveChanges
{
    // ensure that the user understands that the updates will be lost if
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [UIAlertController alertControllerWithTitle:nil
                                                       message:[VectorL10n roomDetailsSaveChangesPrompt]
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n no]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self->updatedItemsDict removeAllObjects];
                                                           
                                                           if (self.delegate)
                                                           {
                                                               [self.delegate roomSettingsViewControllerDidCancel:self];
                                                           }
                                                           else
                                                           {
                                                               [self withdrawViewControllerAnimated:YES completion:nil];
                                                           }
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n yes]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self onSave:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCSaveChangesAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)promptUserToCopyRoomId:(UILabel*)roomIdLabel
{
    if (roomIdLabel)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        __weak typeof(self) weakSelf = self;
        
        currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomDetailsCopyRoomId]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               NSString *roomdId = roomIdLabel.text;
                                                               
                                                               if (roomdId)
                                                               {
                                                                   MXKPasteboardManager.shared.pasteboard.string = roomdId;
                                                               }
                                                               else
                                                               {
                                                                   MXLogDebug(@"[RoomSettingsViewController] Copy room id failed. Room id is nil");
                                                               }
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCCopyRoomIdAlert"];
        [currentAlert popoverPresentationController].sourceView = roomIdLabel;
        [currentAlert popoverPresentationController].sourceRect = roomIdLabel.bounds;
        [self presentViewController:currentAlert animated:YES completion:nil];
    }
}

- (void)promptUserOnSelectedRoomAlias:(UILabel*)roomAliasLabel
{
    if (roomAliasLabel)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        __weak typeof(self) weakSelf = self;
        
        currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        // Check whether the user is allowed to modify the main address.
        if ([self canSetCanonicalAlias])
        {
            // Compare the selected alias with the current main address
            NSString *currentCanonicalAlias = mxRoomState.canonicalAlias;
            NSString *canonicalAlias;
            
            if (updatedItemsDict[kRoomSettingsCanonicalAliasKey])
            {
                canonicalAlias = updatedItemsDict[kRoomSettingsCanonicalAliasKey];
            }
            else
            {
                canonicalAlias = currentCanonicalAlias;
            }
            
            if (canonicalAlias && [roomAliasLabel.text isEqualToString:canonicalAlias])
            {
                [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomDetailsUnsetMainAddress]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       // Prompt user before removing the current main address (use dispatch_async here to not be stuck by the table refresh).
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                           
                                                                           [self shouldRemoveCanonicalAlias:nil];
                                                                           
                                                                       });
                                                                   }
                                                                   
                                                               }]];
            }
            else
            {
                // Invite user to define this alias as the main room address
                [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomDetailsSetMainAddress]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   
                                                                   if (weakSelf)
                                                                   {
                                                                       typeof(self) self = weakSelf;
                                                                       self->currentAlert = nil;
                                                                       
                                                                       [self setRoomAliasAsMainAddress:roomAliasLabel.text];
                                                                   }
                                                                   
                                                               }]];
            }
        }
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomDetailsCopyRoomAddress]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               NSString *roomAlias = roomAliasLabel.text;
                                                               
                                                               if (roomAlias)
                                                               {
                                                                   MXKPasteboardManager.shared.pasteboard.string = roomAlias;
                                                               }
                                                               else
                                                               {
                                                                   MXLogDebug(@"[RoomSettingsViewController] Copy room address failed. Room address is nil");
                                                               }
                                                           }
                                                           
                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n roomDetailsCopyRoomUrl]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
            
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
                
                // Create a matrix.to permalink to the room
                
                NSString *permalink = [MXTools permalinkToRoom:roomAliasLabel.text];
                NSURL *url = [NSURL URLWithString:permalink];

                if (url)
                {
                    MXKPasteboardManager.shared.pasteboard.URL = url;
                    [self.view vc_toastWithMessage:VectorL10n.roomEventCopyLinkInfo
                                             image:AssetImages.linkIcon.image
                                          duration:2.0
                                          position:ToastPositionBottom
                                  additionalMargin:0.0];
                }
                else
                {
                    MXLogDebug(@"[RoomSettingsViewController] Copy room URL failed. Room URL is nil");
                }
            }
            
        }]];
        
        // The user can only delete alias they has created, even if the Admin has set it as canonical.
        // So, let the server answer if it's possible to delete an alias.
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n delete]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {

                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;

                                                               [self removeRoomAlias:roomAliasLabel.text];
                                                           }

                                                       }]];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                           }
                                                           
                                                       }]];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCOnSelectedAliasAlert"];
        [currentAlert popoverPresentationController].sourceView = roomAliasLabel;
        [currentAlert popoverPresentationController].sourceRect = roomAliasLabel.bounds;
        [self presentViewController:currentAlert animated:YES completion:nil];
    }
}

- (void)retrieveActualDirectoryVisibility
{
    if (!mxRoom || actualDirectoryVisibilityRequest)
    {
        return;
    }
    
    // Trigger a new request to check the actual directory visibility
    __weak typeof(self) weakSelf = self;
    
    actualDirectoryVisibilityRequest = [mxRoom directoryVisibility:^(MXRoomDirectoryVisibility directoryVisibility) {
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            self->actualDirectoryVisibilityRequest = nil;
            
            self->actualDirectoryVisibility = directoryVisibility;
            
            // Update the value of the displayed toggle button (if any)
            if (self->directoryVisibilitySwitch)
            {
                // Check a potential user's change before the end of the request
                MXRoomDirectoryVisibility modifiedDirectoryVisibility = self->updatedItemsDict[kRoomSettingsDirectoryKey];
                if (modifiedDirectoryVisibility)
                {
                    if ([modifiedDirectoryVisibility isEqualToString:directoryVisibility])
                    {
                        // The requested change corresponds to the actual settings
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
                        
                        [self getNavigationItem].rightBarButtonItem.enabled = (self->updatedItemsDict.count != 0);
                    }
                }
                
                self->directoryVisibilitySwitch.on = ([directoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic]);
            }
        }
        
    } failure:^(NSError *error) {
        
        MXLogDebug(@"[RoomSettingsViewController] request to get directory visibility failed");
        
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            self->actualDirectoryVisibilityRequest = nil;
        }
    }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView;
{
    if (topicTextView == textView)
    {
        UIView *contentView = topicTextView.superview;
        if (contentView)
        {
            // refresh cell's layout
            [contentView.superview setNeedsLayout];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (topicTextView == textView)
    {
        UIView *contentView = topicTextView.superview;
        if (contentView)
        {
            // refresh cell's layout
            [contentView.superview setNeedsLayout];
        }
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (topicTextView == textView)
    {
        NSString* currentTopic = mxRoomState.topic;
        
        // Remove white space from both ends
        NSString* topic = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check whether the topic has been actually changed
        if ((topic || currentTopic) && ([topic isEqualToString:currentTopic] == NO))
        {
            updatedItemsDict[kRoomSettingsTopicKey] = topic ? topic : @"";
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsTopicKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == nameTextField)
    {
        nameTextField.textAlignment = NSTextAlignmentLeft;
    }
    else if (textField == addAddressTextField)
    {
        if (textField.text.length == 0)
        {
            textField.text = @"#";
        }
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == nameTextField)
    {
        nameTextField.textAlignment = NSTextAlignmentRight;
    }
    else if (textField == addAddressTextField)
    {
        if (textField.text.length < 2)
        {
            // reset text field
            textField.text = nil;
        }
        else
        {
            // Check whether homeserver suffix should be added
            NSRange range = [textField.text rangeOfString:@":"];
            if (range.location == NSNotFound)
            {
                textField.text = [textField.text stringByAppendingString:self.mainSession.matrixRestClient.homeserverSuffix];
            }
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Auto complete room alias
    if (textField == addAddressTextField)
    {
        // Add # if none
        if (!textField.text.length || textField.text.length == range.length)
        {
            if ([string hasPrefix:@"#"] == NO)
            {
                if ([string isEqualToString:@":"])
                {
                    textField.text = [NSString stringWithFormat:@"#%@",self.mainSession.matrixRestClient.homeserverSuffix];
                }
                else
                {
                    textField.text = [NSString stringWithFormat:@"#%@",string];
                }
                return NO;
            }
        }
        else
        {
            // Remove default '#' if the string start with '#'
            if ([string hasPrefix:@"#"] && [textField.text isEqualToString:@"#"])
            {
                textField.text = string;
                return NO;
            }
            // Add homeserver automatically when user adds ':' at the end
            else if (range.location == textField.text.length && [string isEqualToString:@":"])
            {
                textField.text = [textField.text stringByAppendingString:self.mainSession.matrixRestClient.homeserverSuffix];
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (textField == addAddressTextField)
    {
        textField.text = @"#";
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == nameTextField)
    {
        // Dismiss the keyboard
        [nameTextField resignFirstResponder];
    }
    else if (textField == addAddressTextField)
    {
        // Dismiss the keyboard
        [addAddressTextField resignFirstResponder];
        
        NSString *roomAlias = addAddressTextField.text;
        if (!roomAlias.length || [self addRoomAlias:roomAlias])
        {
            // Reset the input field
            addAddressTextField.text = nil;
        }
    }
    
    return YES;
}

#pragma mark - actions

- (IBAction)onTextFieldUpdate:(UITextField*)textField
{
    if (textField == nameTextField)
    {
        NSString *currentName = mxRoomState.name;
        
        // Remove white space from both ends
        NSString *displayName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        // Check whether the name has been actually changed
        if ((displayName || currentName) && ([displayName isEqualToString:currentName] == NO))
        {
            updatedItemsDict[kRoomSettingsNameKey] = displayName ? displayName : @"";
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsNameKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

- (void)didUpdateRules:(NSNotification *)notif
{
    [self refreshRoomSettings];
}

- (IBAction)onCancel:(id)sender
{
    [self dismissFirstResponder];
    
    // Check whether some changes have been done
    if (updatedItemsDict.count)
    {
        [self promptUserToSaveChanges];
    }
    else
    {
        if (self.delegate)
        {
            [self.delegate roomSettingsViewControllerDidCancel:self];
        }
        else
        {
            [self withdrawViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)onSaveFailed:(NSString*)message withKeys:(NSArray<NSString *>*)keys
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    currentAlert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           // Discard related change
                                                           for (NSString *key in keys)
                                                           {
                                                               [self->updatedItemsDict removeObjectForKey:key];
                                                           }
                                                           
                                                           // Save anything else
                                                           [self onSave:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n retry]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self onSave:nil];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCSaveChangesFailedAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (IBAction)onSave:(id)sender
{
    if (updatedItemsDict.count)
    {
        [self startActivityIndicator];
        
        __weak typeof(self) weakSelf = self;
        
        // check if there is some updates related to room state
        if (mxRoomState)
        {
            if (updatedItemsDict[kRoomSettingsAvatarKey])
            {
                // Retrieve the current picture and make sure its orientation is up
                UIImage *updatedPicture = [MXKTools forceImageOrientationUp:updatedItemsDict[kRoomSettingsAvatarKey]];
                
                // Upload picture
                uploader = [MXMediaManager prepareUploaderWithMatrixSession:mxRoom.mxSession initialRange:0 andRange:1.0];
                
                [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url) {
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->uploader = nil;
                        
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsAvatarKey];
                        self->updatedItemsDict[kRoomSettingsAvatarURLKey] = url;
                        
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Image upload failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->uploader = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateAvatar];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsAvatarKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            NSString* photoUrl = updatedItemsDict[kRoomSettingsAvatarURLKey];
            if (photoUrl)
            {
                pendingOperation = [mxRoom setAvatar:photoUrl success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsAvatarURLKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Failed to update the room avatar");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateAvatar];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsAvatarURLKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // has a new room name
            NSString* roomName = updatedItemsDict[kRoomSettingsNameKey];
            if (roomName)
            {
                pendingOperation = [mxRoom setName:roomName success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsNameKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Rename room failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateRoomName];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsNameKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // has a new room topic
            NSString* roomTopic = updatedItemsDict[kRoomSettingsTopicKey];
            if (roomTopic)
            {
                pendingOperation = [mxRoom setTopic:roomTopic success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsTopicKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Rename topic failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateTopic];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsTopicKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // Room guest access
            MXRoomGuestAccess guestAccess = updatedItemsDict[kRoomSettingsGuestAccessKey];
            if (guestAccess)
            {
                pendingOperation = [mxRoom setGuestAccess:guestAccess success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Update guest access failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateRoomGuestAccess];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsGuestAccessKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // Room join rule
            MXRoomJoinRule joinRule = updatedItemsDict[kRoomSettingsJoinRuleKey];
            if (joinRule)
            {
                pendingOperation = [mxRoom setJoinRule:joinRule success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Update join rule failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateRoomJoinRule];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsJoinRuleKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // History visibility
            MXRoomHistoryVisibility visibility = updatedItemsDict[kRoomSettingsHistoryVisibilityKey];
            if (visibility)
            {
                pendingOperation = [mxRoom setHistoryVisibility:visibility success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsHistoryVisibilityKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Update history visibility failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateHistoryVisibility];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsHistoryVisibilityKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // Room addresses
            NSMutableArray<NSString *> *aliases = updatedItemsDict[kRoomSettingsNewAliasesKey];
            if (aliases.count)
            {
                NSString *roomAlias = aliases.firstObject;
                
                pendingOperation = [mxRoom addAlias:roomAlias success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        if (aliases.count > 1)
                        {
                            [aliases removeObjectAtIndex:0];
                            self->updatedItemsDict[kRoomSettingsNewAliasesKey] = aliases;
                        }
                        else
                        {
                            [self->updatedItemsDict removeObjectForKey:kRoomSettingsNewAliasesKey];
                        }
                        
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Add room aliases failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToAddRoomAliases];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsNewAliasesKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            aliases = updatedItemsDict[kRoomSettingsRemovedAliasesKey];
            if (aliases.count)
            {
                NSString *roomAlias = aliases.firstObject;
                
                pendingOperation = [mxRoom removeAlias:roomAlias success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        if (aliases.count > 1)
                        {
                            [aliases removeObjectAtIndex:0];
                            self->updatedItemsDict[kRoomSettingsRemovedAliasesKey] = aliases;
                        }
                        else
                        {
                            [self->updatedItemsDict removeObjectForKey:kRoomSettingsRemovedAliasesKey];
                        }
                        
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Remove room aliases failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToRemoveRoomAliases];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsRemovedAliasesKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            NSString* canonicalAlias = updatedItemsDict[kRoomSettingsCanonicalAliasKey];
            if (canonicalAlias)
            {
                pendingOperation = [mxRoom setCanonicalAlias:canonicalAlias success:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
                        [self onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXLogDebug(@"[RoomSettingsViewController] Update canonical alias failed");
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        self->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = [VectorL10n roomDetailsFailToUpdateRoomCanonicalAlias];
                            }
                            [self onSaveFailed:message withKeys:@[kRoomSettingsCanonicalAliasKey]];
                            
                        });
                    }
                    
                }];
                
                return;
            }
        }
        
        // Update here other room settings
        NSString *roomTag = updatedItemsDict[kRoomSettingsTagKey];
        if (roomTag)
        {
            if (!roomTag.length)
            {
                roomTag = nil;
            }
            
            [mxRoom setRoomTag:roomTag completion:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsTagKey];
                    [self onSave:nil];
                }
                
            }];
            
            return;
        }
        
        if (updatedItemsDict[kRoomSettingsMuteNotifKey])
        {
            if (((NSNumber*) updatedItemsDict[kRoomSettingsMuteNotifKey]).boolValue)
            {
                [mxRoom mentionsOnly:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                        [self onSave:nil];
                    }
                    
                }];
            }
            else
            {
                [mxRoom allMessages:^{
                    
                    if (weakSelf)
                    {
                        typeof(self) self = weakSelf;
                        
                        [self->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                        [self onSave:nil];
                    }
                    
                }];
            }
            return;
        }
        
        if (updatedItemsDict[kRoomSettingsDirectChatKey])
        {
            pendingOperation = [mxRoom setIsDirect:((NSNumber*) updatedItemsDict[kRoomSettingsDirectChatKey]).boolValue withUserId:nil success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    self->pendingOperation = nil;
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsDirectChatKey];
                    [self onSave:nil];
                }
                
            }                              failure:^(NSError *error) {
                
                MXLogDebug(@"[RoomSettingsViewController] Altering DMness failed");
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    self->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = [VectorL10n roomDetailsFailToUpdateRoomDirect];
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsDirectChatKey]];
                        
                    });
                }
                
            }];
            return;
        }
        
        // Room directory visibility
        MXRoomDirectoryVisibility directoryVisibility = updatedItemsDict[kRoomSettingsDirectoryKey];
        if (directoryVisibility)
        {
            [mxRoom setDirectoryVisibility:directoryVisibility success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
                    [self onSave:nil];
                }
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[RoomSettingsViewController] Update room directory visibility failed");
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    self->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = [VectorL10n roomDetailsFailToUpdateRoomDirectoryVisibility];
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsDirectoryKey]];
                        
                    });
                }
                
            }];
            
            return;
        }
        
        // Room encryption
        if (updatedItemsDict[kRoomSettingsEncryptionKey])
        {
            pendingOperation = [mxRoom enableEncryptionWithAlgorithm:kMXCryptoMegolmAlgorithm success:^{
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    self->pendingOperation = nil;
                    
                    [self->updatedItemsDict removeObjectForKey:kRoomSettingsEncryptionKey];
                    [self onSave:nil];
                }
                
            } failure:^(NSError *error) {
                
                MXLogDebug(@"[RoomSettingsViewController] Enabling encrytion failed. Error: %@", error);
                
                if (weakSelf)
                {
                    typeof(self) self = weakSelf;
                    
                    self->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = [VectorL10n roomDetailsFailToEnableEncryption];
                        }
                        [self onSaveFailed:message withKeys:@[kRoomSettingsEncryptionKey]];
                        
                    });
                }
                
            }];
            
            return;
        }
        
        // Room settings on blacklist unverified devices
        if (updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey])
        {
            BOOL blacklistUnverifiedDevices = [((NSNumber*)updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey]) boolValue];
            [mxRoom.mxSession.crypto setBlacklistUnverifiedDevicesInRoom:mxRoom.roomId blacklist:blacklistUnverifiedDevices];
        }
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = NO;
    
    [self stopActivityIndicator];
    
    if (self.delegate)
    {
        [self.delegate roomSettingsViewControllerDidComplete:self];
    }
    else
    {
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableViewSections.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Section *sectionObject = [_tableViewSections sectionAtIndex:section];
    return sectionObject.rows.count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    Section *sectionObject = [_tableViewSections sectionAtIndex:section];
    return sectionObject.headerTitle;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:UITableViewHeaderFooterView.class])
    {
        // Customize label style
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView*)view;
        tableViewHeaderFooterView.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        tableViewHeaderFooterView.textLabel.font = [UIFont systemFontOfSize:15];
        tableViewHeaderFooterView.contentView.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;

    if (section == SECTION_TAG_MAIN)
    {
        if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
        {
            return ROOM_TOPIC_CELL_HEIGHT;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;
    
    UITableViewCell* cell;
    
    // Check user's power level to know which settings are editable.
    MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    
    // general settings
    if (section == SECTION_TAG_MAIN)
    {
        if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS)
        {
            MXKTableViewCellWithLabelAndSwitch *roomNotifCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            [roomNotifCell.mxkSwitch addTarget:self action:@selector(toggleRoomNotification:) forControlEvents:UIControlEventValueChanged];
            
            roomNotifCell.mxkLabel.text = [VectorL10n roomDetailsMuteNotifs];
            
            if (updatedItemsDict[kRoomSettingsMuteNotifKey])
            {
                roomNotifCell.mxkSwitch.on = ((NSNumber*) updatedItemsDict[kRoomSettingsMuteNotifKey]).boolValue;
            }
            else
            {
                roomNotifCell.mxkSwitch.on = mxRoom.isMute || mxRoom.isMentionsOnly;
            }
            
            cell = roomNotifCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_DIRECT_CHAT)
        {
            MXKTableViewCellWithLabelAndSwitch *roomDirectChat = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            [roomDirectChat.mxkSwitch addTarget:self action:@selector(toggleDirectChat:) forControlEvents:UIControlEventValueChanged];
            
            roomDirectChat.mxkLabel.text = [VectorL10n roomDetailsDirectChat];
            
            if (updatedItemsDict[kRoomSettingsDirectChatKey])
            {
                roomDirectChat.mxkSwitch.on = ((NSNumber*) updatedItemsDict[kRoomSettingsDirectChatKey]).boolValue;
            }
            else
            {
                roomDirectChat.mxkSwitch.on = mxRoom.isDirect;
            }
            
            cell = roomDirectChat;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
        {
            MXKTableViewCellWithLabelAndMXKImageView *roomPhotoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomPhotoCell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
            roomPhotoCell.mxkImageViewTrailingConstraint.constant = 10;
            
            roomPhotoCell.mxkImageViewWidthConstraint.constant = roomPhotoCell.mxkImageViewHeightConstraint.constant = 30;
            
            roomPhotoCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
            
            // Handle tap on avatar to update it
            if (!roomPhotoCell.mxkImageView.gestureRecognizers.count)
            {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRoomAvatarTap:)];
                [roomPhotoCell.mxkImageView addGestureRecognizer:tap];
            }
            
            roomPhotoCell.mxkImageView.defaultBackgroundColor = [UIColor clearColor];
            
            if (mxRoom.isDirect)
            {
                roomPhotoCell.mxkLabel.text = [VectorL10n roomDetailsPhotoForDm];
            }
            else
            {
                roomPhotoCell.mxkLabel.text = [VectorL10n roomDetailsPhoto];
            }
            roomPhotoCell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            if (updatedItemsDict[kRoomSettingsAvatarKey])
            {
                roomPhotoCell.mxkImageView.image = (UIImage*) updatedItemsDict[kRoomSettingsAvatarKey];
            }
            else
            {
                [mxRoom.summary setRoomAvatarImageIn:roomPhotoCell.mxkImageView];
                
                roomPhotoCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomAvatar]);
                roomPhotoCell.mxkImageView.alpha = roomPhotoCell.userInteractionEnabled ? 1.0f : 0.5f;
            }
            
            cell = roomPhotoCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
        {
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsTopicCellViewIdentifier forIndexPath:indexPath];
            
            roomTopicCell.labelLeadingConstraint.constant = tableView.vc_separatorInset.left;
            
            roomTopicCell.label.text = [VectorL10n roomDetailsTopic];
            
            topicTextView = roomTopicCell.textView;
            
            if (updatedItemsDict[kRoomSettingsTopicKey])
            {
                topicTextView.text = (NSString*) updatedItemsDict[kRoomSettingsTopicKey];
            }
            else
            {
                topicTextView.text = mxRoomState.topic;
            }
            
            topicTextView.tintColor = ThemeService.shared.theme.tintColor;
            topicTextView.font = [UIFont systemFontOfSize:15];
            topicTextView.bounces = NO;
            topicTextView.delegate = self;
            
            // disable the edition if the user cannot update it
            topicTextView.editable = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic]);
            topicTextView.textColor = ThemeService.shared.theme.textSecondaryColor;
            
            topicTextView.keyboardAppearance = ThemeService.shared.theme.keyboardAppearance;
            
            cell = roomTopicCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_NAME)
        {
            MXKTableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsNameCellViewIdentifier forIndexPath:indexPath];
            
            roomNameCell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
            roomNameCell.mxkTextFieldLeadingConstraint.constant = 16;
            roomNameCell.mxkTextFieldTrailingConstraint.constant = 15;
            
            if (mxRoom.isDirect)
            {
                roomNameCell.mxkLabel.text = [VectorL10n roomDetailsRoomNameForDm];
            }
            else
            {
                roomNameCell.mxkLabel.text = [VectorL10n roomDetailsRoomName];
            }
            roomNameCell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            roomNameCell.accessoryView = nil;
            
            nameTextField = roomNameCell.mxkTextField;
            
            nameTextField.tintColor = ThemeService.shared.theme.tintColor;
            nameTextField.font = [UIFont systemFontOfSize:17];
            nameTextField.borderStyle = UITextBorderStyleNone;
            nameTextField.textAlignment = NSTextAlignmentRight;
            nameTextField.delegate = self;
            
            if (updatedItemsDict[kRoomSettingsNameKey])
            {
                nameTextField.text = (NSString*) updatedItemsDict[kRoomSettingsNameKey];
            }
            else
            {
                nameTextField.text = mxRoomState.name;
            }
            
            // disable the edition if the user cannot update it
            nameTextField.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName]);
            nameTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
            
            // Add a "textFieldDidChange" notification method to the text field control.
            [nameTextField addTarget:self action:@selector(onTextFieldUpdate:) forControlEvents:UIControlEventEditingChanged];
            
            cell = roomNameCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TAG)
        {
            if (RiotSettings.shared.roomSettingsScreenShowLowPriorityOption)
            {
                //  show a muti-checkbox cell
                roomTagCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxes defaultReuseIdentifier] forIndexPath:indexPath];
                roomTagCell.mainContainerLeadingConstraint.constant = tableView.vc_separatorInset.left;
                roomTagCell.checkBoxesNumber = 2;
                roomTagCell.allowsMultipleSelection = NO;
                roomTagCell.delegate = self;
                
                NSArray *labels = roomTagCell.labels;
                UILabel *label;
                label = labels[0];
                label.textColor = ThemeService.shared.theme.textPrimaryColor;
                label.text = [VectorL10n roomDetailsFavouriteTag];
                label = labels[1];
                label.textColor = ThemeService.shared.theme.textPrimaryColor;
                label.text = [VectorL10n roomDetailsLowPriorityTag];
                
                if (updatedItemsDict[kRoomSettingsTagKey])
                {
                    NSString *roomTag = updatedItemsDict[kRoomSettingsTagKey];
                    if ([roomTag isEqualToString:kMXRoomTagFavourite])
                    {
                        [roomTagCell setCheckBoxValue:YES atIndex:0];
                    }
                    else if ([roomTag isEqualToString:kMXRoomTagLowPriority])
                    {
                        [roomTagCell setCheckBoxValue:YES atIndex:1];
                    }
                }
                else
                {
                    if (mxRoom.accountData.tags[kMXRoomTagFavourite] != nil)
                    {
                        [roomTagCell setCheckBoxValue:YES atIndex:0];
                    }
                    else if (mxRoom.accountData.tags[kMXRoomTagLowPriority] != nil)
                    {
                        [roomTagCell setCheckBoxValue:YES atIndex:1];
                    }
                }
                
                cell = roomTagCell;
            }
            else
            {
                //  use a switch cell
                MXKTableViewCellWithLabelAndSwitch *favoriteCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
                
                [favoriteCell.mxkSwitch addTarget:self action:@selector(toggleFavorite:) forControlEvents:UIControlEventValueChanged];
                
                favoriteCell.mxkLabel.text = [VectorL10n roomDetailsFavouriteTag];
                
                if ([updatedItemsDict[kRoomSettingsTagKey] isEqualToString:kMXRoomTagFavourite])
                {
                    favoriteCell.mxkSwitch.on = ((NSNumber*) updatedItemsDict[kMXRoomTagFavourite]).boolValue;
                }
                else
                {
                    favoriteCell.mxkSwitch.on = mxRoom.accountData.tags[kMXRoomTagFavourite] != nil;
                }
                
                cell = favoriteCell;
            }
        }
    }
    else if (section == SECTION_TAG_ACCESS)
    {
        if (row == ROOM_SETTINGS_ROOM_ACCESS_DIRECTORY_VISIBILITY)
        {
            MXKTableViewCellWithLabelAndSwitch *directoryToggleCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            if (mxRoom.isDirect)
            {
                directoryToggleCell.mxkLabel.text = [VectorL10n roomDetailsAccessSectionDirectoryToggleForDm];
            }
            else
            {
                directoryToggleCell.mxkLabel.text = [VectorL10n roomDetailsAccessSectionDirectoryToggle];
            }
            
            [directoryToggleCell.mxkSwitch addTarget:self action:@selector(toggleDirectoryVisibility:) forControlEvents:UIControlEventValueChanged];
            
            if (updatedItemsDict[kRoomSettingsDirectoryKey])
            {
                directoryToggleCell.mxkSwitch.on = ((NSNumber*) updatedItemsDict[kRoomSettingsDirectoryKey]).boolValue;
            }
            else
            {
                // Use the last retrieved value if any
                directoryToggleCell.mxkSwitch.on = actualDirectoryVisibility ? [actualDirectoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic] : NO;
            }
            
            // Check whether the user can change this option
            directoryToggleCell.mxkSwitch.enabled = (oneSelfPowerLevel >= powerLevels.stateDefault);
            
            // Store the switch to be able to update it
            directoryVisibilitySwitch = directoryToggleCell.mxkSwitch;
            
            cell = directoryToggleCell;
        }
        else if (row == ROOM_SETTINGS_ROOM_ACCESS_MISSING_ADDRESS_WARNING)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsWarningCellViewIdentifier forIndexPath:indexPath];
            
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.textColor = ThemeService.shared.theme.warningColor;
            cell.textLabel.numberOfLines = 0;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = [VectorL10n roomDetailsAccessSectionNoAddressWarning];
        }
        else if (row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ACCESS)
        {
            TitleAndRightDetailTableViewCell *roomAccessCell = [tableView dequeueReusableCellWithIdentifier:[TitleAndRightDetailTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
                        
            // Retrieve the potential updated values for joinRule and guestAccess
            NSString *joinRule = updatedItemsDict[kRoomSettingsJoinRuleKey];
            NSString *guestAccess = updatedItemsDict[kRoomSettingsGuestAccessKey];
            
            // Use the actual values if no change is pending
            if (!joinRule)
            {
                joinRule = mxRoomState.joinRule;
            }
            if (!guestAccess)
            {
                guestAccess = mxRoomState.guestAccess;
            }
            
            roomAccessCell.titleLabel.text = [VectorL10n roomDetailsAccessRowTitle];
            NSString *access = VectorL10n.private;
            if ([joinRule isEqualToString:kMXRoomJoinRulePublic])
            {
                access = VectorL10n.public;
            }
            else if ([joinRule isEqualToString:kMXRoomJoinRuleRestricted])
            {
                access = VectorL10n.createRoomTypeRestricted;
            }
            roomAccessCell.detailLabel.text = access;

            // Check whether the user can change this option
            roomAccessCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomJoinRules]);

            cell = roomAccessCell;
        }
        else
        {
            TableViewCellWithCheckBoxAndLabel *roomAccessCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomAccessCell.checkBoxLeadingConstraint.constant = tableView.vc_separatorInset.left;
            
            // Retrieve the potential updated values for joinRule and guestAccess
            NSString *joinRule = updatedItemsDict[kRoomSettingsJoinRuleKey];
            NSString *guestAccess = updatedItemsDict[kRoomSettingsGuestAccessKey];
            
            // Use the actual values if no change is pending
            if (!joinRule)
            {
                joinRule = mxRoomState.joinRule;
            }
            if (!guestAccess)
            {
                guestAccess = mxRoomState.guestAccess;
            }

            // Check whether the user can change this option
            roomAccessCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomJoinRules]);
            roomAccessCell.checkBox.alpha = roomAccessCell.userInteractionEnabled ? 1.0f : 0.5f;
            
            cell = roomAccessCell;
        }
    }
    else if (section == SECTION_TAG_PROMOTION)
    {
        if (row == ROOM_SETTINGS_ROOM_ACCESS_DIRECTORY_VISIBILITY)
        {
            MXKTableViewCellWithLabelAndSwitch *directoryToggleCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            if (mxRoom.isDirect)
            {
                directoryToggleCell.mxkLabel.text = [VectorL10n roomDetailsAccessSectionDirectoryToggleForDm];
            }
            else
            {
                directoryToggleCell.mxkLabel.text = [VectorL10n roomDetailsAccessSectionDirectoryToggle];
            }
            
            [directoryToggleCell.mxkSwitch addTarget:self action:@selector(toggleDirectoryVisibility:) forControlEvents:UIControlEventValueChanged];
            
            if (updatedItemsDict[kRoomSettingsDirectoryKey])
            {
                directoryToggleCell.mxkSwitch.on = ((NSNumber*) updatedItemsDict[kRoomSettingsDirectoryKey]).boolValue;
            }
            else
            {
                // Use the last retrieved value if any
                directoryToggleCell.mxkSwitch.on = actualDirectoryVisibility ? [actualDirectoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic] : NO;
            }
            
            // Check whether the user can change this option
            directoryToggleCell.mxkSwitch.enabled = (oneSelfPowerLevel >= powerLevels.stateDefault);
            
            // Store the switch to be able to update it
            directoryVisibilitySwitch = directoryToggleCell.mxkSwitch;
            
            cell = directoryToggleCell;
        }
        else if (row == ROOM_SETTINGS_ROOM_PROMOTE_SECTION_ROW_SUGGEST)
        {
            TitleAndRightDetailTableViewCell *roomSuggestionCell = [tableView dequeueReusableCellWithIdentifier:[TitleAndRightDetailTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
                        
            roomSuggestionCell.titleLabel.text = [VectorL10n roomDetailsPromoteRoomSuggestTitle];
            roomSuggestionCell.detailLabel.text = [self.mainSession.spaceService directParentIdsOfRoomWithId:self.roomId whereRoomIsSuggested:YES].count ? [VectorL10n on] : [VectorL10n off];

            // Check whether the user can change this option
            roomSuggestionCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomJoinRules]);

            cell = roomSuggestionCell;
        }
    }
    else if (section == SECTION_TAG_HISTORY)
    {
        TableViewCellWithCheckBoxAndLabel *historyVisibilityCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier] forIndexPath:indexPath];
        
        historyVisibilityCell.checkBoxLeadingConstraint.constant = tableView.vc_separatorInset.left;
        
        // Retrieve first the potential updated value for history visibility
        NSString *visibility = updatedItemsDict[kRoomSettingsHistoryVisibilityKey];
        
        // Use the actual value if no change is pending
        if (!visibility)
        {
            visibility = mxRoomState.historyVisibility;
        }
        
        if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = [VectorL10n roomDetailsHistorySectionAnyone];
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityWorldReadable]);
            
            historyVisibilityTickCells[kMXRoomHistoryVisibilityWorldReadable] = historyVisibilityCell;
        }
        else if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = [VectorL10n roomDetailsHistorySectionMembersOnly];
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityShared]);
            
            historyVisibilityTickCells[kMXRoomHistoryVisibilityShared] = historyVisibilityCell;
        }
        else if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = [VectorL10n roomDetailsHistorySectionMembersOnlySinceInvited];
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityInvited]);
            
            historyVisibilityTickCells[kMXRoomHistoryVisibilityInvited] = historyVisibilityCell;
        }
        else if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = [VectorL10n roomDetailsHistorySectionMembersOnlySinceJoined];
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityJoined]);
            
            historyVisibilityTickCells[kMXRoomHistoryVisibilityJoined] = historyVisibilityCell;
        }
        
        // Check whether the user can change this option
        historyVisibilityCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomHistoryVisibility]);
        historyVisibilityCell.checkBox.alpha = historyVisibilityCell.userInteractionEnabled ? 1.0f : 0.5f;
        
        cell = historyVisibilityCell;
    }
    else if (section == SECTION_TAG_ADDRESSES)
    {
        if (row == ROOM_SETTINGS_ROOM_ADDRESS_NEW_ALIAS)
        {
            MXKTableViewCellWithLabelAndTextField *addAddressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsNewAddressCellViewIdentifier forIndexPath:indexPath];
            
            // Retrieve the current edited value if any
            NSString *currentValue = (addAddressTextField ? addAddressTextField.text : nil);
            
            addAddressCell.mxkLabelLeadingConstraint.constant = 0;
            addAddressCell.mxkTextFieldLeadingConstraint.constant = tableView.vc_separatorInset.left;
            addAddressCell.mxkTextFieldTrailingConstraint.constant = 15;
            
            addAddressCell.mxkLabel.text = nil;
            
            addAddressCell.accessoryType = UITableViewCellAccessoryNone;
            addAddressCell.accessoryView = [[UIImageView alloc] initWithImage:[AssetImages.plusIcon.image vc_tintedImageUsingColor:ThemeService.shared.theme.textPrimaryColor]];
            
            addAddressTextField = addAddressCell.mxkTextField;
            addAddressTextField.placeholder = [VectorL10n roomDetailsNewAddressPlaceholder:self.mainSession.matrixRestClient.homeserverSuffix];
            addAddressTextField.attributedPlaceholder = [[NSAttributedString alloc]
                                                         initWithString:addAddressTextField.placeholder
                                                         attributes:@{NSForegroundColorAttributeName: ThemeService.shared.theme.placeholderTextColor}];
            addAddressTextField.userInteractionEnabled = YES;
            addAddressTextField.text = currentValue;
            addAddressTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
            
            addAddressTextField.tintColor = ThemeService.shared.theme.tintColor;
            addAddressTextField.font = [UIFont systemFontOfSize:17];
            addAddressTextField.borderStyle = UITextBorderStyleNone;
            addAddressTextField.textAlignment = NSTextAlignmentLeft;
            
            addAddressTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            addAddressTextField.spellCheckingType = UITextSpellCheckingTypeNo;
            addAddressTextField.delegate = self;
            
            cell = addAddressCell;
        }
        else if (row == ROOM_SETTINGS_ROOM_ADDRESS_NO_LOCAL_ADDRESS)
        {
            UITableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAddressCellViewIdentifier forIndexPath:indexPath];
            
            addressCell.textLabel.font = [UIFont systemFontOfSize:16];
            addressCell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            addressCell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            addressCell.accessoryView = nil;
            addressCell.accessoryType = UITableViewCellAccessoryNone;
            addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (mxRoom.isDirect)
            {
                addressCell.textLabel.text = [VectorL10n roomDetailsNoLocalAddressesForDm];
            }
            else
            {
                addressCell.textLabel.text = [VectorL10n roomDetailsNoLocalAddresses];
            }
            
            cell = addressCell;
        }
        else
        {
            UITableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAddressCellViewIdentifier forIndexPath:indexPath];
            
            addressCell.textLabel.font = [UIFont systemFontOfSize:16];
            addressCell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            addressCell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            addressCell.accessoryView = nil;
            addressCell.accessoryType = UITableViewCellAccessoryNone;
            addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            NSInteger index = row - ROOM_SETTINGS_ROOM_ADDRESS_ALIAS_OFFSET;
            
            if (index < roomAddresses.count)
            {
                NSString *alias = roomAddresses[index];
                NSString *canonicalAlias;
                
                if (updatedItemsDict[kRoomSettingsCanonicalAliasKey])
                {
                    canonicalAlias = updatedItemsDict[kRoomSettingsCanonicalAliasKey];
                }
                else
                {
                    canonicalAlias = mxRoomState.canonicalAlias;
                }
                
                addressCell.textLabel.text = alias;
                
                // Check whether this alias is the main address
                if (canonicalAlias)
                {
                    if ([alias isEqualToString:canonicalAlias])
                    {
                        addressCell.accessoryView = [[UIImageView alloc] initWithImage:AssetImages.mainAliasIcon.image];
                    }
                }
            }
            
            cell = addressCell;
        }
    }
    else if (section == SECTION_TAG_BANNED_USERS)
    {
        UITableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAddressCellViewIdentifier forIndexPath:indexPath];
        
        addressCell.textLabel.font = [UIFont systemFontOfSize:16];
        addressCell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        addressCell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        addressCell.accessoryView = nil;
        addressCell.accessoryType = UITableViewCellAccessoryNone;
        addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        addressCell.textLabel.text = bannedMembers[row].userId;
        
        cell = addressCell;
    }
    else if (section == SECTION_TAG_BANNED_ADVANCED)
    {
        if (row == ROOM_SETTINGS_ADVANCED_ROOM_ID)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAdvancedCellViewIdentifier];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kRoomSettingsAdvancedCellViewIdentifier];
            }
            
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            if (mxRoom.isDirect)
            {
                cell.textLabel.text = [VectorL10n roomDetailsAdvancedRoomIdForDm];
            }
            else
            {
                cell.textLabel.text = [VectorL10n roomDetailsAdvancedRoomId];
            }
            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
            cell.detailTextLabel.text = mxRoomState.roomId;
            cell.detailTextLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (row == ROOM_SETTINGS_ADVANCED_ENCRYPT_TO_VERIFIED)
        {
            MXKTableViewCellWithLabelAndSwitch *roomBlacklistUnverifiedDevicesCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            [roomBlacklistUnverifiedDevicesCell.mxkSwitch addTarget:self action:@selector(toggleBlacklistUnverifiedDevice:) forControlEvents:UIControlEventValueChanged];
            roomBlacklistUnverifiedDevicesCell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
            
            roomBlacklistUnverifiedDevicesCell.mxkLabel.text = [VectorL10n roomDetailsAdvancedE2eEncryptionBlacklistUnverifiedDevices];
            
            // For the switch value, use by order:
            // - the MXCrypto.globalBlacklistUnverifiedDevices if its value is YES
            //   In this case, the switch is disabled.
            // - the changed value made by the user
            // - the value used by the crypto
            BOOL blacklistUnverifiedDevices;
            if (mxRoom.mxSession.crypto.globalBlacklistUnverifiedDevices)
            {
                blacklistUnverifiedDevices = YES;
                roomBlacklistUnverifiedDevicesCell.mxkSwitch.enabled = NO;
            }
            else
            {
                roomBlacklistUnverifiedDevicesCell.mxkSwitch.enabled = YES;
                
                if (updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey])
                {
                    blacklistUnverifiedDevices = [((NSNumber*)updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey]) boolValue];
                }
                else
                {
                    blacklistUnverifiedDevices = [mxRoom.mxSession.crypto isBlacklistUnverifiedDevicesInRoom:mxRoom.roomId];
                }
            }
            
            roomBlacklistUnverifiedDevicesCell.mxkSwitch.on = blacklistUnverifiedDevices;
            
            cell = roomBlacklistUnverifiedDevicesCell;
            
            // Force layout before reusing a cell (fix switch displayed outside the screen)
            [cell layoutIfNeeded];
        }
        else if (row == ROOM_SETTINGS_ADVANCED_ENCRYPTION_ENABLED)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
            }
            
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.numberOfLines = 0;
            if (mxRoom.isDirect)
            {
                cell.textLabel.text = [VectorL10n roomDetailsAdvancedE2eEncryptionEnabledForDm];
            }
            else
            {
                cell.textLabel.text = [VectorL10n roomDetailsAdvancedE2eEncryptionEnabled];
            }
            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (row == ROOM_SETTINGS_ADVANCED_ENABLE_ENCRYPTION)
        {
            MXKTableViewCellWithLabelAndSwitch *roomEncryptionCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            [roomEncryptionCell.mxkSwitch addTarget:self action:@selector(toggleEncryption:) forControlEvents:UIControlEventValueChanged];
            
            roomEncryptionCell.mxkLabel.text = [VectorL10n roomDetailsAdvancedEnableE2eEncryption];
            
            roomEncryptionCell.mxkSwitch.on = (updatedItemsDict[kRoomSettingsEncryptionKey] != nil);
            
            cell = roomEncryptionCell;
        }
        else if (row == ROOM_SETTINGS_ADVANCED_ENCRYPTION_DISABLED)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
            }
            
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.numberOfLines = 0;
            if (mxRoom.isDirect)
            {
                cell.textLabel.text = [VectorL10n roomDetailsAdvancedE2eEncryptionDisabledForDm];
            }
            else
            {
                cell.textLabel.text = [VectorL10n roomDetailsAdvancedE2eEncryptionDisabled];
            }
            cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    
    // Sanity check
    if (!cell)
    {
        MXLogDebug(@"[RoomSettingsViewController] cellForRowAtIndexPath: invalid indexPath");
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    
    return cell;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableView forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    cell.mxkSwitch.onTintColor = ThemeService.shared.theme.tintColor;
    [cell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];
    
    // Reset the stored `directoryVisibilitySwitch` if the corresponding cell is reused.
    if (cell.mxkSwitch == directoryVisibilitySwitch)
    {
        directoryVisibilitySwitch = nil;
    }
    
    // Force layout before reusing a cell (fix switch displayed outside the screen)
    [cell layoutIfNeeded];
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;
    
    if (self.tableView == tableView)
    {
        [self dismissFirstResponder];
        
        if (section == SECTION_TAG_MAIN)
        {
            if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
            {
                [self onRoomAvatarTap:nil];
            }
            else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
            {
                if (topicTextView.editable)
                {
                    [self editRoomTopic];
                }
            }
        }
        else if (section == SECTION_TAG_ACCESS)
        {
            BOOL isUpdated = NO;

            if (row == ROOM_SETTINGS_ROOM_ACCESS_MISSING_ADDRESS_WARNING)
            {
                // Scroll to room addresses section
                NSIndexPath *addressIndexPath = [_tableViewSections exactIndexPathForRowTag:0 sectionTag:SECTION_TAG_ADDRESSES];
                if (addressIndexPath)
                {
                    [tableView scrollToRowAtIndexPath:addressIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
                else
                {
                    addressIndexPath = [_tableViewSections nearestIndexPathForRowTag:0 sectionTag:SECTION_TAG_ADDRESSES];
                    if (addressIndexPath)
                    {
                        [tableView scrollToRowAtIndexPath:addressIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    }
                }
            }
            else if (row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ACCESS)
            {
                [self showRoomAccessFlow];
            }
            
            if (isUpdated)
            {
                [self updateSections];
                
                [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
            }
        }
        else if (section == SECTION_TAG_PROMOTION)
        {
            if (row == ROOM_SETTINGS_ROOM_PROMOTE_SECTION_ROW_SUGGEST)
            {
                [self showSuggestToSpaceMembers];
            }
        }
        else if (section == SECTION_TAG_HISTORY)
        {
            // Ignore the selection if the option is already enabled
            TableViewCellWithCheckBoxAndLabel *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (! selectedCell.isEnabled)
            {
                MXRoomHistoryVisibility historyVisibility;
                
                if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE)
                {
                    historyVisibility = kMXRoomHistoryVisibilityWorldReadable;
                }
                else if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY)
                {
                    historyVisibility = kMXRoomHistoryVisibilityShared;
                }
                else if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED)
                {
                    historyVisibility = kMXRoomHistoryVisibilityInvited;
                }
                else if (row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED)
                {
                    historyVisibility = kMXRoomHistoryVisibilityJoined;
                }
                
                if (historyVisibility)
                {
                    // Prompt the user before taking into account the change
                    [self shouldChangeHistoryVisibility:historyVisibility];
                }
            }
        }
        else if (section == SECTION_TAG_ADDRESSES)
        {
            if (row == ROOM_SETTINGS_ROOM_ADDRESS_NEW_ALIAS)
            {
                NSString *roomAlias = addAddressTextField.text;
                if (!roomAlias.length || [self addRoomAlias:roomAlias])
                {
                    // Reset the input field
                    addAddressTextField.text = nil;
                }
            }
            else if (row >= ROOM_SETTINGS_ROOM_ADDRESS_ALIAS_OFFSET)
            {
                // Prompt user on selected room alias
                UITableViewCell *addressCell = [tableView cellForRowAtIndexPath:indexPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self promptUserOnSelectedRoomAlias:addressCell.textLabel];
                    
                });
            }
        }
        else if (section == SECTION_TAG_BANNED_USERS)
        {
            // Show the RoomMemberDetailsViewController on this member so that
            // if the user has enough power level, he will be able to unban him
            RoomMemberDetailsViewController *roomMemberDetailsViewController = [RoomMemberDetailsViewController roomMemberDetailsViewController];
            [roomMemberDetailsViewController displayRoomMember:bannedMembers[row] withMatrixRoom:mxRoom];
            roomMemberDetailsViewController.delegate = self;
            roomMemberDetailsViewController.enableVoipCall = NO;
            
            [self.parentViewController.navigationController pushViewController:roomMemberDetailsViewController animated:NO];
        }
        else if (section == SECTION_TAG_BANNED_ADVANCED && row == ROOM_SETTINGS_ADVANCED_ROOM_ID)
        {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell)
            {
                // Prompt user to copy the room id (use dispatch_async here to not be stuck by the table refresh).
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self promptUserToCopyRoomId:cell.detailTextLabel];
                    
                });
            }
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *tagsIndexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger section = tagsIndexPath.section;
    NSInteger row = tagsIndexPath.row;
    
    // Add the swipe to delete only on addresses section
    if (section == SECTION_TAG_ADDRESSES && row >= ROOM_SETTINGS_ROOM_ADDRESS_ALIAS_OFFSET)
    {
        UIContextualAction *removeAddressAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                          title:@"    "
                                                                                        handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self removeAddressAtIndexPath:indexPath];
            completionHandler(YES);
        }];
        removeAddressAction.backgroundColor = ThemeService.shared.theme.headerBackgroundColor;
        removeAddressAction.image = [AssetImages.removeIcon.image vc_notRenderedImage];
        
        // Create swipe action configuration
        
        NSArray<UIContextualAction*> *actions = @[
            removeAddressAction
        ];
        
        UISwipeActionsConfiguration *swipeActionConfiguration = [UISwipeActionsConfiguration configurationWithActions:actions];
        swipeActionConfiguration.performsFirstActionWithFullSwipe = NO;
        return swipeActionConfiguration;
    }
    
    return nil;
}

#pragma mark -

- (void)shouldChangeHistoryVisibility:(MXRoomHistoryVisibility)historyVisibility
{
    // Prompt the user before applying the change on room history visibility
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomDetailsHistorySectionPromptTitle]
                                                       message:[VectorL10n roomDetailsHistorySectionPromptMsg]
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n continue]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           [self changeHistoryVisibility:historyVisibility];
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCChangeHistoryVisibilityAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)changeHistoryVisibility:(MXRoomHistoryVisibility)historyVisibility
{
    if (historyVisibility)
    {
        // Disable all history visibility options
        NSArray *tickCells = historyVisibilityTickCells.allValues;
        for (TableViewCellWithCheckBoxAndLabel *historyVisibilityTickCell in tickCells)
        {
            historyVisibilityTickCell.enabled = NO;
        }
        
        // Enable the selected option
        historyVisibilityTickCells[historyVisibility].enabled = YES;
        
        // Check the actual option
        if ([mxRoomState.historyVisibility isEqualToString:historyVisibility])
        {
            // No change on history visibility
            [updatedItemsDict removeObjectForKey:kRoomSettingsHistoryVisibilityKey];
        }
        else
        {
            updatedItemsDict[kRoomSettingsHistoryVisibilityKey] = historyVisibility;
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

- (BOOL)canSetCanonicalAlias
{
    BOOL canSetCanonicalAlias = NO;
    if (self.mainSession)
    {
        // Check user's power level to know whether the user is allowed to set the main address
        MXRoomPowerLevels *powerLevels = [mxRoomState powerLevels];
        NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];

        if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomAliases])
        {
            canSetCanonicalAlias = YES;
        }
    }

    return canSetCanonicalAlias;
}

- (void)shouldRemoveCanonicalAlias:(void (^)(void))didRemoveCanonicalAlias
{
    // Prompt the user before removing the current main address
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomDetailsAddressesDisableMainAddressPromptTitle]
                                                       message:[VectorL10n roomDetailsAddressesDisableMainAddressPromptMsg]
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n continue]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                           
                                                           // Remove the canonical address
                                                           if (self->mxRoomState.canonicalAlias.length)
                                                           {
                                                               self->updatedItemsDict[kRoomSettingsCanonicalAliasKey] = @"";
                                                           }
                                                           else
                                                           {
                                                               [self->updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
                                                           }
                                                           
                                                           [self updateSections];
                                                           
                                                           [self getNavigationItem].rightBarButtonItem.enabled = (self->updatedItemsDict.count != 0);
                                                           
                                                           if (didRemoveCanonicalAlias)
                                                           {
                                                               didRemoveCanonicalAlias();
                                                           }
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCRemoveCanonicalAliasAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId completion:(void (^)(void))completion
{
    [[AppDelegate theDelegate] showNewDirectChat:matrixId withMatrixSession:mxRoom.mxSession completion:completion];
}

#pragma mark - actions

- (void)onRoomAvatarTap:(UITapGestureRecognizer *)recognizer
{
    SingleImagePickerPresenter *singleImagePickerPresenter = [[SingleImagePickerPresenter alloc] initWithSession:self.mainSession];
    singleImagePickerPresenter.delegate = self;
    
    UIView *sourceView;
    
    NSIndexPath *indexPath = [_tableViewSections exactIndexPathForRowTag:ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO sectionTag:SECTION_TAG_MAIN];
    if (indexPath)
    {
        sourceView = [self.tableView cellForRowAtIndexPath:indexPath];
    }
    
    [singleImagePickerPresenter presentFrom:self sourceView:sourceView sourceRect:sourceView.bounds animated:YES];
    
    self.imagePickerPresenter = singleImagePickerPresenter;
}

- (void)toggleRoomNotification:(UISwitch*)theSwitch
{
    if (theSwitch.on == (mxRoom.isMute || mxRoom.isMentionsOnly))
    {
        [updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
    }
    else
    {
        updatedItemsDict[kRoomSettingsMuteNotifKey] = @(theSwitch.on);
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)toggleFavorite:(UISwitch *)theSwitch
{
    if (theSwitch.on)
    {
        if (mxRoom.accountData.tags[kMXRoomTagFavourite])
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsTagKey];
        }
        else
        {
            updatedItemsDict[kRoomSettingsTagKey] = kMXRoomTagFavourite;
        }
    }
    else
    {
        // The user wants to unselect this tag
        // Retrieve the current change on room tag (if any)
        NSString *updatedRoomTag = updatedItemsDict[kRoomSettingsTagKey];
        
        // Check the actual tag on mxRoom
        if (mxRoom.accountData.tags[kMXRoomTagFavourite])
        {
            // The actual tag must be updated, check whether another tag is already set
            if (!updatedRoomTag)
            {
                updatedItemsDict[kRoomSettingsTagKey] = @"";
            }
        }
        else if (updatedRoomTag && [updatedRoomTag isEqualToString:kMXRoomTagFavourite])
        {
            // Cancel the updated tag, but take into account the cancellation of another tag when 'tappedRoomTag' was selected.
            if (mxRoom.accountData.tags.count)
            {
                updatedItemsDict[kRoomSettingsTagKey] = @"";
            }
            else
            {
                [updatedItemsDict removeObjectForKey:kRoomSettingsTagKey];
            }
        }
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)toggleDirectChat:(UISwitch*)theSwitch
{
    if (theSwitch.on == mxRoom.isDirect)
    {
        [updatedItemsDict removeObjectForKey:kRoomSettingsDirectChatKey];
    }
    else
    {
        updatedItemsDict[kRoomSettingsDirectChatKey] = @(theSwitch.on);
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)toggleEncryption:(UISwitch*)theSwitch
{
    if (theSwitch.on)
    {
        updatedItemsDict[kRoomSettingsEncryptionKey] = @(YES);

        [self getNavigationItem].rightBarButtonItem.enabled = self->updatedItemsDict.count;
    }
    else
    {
        [updatedItemsDict removeObjectForKey:kRoomSettingsEncryptionKey];
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)toggleBlacklistUnverifiedDevice:(UISwitch*)theSwitch
{
    if ([mxRoom.mxSession.crypto isBlacklistUnverifiedDevicesInRoom:mxRoom.roomId] != theSwitch.on)
    {
        updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey] = @(theSwitch.on);
    }
    else
    {
        [updatedItemsDict removeObjectForKey:kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey];
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}


- (void)toggleDirectoryVisibility:(UISwitch*)theSwitch
{
    MXRoomDirectoryVisibility visibility = theSwitch.on ? kMXRoomDirectoryVisibilityPublic : kMXRoomDirectoryVisibilityPrivate;
    
    // Check whether the actual settings has been retrieved
    if (actualDirectoryVisibility)
    {
        if ([visibility isEqualToString:actualDirectoryVisibility])
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
        }
        else
        {
            updatedItemsDict[kRoomSettingsDirectoryKey] = visibility;
        }
    }
    else
    {
        updatedItemsDict[kRoomSettingsDirectoryKey] = visibility;
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)showRoomAccessFlow
{
    MXRoom *room = [self.mainSession roomWithRoomId:self.roomId];

    if (room) {
        roomAccessPresenter = [[RoomAccessCoordinatorBridgePresenter alloc] initWithRoom:room parentSpaceId:self.parentSpaceId];
        roomAccessPresenter.delegate = self;
        [roomAccessPresenter presentFrom:self animated:YES];
    }
}

- (void)showSuggestToSpaceMembers
{
    MXRoom *room = [self.mainSession roomWithRoomId:self.roomId];

    if (room) {
        roomSuggestionPresenter = [[RoomSuggestionCoordinatorBridgePresenter alloc] initWithRoom:room];
        roomSuggestionPresenter.delegate = self;
        [roomSuggestionPresenter presentFrom:self animated:YES];
    }
}

- (void)setRoomAliasAsMainAddress:(NSString *)alias
{
    NSString *currentCanonicalAlias = mxRoomState.canonicalAlias;
    
    // Update the current canonical address
    if ([alias isEqualToString:currentCanonicalAlias])
    {
        [updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
    }
    else
    {
        updatedItemsDict[kRoomSettingsCanonicalAliasKey] = alias;
    }
    
    [self updateSections];
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)removeAddressAtIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [_tableViewSections tagsIndexPathFromTableViewIndexPath:indexPath];
    NSInteger row = indexPath.row;
    
    row = ROOM_SETTINGS_ROOM_ADDRESS_ALIAS_OFFSET - row;
    
    if (row < roomAddresses.count)
    {
        NSString *alias = roomAddresses[row];
        [self removeRoomAlias:alias];
    }
}

- (void)removeRoomAlias:(NSString*)roomAlias
{
    NSString *canonicalAlias;
    
    if (updatedItemsDict[kRoomSettingsCanonicalAliasKey])
    {
        canonicalAlias = updatedItemsDict[kRoomSettingsCanonicalAliasKey];
    }
    else
    {
        canonicalAlias = mxRoomState.canonicalAlias;
    }
    
    // Check whether this alias is the main address
    if (canonicalAlias && [roomAlias isEqualToString:canonicalAlias])
    {
        // Prompt user before remove this alias which is the main address
        [self shouldRemoveCanonicalAlias:^{
            
            // The room alias can be removed now
            [self removeRoomAlias:roomAlias];
            
        }];
    }
    else
    {
        // Check whether the alias has just been added
        NSMutableArray<NSString *> *addedAlias = updatedItemsDict[kRoomSettingsNewAliasesKey];
        if (addedAlias && [addedAlias indexOfObject:roomAlias] != NSNotFound)
        {
            [addedAlias removeObject:roomAlias];
            
            if (!addedAlias.count)
            {
                [updatedItemsDict removeObjectForKey:kRoomSettingsNewAliasesKey];
            }
        }
        else
        {
            NSMutableArray<NSString *> *removedAlias = updatedItemsDict[kRoomSettingsRemovedAliasesKey];
            if (!removedAlias)
            {
                removedAlias = [NSMutableArray array];
                updatedItemsDict[kRoomSettingsRemovedAliasesKey] = removedAlias;
            }
            
            [removedAlias addObject:roomAlias];
        }
        
        [self updateSections];
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

- (BOOL)addRoomAlias:(NSString*)roomAlias
{
    // Check whether the provided alias is valid
    if ([MXTools isMatrixRoomAlias:roomAlias])
    {
        // Check whether this alias has just been deleted
        NSMutableArray<NSString *> *removedAlias = updatedItemsDict[kRoomSettingsRemovedAliasesKey];
        if (removedAlias && [removedAlias indexOfObject:roomAlias] != NSNotFound)
        {
            [removedAlias removeObject:roomAlias];
            
            if (!removedAlias.count)
            {
                [updatedItemsDict removeObjectForKey:kRoomSettingsRemovedAliasesKey];
            }
        }
        // Check whether this alias is not already defined for this room
        else if ([roomAddresses indexOfObject:roomAlias] == NSNotFound)
        {
            NSMutableArray<NSString *> *addedAlias = updatedItemsDict[kRoomSettingsNewAliasesKey];
            if (!addedAlias)
            {
                addedAlias = [NSMutableArray array];
                updatedItemsDict[kRoomSettingsNewAliasesKey] = addedAlias;
            }
            
            [addedAlias addObject:roomAlias];
        }
        
        if (!roomAddresses.count)
        {
            // The first added alias is defined as the main address by default.
            // Update the current canonical address.
            NSString *currentCanonicalAlias = mxRoomState.canonicalAlias;
            if (currentCanonicalAlias && [roomAlias isEqualToString:currentCanonicalAlias])
            {
                // The right canonical alias is already defined
                [updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
            }
            else
            {
                updatedItemsDict[kRoomSettingsCanonicalAliasKey] = roomAlias;
            }
        }
        
        [self updateSections];
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
        
        return YES;
    }
    
    // Prompt here user for invalid alias
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    NSString *alertMsg = [VectorL10n roomDetailsAddressesInvalidAddressPromptMsg:roomAlias];
    
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n roomDetailsAddressesInvalidAddressPromptTitle]
                                                       message:alertMsg
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           self->currentAlert = nil;
                                                       }
                                                       
                                                   }]];
    
    [currentAlert mxk_setAccessibilityIdentifier:@"RoomSettingsVCAddAliasAlert"];
    [self presentViewController:currentAlert animated:YES completion:nil];
    
    return NO;
}

#pragma mark - TableViewCellWithCheckBoxesDelegate

- (void)tableViewCellWithCheckBoxes:(TableViewCellWithCheckBoxes *)tableViewCellWithCheckBoxes didTapOnCheckBoxAtIndex:(NSUInteger)index
{
    if (tableViewCellWithCheckBoxes == roomTagCell)
    {
        NSString *tappedRoomTag = (index == 0) ? kMXRoomTagFavourite : kMXRoomTagLowPriority;
        BOOL isCurrentlySelected = [roomTagCell checkBoxValueAtIndex:index];
        
        if (isCurrentlySelected)
        {
            // The user wants to unselect this tag
            // Retrieve the current change on room tag (if any)
            NSString *updatedRoomTag = updatedItemsDict[kRoomSettingsTagKey];
            
            // Check the actual tag on mxRoom
            if (mxRoom.accountData.tags[tappedRoomTag])
            {
                // The actual tag must be updated, check whether another tag is already set
                if (!updatedRoomTag)
                {
                    updatedItemsDict[kRoomSettingsTagKey] = @"";
                }
            }
            else if (updatedRoomTag && [updatedRoomTag isEqualToString:tappedRoomTag])
            {
                // Cancel the updated tag, but take into account the cancellation of another tag when 'tappedRoomTag' was selected.
                if (mxRoom.accountData.tags.count)
                {
                    updatedItemsDict[kRoomSettingsTagKey] = @"";
                }
                else
                {
                    [updatedItemsDict removeObjectForKey:kRoomSettingsTagKey];
                }
            }
            
            // Unselect the tag
            [roomTagCell setCheckBoxValue:NO atIndex:index];
        }
        else
        {
            // The user wants to select this room tag
            // Check the actual tag on mxRoom
            if (mxRoom.accountData.tags[tappedRoomTag])
            {
                [updatedItemsDict removeObjectForKey:kRoomSettingsTagKey];
            }
            else
            {
                updatedItemsDict[kRoomSettingsTagKey] = tappedRoomTag;
            }
            
            // Select the tapped tag
            [roomTagCell setCheckBoxValue:YES atIndex:index];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
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
    
    UIImage *image = [UIImage imageWithData:imageData];
    if (image)
    {
        [self getNavigationItem].rightBarButtonItem.enabled = YES;
        
        updatedItemsDict[kRoomSettingsAvatarKey] = image;
        
        [self refreshRoomSettings];
    }
}

#pragma mark - TableViewSectionsDelegate

- (void)tableViewSectionsDidUpdateSections:(TableViewSections *)sections
{
    [self.tableView reloadData];
}

#pragma mark - RoomAccessCoordinatorBridgePresenterDelegate

- (void)roomAccessCoordinatorBridgePresenterDelegate:(RoomAccessCoordinatorBridgePresenter *)coordinatorBridgePresenter didCancelRoomWithId:(NSString *)roomId
{
    if (![roomId isEqualToString: self.roomId]) {
        // Room Access Coordinator upgraded the actual room -> Need to move to replacement room
        [self.delegate roomSettingsViewController:self didReplaceRoomWithReplacementId:roomId];
    }

    MXWeakify(self);
    [roomAccessPresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        self->roomAccessPresenter = nil;
    }];
}

- (void)roomAccessCoordinatorBridgePresenterDelegate:(RoomAccessCoordinatorBridgePresenter *)coordinatorBridgePresenter didCompleteRoomWithId:(NSString *)roomId
{
    if (![roomId isEqualToString: self.roomId]) {
        // Room Access Coordinator upgraded the actual room -> Need to move to replacement room
        [self.delegate roomSettingsViewController:self didReplaceRoomWithReplacementId:roomId];
    }

    MXWeakify(self);
    [roomAccessPresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        self->roomAccessPresenter = nil;
    }];
}

#pragma mark - RoomSuggestionCoordinatorBridgePresenterDelegate

- (void)roomSuggestionCoordinatorBridgePresenterDelegateDidCancel:(RoomSuggestionCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [roomSuggestionPresenter dismissWithAnimated:YES completion:nil];
    roomSuggestionPresenter = nil;
}

- (void)roomSuggestionCoordinatorBridgePresenterDelegateDidComplete:(RoomSuggestionCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    MXWeakify(self);
    [roomSuggestionPresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        self->roomSuggestionPresenter = nil;
        [self refreshRoomSettings];
    }];
}

@end
