/*
 Copyright 2016 OpenMarket Ltd
 
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

#import "RoomSettingsViewController.h"

#import "TableViewCellWithLabelAndLargeTextView.h"
#import "TableViewCellWithCheckBoxAndLabel.h"

#import "SegmentedViewController.h"

#import "RageShakeManager.h"

#import "VectorDesignValues.h"

#import "AvatarGenerator.h"
#import "Tools.h"

#import "MXRoom+Vector.h"

#import "AppDelegate.h"

#import "RoomMemberDetailsViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#define ROOM_SETTINGS_MAIN_SECTION_INDEX               0
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX        1
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX 2
#define ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX     3
#define ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX       4
#define ROOM_SETTINGS_ADVANCED_SECTION_INDEX           5
#define ROOM_SETTINGS_SECTION_COUNT                    6

#define ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO               0
#define ROOM_SETTINGS_MAIN_SECTION_ROW_NAME                1
#define ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC               2
#define ROOM_SETTINGS_MAIN_SECTION_ROW_TAG                 3
#define ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS  4
#define ROOM_SETTINGS_MAIN_SECTION_ROW_LEAVE               5
#define ROOM_SETTINGS_MAIN_SECTION_ROW_COUNT               6

#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_INVITED_ONLY            0
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE_APART_FROM_GUEST 1
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE                  2
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_SUB_COUNT               3

#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE                     0
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY               1
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED 2
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED  3
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_COUNT                      4

#define ROOM_TOPIC_CELL_HEIGHT 124

#define SECTION_TITLE_PADDING_WHEN_HIDDEN 0.01f

NSString *const kRoomSettingsAvatarKey = @"kRoomSettingsAvatarKey";
NSString *const kRoomSettingsAvatarURLKey = @"kRoomSettingsAvatarURLKey";
NSString *const kRoomSettingsNameKey = @"kRoomSettingsNameKey";
NSString *const kRoomSettingsTopicKey = @"kRoomSettingsTopicKey";
NSString *const kRoomSettingsTagKey = @"kRoomSettingsTagKey";
NSString *const kRoomSettingsMuteNotifKey = @"kRoomSettingsMuteNotifKey";
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

@interface RoomSettingsViewController ()
{
    // The updated user data
    NSMutableDictionary<NSString*, id> *updatedItemsDict;
    
    // The current table items
    UITextField* nameTextField;
    UITextView* topicTextView;
    
    // The room tag items
    TableViewCellWithCheckBoxes *roomTagCell;
    
    // Room Access items
    NSInteger directoryVisibilityIndex;
    NSInteger missingAddressWarningIndex;
    TableViewCellWithCheckBoxAndLabel *accessInvitedOnlyTickCell;
    TableViewCellWithCheckBoxAndLabel *accessAnyoneApartGuestTickCell;
    TableViewCellWithCheckBoxAndLabel *accessAnyoneTickCell;
    UISwitch *directoryVisibilitySwitch;
    MXRoomDirectoryVisibility actualDirectoryVisibility;
    MXHTTPOperation* actualDirectoryVisibilityRequest;
    
    // History Visibility items
    NSMutableDictionary<MXRoomHistoryVisibility, TableViewCellWithCheckBoxAndLabel*> *historyVisibilityTickCells;
    
    // Room aliases
    NSMutableArray<NSString *> *roomAddresses;
    NSUInteger localAddressesCount;
    NSInteger roomAddressNewAliasIndex;
    UITextField* addAddressTextField;
    
    // The potential image loader
    MXMediaLoader *uploader;
    
    // The pending http operation
    MXHTTPOperation* pendingOperation;
    
    // the updating spinner
    UIActivityIndicatorView* updatingSpinner;
    
    MXKAlert *currentAlert;
    
    // listen to more events than the mother class
    id extraEventsListener;
    
    // picker
    MediaPickerViewController* mediaPicker;
    
    // switches
    UISwitch *roomNotifSwitch;
    UISwitch *roomEncryptionSwitch;
    UISwitch *roomEncryptionBlacklistUnverifiedDevicesSwitch;

    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id appDelegateDidTapStatusBarNotificationObserver;

    // A copy of the banned members
    NSArray<MXRoomMember*> *bannedMembers;
}
@end

@implementation RoomSettingsViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    _selectedRoomSettingsField = RoomSettingsViewControllerFieldNone;
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)initWithSession:(MXSession *)session andRoomId:(NSString *)roomId
{
    [super initWithSession:session andRoomId:roomId];

    // Add an additional listener to update banned users
    extraEventsListener = [mxRoom.liveTimeline listenToEventsOfTypes:@[kMXEventTypeStringRoomMember] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

        if (direction == MXTimelineDirectionForwards)
        {
            [self updateRoomState:mxRoom.state];
        }
    }];
}

- (void)updateRoomState:(MXRoomState *)newRoomState
{
    [super updateRoomState:newRoomState];

    bannedMembers = [mxRoomState membersWithMembership:MXMembershipBan];
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
    
    self.tableView.backgroundColor = kVectorColorLightGrey;
    
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

    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;

    [self setNavBarButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"RoomSettings"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateRules:) name:kMXNotificationCenterDidUpdateRules object:nil];
    
    // Observe appDelegateDidTapStatusBarNotificationObserver.
    appDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
        
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
        [currentAlert dismiss:NO];
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
        [mxRoom.liveTimeline removeListener:extraEventsListener];
        extraEventsListener = nil;
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
    [super refreshRoomSettings];
    
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

#pragma mark - 

- (void)setSelectedRoomSettingsField:(RoomSettingsViewControllerField)selectedRoomSettingsField
{
    // Check whether the view controller is already embedded inside a navigation controller
    if (self.navigationController)
    {
        [self dismissFirstResponder];
        
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
    [currentAlert dismiss:NO];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"room_details_save_changes_prompt", @"Vector", nil) style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            [strongSelf->updatedItemsDict removeAllObjects];
            
            [strongSelf withdrawViewControllerAnimated:YES completion:nil];
        }
        
    }];
    
    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            [strongSelf onSave:nil];
        }
        
    }];
    
    currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCSaveChangesAlert";
    [currentAlert showInViewController:self];
}

- (void)promptUserToCopyRoomId:(UILabel*)roomIdLabel
{
    if (roomIdLabel)
    {
        [currentAlert dismiss:NO];
        
        __weak typeof(self) weakSelf = self;
        
        currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
        
        [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_details_copy_room_id", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->currentAlert = nil;
                
                [[UIPasteboard generalPasteboard] setString:roomIdLabel.text];
            }
            
        }];
        
        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->currentAlert = nil;
            }
            
        }];
        
        currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCCopyRoomIdAlert";
        currentAlert.sourceView = roomIdLabel;
        [currentAlert showInViewController:self];
    }
}

- (void)promptUserOnSelectedRoomAlias:(UILabel*)roomAliasLabel
{
    if (roomAliasLabel)
    {
        [currentAlert dismiss:NO];
        
        __weak typeof(self) weakSelf = self;
        
        currentAlert = [[MXKAlert alloc] initWithTitle:nil message:nil style:MXKAlertStyleActionSheet];
        
        // Check whether the user is allowed to modify the main address.
        if (roomAddressNewAliasIndex != -1)
        {
            // Compare the selected alias with the current main address
            NSString *currentCanonicalAlias = mxRoomState.canonicalAlias;
            NSString *canonicalAlias;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey])
            {
                canonicalAlias = [updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey];
            }
            else
            {
                canonicalAlias = currentCanonicalAlias;
            }
            
            if (canonicalAlias && [roomAliasLabel.text isEqualToString:canonicalAlias])
            {
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_details_unset_main_address", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf->currentAlert = nil;
                        
                        // Prompt user before removing the current main address (use dispatch_async here to not be stuck by the table refresh).
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [strongSelf shouldRemoveCanonicalAlias:nil];
                            
                        });
                    }
                    
                }];
            }
            else
            {
                // Invite user to define this alias as the main room address
                [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_details_set_main_address", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf->currentAlert = nil;
                        
                        [strongSelf setRoomAliasAsMainAddress:roomAliasLabel.text];
                    }
                    
                }];
            }
        }
        
        [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_details_copy_room_address", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->currentAlert = nil;
                
                [[UIPasteboard generalPasteboard] setString:roomAliasLabel.text];
            }
            
        }];
        
        [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_details_copy_room_url", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->currentAlert = nil;
                
                // Create a matrix.to permalink to the room
                [[UIPasteboard generalPasteboard] setString:[MXTools permalinkToRoom:roomAliasLabel.text]];
            }
            
        }];
        
        // Check whether the user is allowed to remove a room alias.
        if (roomAddressNewAliasIndex != -1)
        {
            [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"delete"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                    
                    [strongSelf removeRoomAlias:roomAliasLabel.text];
                }
                
            }];
        }
        
        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->currentAlert = nil;
            }
            
        }];
        
        currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCOnSelectedAliasAlert";
        currentAlert.sourceView = roomAliasLabel;
        [currentAlert showInViewController:self];
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
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->actualDirectoryVisibilityRequest = nil;
            
            strongSelf->actualDirectoryVisibility = directoryVisibility;
            
            // Update the value of the displayed toggle button (if any)
            if (directoryVisibilitySwitch)
            {
                // Check a potential user's change before the end of the request
                MXRoomDirectoryVisibility modifiedDirectoryVisibility = [updatedItemsDict objectForKey:kRoomSettingsDirectoryKey];
                if (modifiedDirectoryVisibility)
                {
                    if ([modifiedDirectoryVisibility isEqualToString:directoryVisibility])
                    {
                        // The requested change corresponds to the actual settings
                        [updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
                        
                        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
                    }
                }
                
                directoryVisibilitySwitch.on = ([directoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic]);
            }
        }
        
    } failure:^(NSError *error) {
        
        NSLog(@"[RoomSettingsViewController] request to get directory visibility failed");
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->actualDirectoryVisibilityRequest = nil;
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
            [updatedItemsDict setObject:(topic ? topic : @"") forKey:kRoomSettingsTopicKey];
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
            [updatedItemsDict setObject:(displayName ? displayName : @"") forKey:kRoomSettingsNameKey];
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
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
}

- (void)onSaveFailed:(NSString*)message withKey:(NSString*)key
{
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:message style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            // Discard related change
            [strongSelf->updatedItemsDict removeObjectForKey:key];
            
            // Save anything else
            [strongSelf onSave:nil];
        }
        
    }];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"retry", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            // try again
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            [strongSelf onSave:nil];
        }
        
    }];
    
    currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCSaveChangesFailedAlert";
    [currentAlert showInViewController:self];
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
            if ([updatedItemsDict objectForKey:kRoomSettingsAvatarKey])
            {
                // Retrieve the current picture and make sure its orientation is up
                UIImage *updatedPicture = [MXKTools forceImageOrientationUp:[updatedItemsDict objectForKey:kRoomSettingsAvatarKey]];
                
                // Upload picture
                uploader = [MXMediaManager prepareUploaderWithMatrixSession:mxRoom.mxSession initialRange:0 andRange:1.0];
                
                [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url) {
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->uploader = nil;
                        
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsAvatarKey];
                        [strongSelf->updatedItemsDict setObject:url forKey:kRoomSettingsAvatarURLKey];
                        
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Image upload failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->uploader = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_avatar", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsAvatarKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            NSString* photoUrl = [updatedItemsDict objectForKey:kRoomSettingsAvatarURLKey];
            if (photoUrl)
            {
                pendingOperation = [mxRoom setAvatar:photoUrl success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsAvatarURLKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Failed to update the room avatar");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_avatar", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsAvatarURLKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // has a new room name
            NSString* roomName = [updatedItemsDict objectForKey:kRoomSettingsNameKey];
            if (roomName)
            {
                pendingOperation = [mxRoom setName:roomName success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsNameKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Rename room failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_room_name", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsNameKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // has a new room topic
            NSString* roomTopic = [updatedItemsDict objectForKey:kRoomSettingsTopicKey];
            if (roomTopic)
            {
                pendingOperation = [mxRoom setTopic:roomTopic success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsTopicKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Rename topic failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_topic", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsTopicKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // Room guest access
            MXRoomGuestAccess guestAccess = [updatedItemsDict objectForKey:kRoomSettingsGuestAccessKey];
            if (guestAccess)
            {
                pendingOperation = [mxRoom setGuestAccess:guestAccess success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Update guest access failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_room_guest_access", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsGuestAccessKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // Room join rule
            MXRoomJoinRule joinRule = [updatedItemsDict objectForKey:kRoomSettingsJoinRuleKey];
            if (joinRule)
            {
                pendingOperation = [mxRoom setJoinRule:joinRule success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Update join rule failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_room_join_rule", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsJoinRuleKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // History visibility
            MXRoomHistoryVisibility visibility = [updatedItemsDict objectForKey:kRoomSettingsHistoryVisibilityKey];
            if (visibility)
            {
                pendingOperation = [mxRoom setHistoryVisibility:visibility success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsHistoryVisibilityKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Update history visibility failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_history_visibility", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsHistoryVisibilityKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            // Room addresses
            NSMutableArray<NSString *> *aliases = [updatedItemsDict objectForKey:kRoomSettingsNewAliasesKey];
            if (aliases.count)
            {
                NSString *roomAlias = aliases.firstObject;
                
                pendingOperation = [mxRoom addAlias:roomAlias success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        if (aliases.count > 1)
                        {
                            [aliases removeObjectAtIndex:0];
                            [strongSelf->updatedItemsDict setObject:aliases forKey:kRoomSettingsNewAliasesKey];
                        }
                        else
                        {
                            [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsNewAliasesKey];
                        }
                        
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Add room aliases failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_add_room_aliases", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsNewAliasesKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            aliases = [updatedItemsDict objectForKey:kRoomSettingsRemovedAliasesKey];
            if (aliases.count)
            {
                NSString *roomAlias = aliases.firstObject;
                
                pendingOperation = [mxRoom removeAlias:roomAlias success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        if (aliases.count > 1)
                        {
                            [aliases removeObjectAtIndex:0];
                            [strongSelf->updatedItemsDict setObject:aliases forKey:kRoomSettingsRemovedAliasesKey];
                        }
                        else
                        {
                            [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsRemovedAliasesKey];
                        }
                        
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Remove room aliases failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_remove_room_aliases", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsRemovedAliasesKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
            
            NSString* canonicalAlias = [updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey];
            if (canonicalAlias)
            {
                pendingOperation = [mxRoom setCanonicalAlias:canonicalAlias success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
                        [strongSelf onSave:nil];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] Update canonical alias failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->pendingOperation = nil;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            NSString* message = error.localizedDescription;
                            if (!message.length)
                            {
                                message = NSLocalizedStringFromTable(@"room_details_fail_to_update_room_canonical_alias", @"Vector", nil);
                            }
                            [strongSelf onSaveFailed:message withKey:kRoomSettingsCanonicalAliasKey];
                            
                        });
                    }
                    
                }];
                
                return;
            }
        }
        
        // Update here other room settings
        NSString *roomTag = [updatedItemsDict objectForKey:kRoomSettingsTagKey];
        if (roomTag)
        {
            if (!roomTag.length)
            {
                roomTag = nil;
            }
            
            [mxRoom setRoomTag:roomTag completion:^{
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsTagKey];
                    [strongSelf onSave:nil];
                }
                
            }];
            
            return;
        }
        
        if ([updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey])
        {
            if (roomNotifSwitch.on)
            {
                [mxRoom mentionsOnly:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                        [strongSelf onSave:nil];
                    }
                    
                }];
            }
            else
            {
                [mxRoom allMessages:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                        [strongSelf onSave:nil];
                    }
                    
                }];
            }
            return;
        }
        
        // Room directory visibility
        MXRoomDirectoryVisibility directoryVisibility = [updatedItemsDict objectForKey:kRoomSettingsDirectoryKey];
        if (directoryVisibility)
        {
            [mxRoom setDirectoryVisibility:directoryVisibility success:^{
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
                    [strongSelf onSave:nil];
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[RoomSettingsViewController] Update room directory visibility failed");
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    strongSelf->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = NSLocalizedStringFromTable(@"room_details_fail_to_update_room_directory_visibility", @"Vector", nil);
                        }
                        [strongSelf onSaveFailed:message withKey:kRoomSettingsDirectoryKey];
                        
                    });
                }
                
            }];
            
            return;
        }

        // Room encryption
        if ([updatedItemsDict objectForKey:kRoomSettingsEncryptionKey])
        {
            pendingOperation = [mxRoom enableEncryptionWithAlgorithm:kMXCryptoMegolmAlgorithm success:^{

                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;

                    strongSelf->pendingOperation = nil;

                    [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsEncryptionKey];
                    [strongSelf onSave:nil];
                }

            } failure:^(NSError *error) {

                NSLog(@"[RoomSettingsViewController] Enabling encrytion failed. Error: %@", error);

                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;

                    strongSelf->pendingOperation = nil;

                    dispatch_async(dispatch_get_main_queue(), ^{

                        NSString* message = error.localizedDescription;
                        if (!message.length)
                        {
                            message = NSLocalizedStringFromTable(@"room_details_fail_to_enable_encryption", @"Vector", nil);
                        }
                        [strongSelf onSaveFailed:message withKey:kRoomSettingsEncryptionKey];

                    });
                }

            }];

            return;
        }

        // Room settings on blacklist unverified devices
        if ([updatedItemsDict objectForKey:kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey])
        {
            BOOL blacklistUnverifiedDevices = [((NSNumber*)updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey]) boolValue];
            [mxRoom.mxSession.crypto setBlacklistUnverifiedDevicesInRoom:mxRoom.roomId blacklist:blacklistUnverifiedDevices];
        }
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = NO;
    
    [self stopActivityIndicator];
    
    [self withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Refresh here the room addresses list
    [roomAddresses removeAllObjects];
    localAddressesCount = 0;
    
    NSArray *removedAliases = [updatedItemsDict objectForKey:kRoomSettingsRemovedAliasesKey];
    
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
    
    aliases = [updatedItemsDict objectForKey:kRoomSettingsNewAliasesKey];
    for (NSString *alias in aliases)
    {
        // Add this new alias to local addresses
        [roomAddresses insertObject:alias atIndex:localAddressesCount];
        localAddressesCount++;
    }
    
    // Return the fixed number of sections
    return ROOM_SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        count = ROOM_SETTINGS_MAIN_SECTION_ROW_COUNT;
    }
    else if (section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
    {
        missingAddressWarningIndex = -1;
        directoryVisibilityIndex = -1;
        
        count = ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_SUB_COUNT;
        
        // Check whether a room address is required for the current join rule
        NSString *joinRule = [updatedItemsDict objectForKey:kRoomSettingsJoinRuleKey];
        if (!joinRule)
        {
            // Use the actual values if no change is pending.
            joinRule = mxRoomState.joinRule;
        }
        
        if ([joinRule isEqualToString:kMXRoomJoinRulePublic] && !roomAddresses.count)
        {
            // Notify the user that a room address is required.
            missingAddressWarningIndex = count++;
        }
        
        directoryVisibilityIndex = count++;
    }
    else if (section == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX)
    {
        count = ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_COUNT;
    }
    else if (section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
    {
        roomAddressNewAliasIndex = -1;
        
        count = (localAddressesCount ? roomAddresses.count : roomAddresses.count + 1);
        
        if (self.mainSession)
        {
            // Check user's power level to know whether the user is allowed to add room alias
            MXRoomPowerLevels *powerLevels = [mxRoom.state powerLevels];
            NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
            
            if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomAliases])
            {
                roomAddressNewAliasIndex = count++;
            }
        }
    }
    else if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
    {
        count = bannedMembers.count;
    }
    else if (section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX)
    {
        count = 1;

        if (mxRoom.mxSession.crypto)
        {
            count++;

            if (mxRoom.state.isEncrypted)
            {
                count++;
            }
        }
    }
    
    return count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
    {
        return NSLocalizedStringFromTable(@"room_details_access_section", @"Vector", nil);
    }
    else if (section == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX)
    {
        return NSLocalizedStringFromTable(@"room_details_history_section", @"Vector", nil);
    }
    else if (section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
    {
        return NSLocalizedStringFromTable(@"room_details_addresses_section", @"Vector", nil);
    }
    else if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
    {
        if (bannedMembers.count)
        {
            return NSLocalizedStringFromTable(@"room_details_banned_users_section", @"Vector", nil);
        }
        else
        {
            // Hide this section
            return nil;
        }
    }
    else if (section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX)
    {
        return NSLocalizedStringFromTable(@"room_details_advanced_section", @"Vector", nil);
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:UITableViewHeaderFooterView.class])
    {
        // Customize label style
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView*)view;
        tableViewHeaderFooterView.textLabel.textColor = kVectorTextColorBlack;
        tableViewHeaderFooterView.textLabel.font = [UIFont systemFontOfSize:15];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX && bannedMembers.count == 0)
    {
        // Hide this section
        return SECTION_TITLE_PADDING_WHEN_HIDDEN;
    }
    else
    {
        return [super tableView:tableView heightForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX && bannedMembers.count == 0)
    {
        // Hide this section
        return SECTION_TITLE_PADDING_WHEN_HIDDEN;
    }
    else
    {
        return [super tableView:tableView heightForFooterInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
        {
            return ROOM_TOPIC_CELL_HEIGHT;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    UITableViewCell* cell;
    
    // Check user's power level to know which settings are editable.
    MXRoomPowerLevels *powerLevels = [mxRoom.state powerLevels];
    NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];
    
    // general settings
    if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS)
        {
            MXKTableViewCellWithLabelAndSwitch *roomNotifCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomNotifCell.mxkLabelLeadingConstraint.constant = roomNotifCell.separatorInset.left;
            roomNotifCell.mxkSwitchTrailingConstraint.constant = 15;
            
            [roomNotifCell.mxkSwitch addTarget:self action:@selector(onSwitchUpdate:) forControlEvents:UIControlEventValueChanged];
            roomNotifCell.mxkSwitch.onTintColor = kVectorColorGreen;
            
            roomNotifCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_mute_notifs", @"Vector", nil);
            roomNotifCell.mxkLabel.textColor = kVectorTextColorBlack;
            roomNotifSwitch = roomNotifCell.mxkSwitch;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey])
            {
                roomNotifSwitch.on = ((NSNumber*)[updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey]).boolValue;
            }
            else
            {
                roomNotifSwitch.on = mxRoom.isMute || mxRoom.isMentionsOnly;
            }
            
            cell = roomNotifCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
        {
            MXKTableViewCellWithLabelAndMXKImageView *roomPhotoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomPhotoCell.mxkLabelLeadingConstraint.constant = roomPhotoCell.separatorInset.left;
            roomPhotoCell.mxkImageViewTrailingConstraint.constant = 10;
            
            roomPhotoCell.mxkImageViewWidthConstraint.constant = roomPhotoCell.mxkImageViewHeightConstraint.constant = 30;
            
            roomPhotoCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
            
            // Handle tap on avatar to update it
            if (!roomPhotoCell.mxkImageView.gestureRecognizers.count)
            {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRoomAvatarTap:)];
                [roomPhotoCell.mxkImageView addGestureRecognizer:tap];
            }
            
            roomPhotoCell.mxkImageView.backgroundColor = [UIColor clearColor];
            
            roomPhotoCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_photo", @"Vector", nil);
            roomPhotoCell.mxkLabel.textColor = kVectorTextColorBlack;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsAvatarKey])
            {
                roomPhotoCell.mxkImageView.image = (UIImage*)[updatedItemsDict objectForKey:kRoomSettingsAvatarKey];
            }
            else
            {
                [mxRoom setRoomAvatarImageIn:roomPhotoCell.mxkImageView];
                
                roomPhotoCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomAvatar]);
                roomPhotoCell.mxkImageView.alpha = roomPhotoCell.userInteractionEnabled ? 1.0f : 0.5f;
            }
            
            cell = roomPhotoCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
        {
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsTopicCellViewIdentifier forIndexPath:indexPath];
            
            roomTopicCell.labelLeadingConstraint.constant = roomTopicCell.separatorInset.left;
            
            roomTopicCell.label.text = NSLocalizedStringFromTable(@"room_details_topic", @"Vector", nil);
            
            topicTextView = roomTopicCell.textView;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsTopicKey])
            {
                topicTextView.text = (NSString*)[updatedItemsDict objectForKey:kRoomSettingsTopicKey];
            }
            else
            {
                topicTextView.text = mxRoomState.topic;
            }
                        
            topicTextView.tintColor = kVectorColorGreen;
            topicTextView.font = [UIFont systemFontOfSize:15];
            topicTextView.bounces = NO;
            topicTextView.delegate = self;
            
            // disable the edition if the user cannot update it
            topicTextView.editable = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic]);
            topicTextView.textColor = kVectorTextColorGray;
            
            cell = roomTopicCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_NAME)
        {
            MXKTableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsNameCellViewIdentifier forIndexPath:indexPath];
            
            roomNameCell.mxkLabelLeadingConstraint.constant = roomNameCell.separatorInset.left;
            roomNameCell.mxkTextFieldLeadingConstraint.constant = 16;
            roomNameCell.mxkTextFieldTrailingConstraint.constant = 15;
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_room_name", @"Vector", nil);
            roomNameCell.mxkLabel.textColor = kVectorTextColorBlack;
            
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            roomNameCell.accessoryView = nil;
            
            nameTextField = roomNameCell.mxkTextField;
            
            nameTextField.tintColor = kVectorColorGreen;
            nameTextField.font = [UIFont systemFontOfSize:17];
            nameTextField.borderStyle = UITextBorderStyleNone;
            nameTextField.textAlignment = NSTextAlignmentRight;
            nameTextField.delegate = self;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsNameKey])
            {
                nameTextField.text = (NSString*)[updatedItemsDict objectForKey:kRoomSettingsNameKey];
            }
            else
            {
                nameTextField.text = mxRoomState.name;
            }
            
            // disable the edition if the user cannot update it
            nameTextField.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName]);
            nameTextField.textColor = kVectorTextColorGray;
            
            // Add a "textFieldDidChange" notification method to the text field control.
            [nameTextField addTarget:self action:@selector(onTextFieldUpdate:) forControlEvents:UIControlEventEditingChanged];
            
            cell = roomNameCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_TAG)
        {
            roomTagCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxes defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomTagCell.mainContainerLeadingConstraint.constant = roomTagCell.separatorInset.left;
            
            roomTagCell.checkBoxesNumber = 2;
            
            roomTagCell.allowsMultipleSelection = NO;
            roomTagCell.delegate = self;
            
            NSArray *labels = roomTagCell.labels;
            UILabel *label;
            label = labels[0];
            label.text = NSLocalizedStringFromTable(@"room_details_favourite_tag", @"Vector", nil);
            label = labels[1];
            label.text = NSLocalizedStringFromTable(@"room_details_low_priority_tag", @"Vector", nil);
            
            if ([updatedItemsDict objectForKey:kRoomSettingsTagKey])
            {
                NSString *roomTag = [updatedItemsDict objectForKey:kRoomSettingsTagKey];
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
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_LEAVE)
        {
            MXKTableViewCellWithButton *leaveCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier] forIndexPath:indexPath];
            
            NSString* title = NSLocalizedStringFromTable(@"leave", @"Vector", nil);
            
            [leaveCell.mxkButton setTitle:title forState:UIControlStateNormal];
            [leaveCell.mxkButton setTitle:title forState:UIControlStateHighlighted];
            [leaveCell.mxkButton setTintColor:kVectorColorGreen];
            leaveCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [leaveCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [leaveCell.mxkButton addTarget:self action:@selector(onLeave:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = leaveCell;
        }
    }
    else if (indexPath.section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
    {
        if (indexPath.row == directoryVisibilityIndex)
        {
            MXKTableViewCellWithLabelAndSwitch *directoryToggleCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
            
            directoryToggleCell.mxkLabelLeadingConstraint.constant = directoryToggleCell.separatorInset.left;
            directoryToggleCell.mxkSwitchTrailingConstraint.constant = 15;
            
            directoryToggleCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_access_section_directory_toggle", @"Vector", nil);
            directoryToggleCell.mxkLabel.textColor = kVectorTextColorBlack;
            
            directoryVisibilitySwitch = directoryToggleCell.mxkSwitch;

            // Workaround to avoid mixing between switches
            // TODO: this is a design issue with switch within UITableViewCell that must fix everywhere
            if (roomEncryptionSwitch == directoryVisibilitySwitch)
            {
                roomEncryptionSwitch = nil;
            }
            else if (roomNotifSwitch == directoryVisibilitySwitch)
            {
                roomNotifSwitch = nil;
            }
            else if (roomEncryptionBlacklistUnverifiedDevicesSwitch == directoryVisibilitySwitch)
            {
                roomEncryptionBlacklistUnverifiedDevicesSwitch = nil;
            }

            [directoryVisibilitySwitch addTarget:self action:@selector(onSwitchUpdate:) forControlEvents:UIControlEventValueChanged];
            directoryVisibilitySwitch.onTintColor = kVectorColorGreen;
            
            if ([updatedItemsDict objectForKey:kRoomSettingsDirectoryKey])
            {
                directoryVisibilitySwitch.on = ((NSNumber*)[updatedItemsDict objectForKey:kRoomSettingsDirectoryKey]).boolValue;
            }
            else
            {
                // Use the last retrieved value if any
                directoryVisibilitySwitch.on = actualDirectoryVisibility ? [actualDirectoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic] : NO;
            }
            
            // Check whether the user can change this option
            directoryVisibilitySwitch.enabled = (oneSelfPowerLevel >= powerLevels.stateDefault);
            
            cell = directoryToggleCell;
        }
        else if (indexPath.row == missingAddressWarningIndex)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsWarningCellViewIdentifier forIndexPath:indexPath];
            
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.textColor = kVectorColorPinkRed;
            cell.textLabel.numberOfLines = 0;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = NSLocalizedStringFromTable(@"room_details_access_section_no_address_warning", @"Vector", nil);
        }
        else
        {
            TableViewCellWithCheckBoxAndLabel *roomAccessCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomAccessCell.checkBoxLeadingConstraint.constant = roomAccessCell.separatorInset.left;
            
            // Retrieve the potential updated values for joinRule and guestAccess
            NSString *joinRule = [updatedItemsDict objectForKey:kRoomSettingsJoinRuleKey];
            NSString *guestAccess = [updatedItemsDict objectForKey:kRoomSettingsGuestAccessKey];
            
            // Use the actual values if no change is pending
            if (!joinRule)
            {
                joinRule = mxRoomState.joinRule;
            }
            if (!guestAccess)
            {
                guestAccess = mxRoomState.guestAccess;
            }
            
            if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_INVITED_ONLY)
            {
                roomAccessCell.label.text = NSLocalizedStringFromTable(@"room_details_access_section_invited_only", @"Vector", nil);
                
                roomAccessCell.enabled = ([joinRule isEqualToString:kMXRoomJoinRuleInvite]);
                
                accessInvitedOnlyTickCell = roomAccessCell;
            }
            else if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE_APART_FROM_GUEST)
            {
                roomAccessCell.label.text = NSLocalizedStringFromTable(@"room_details_access_section_anyone_apart_from_guest", @"Vector", nil);
                
                roomAccessCell.enabled = ([joinRule isEqualToString:kMXRoomJoinRulePublic] && [guestAccess isEqualToString:kMXRoomGuestAccessForbidden]);
                
                accessAnyoneApartGuestTickCell = roomAccessCell;
            }
            else if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE)
            {
                roomAccessCell.label.text = NSLocalizedStringFromTable(@"room_details_access_section_anyone", @"Vector", nil);
                
                roomAccessCell.enabled = ([joinRule isEqualToString:kMXRoomJoinRulePublic] && [guestAccess isEqualToString:kMXRoomGuestAccessCanJoin]);
                
                accessAnyoneTickCell = roomAccessCell;
            }
            
            // Check whether the user can change this option
            roomAccessCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomJoinRules]);
            roomAccessCell.checkBox.alpha = roomAccessCell.userInteractionEnabled ? 1.0f : 0.5f;
            
            cell = roomAccessCell;
        }
    }
    else if (indexPath.section == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX)
    {
        TableViewCellWithCheckBoxAndLabel *historyVisibilityCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier] forIndexPath:indexPath];
        
        historyVisibilityCell.checkBoxLeadingConstraint.constant = historyVisibilityCell.separatorInset.left;
        
        // Retrieve first the potential updated value for history visibility
        NSString *visibility = [updatedItemsDict objectForKey:kRoomSettingsHistoryVisibilityKey];
        
        // Use the actual value if no change is pending
        if (!visibility)
        {
            visibility = mxRoomState.historyVisibility;
        }
        
        if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = NSLocalizedStringFromTable(@"room_details_history_section_anyone", @"Vector", nil);
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityWorldReadable]);
            
            [historyVisibilityTickCells setObject:historyVisibilityCell forKey:kMXRoomHistoryVisibilityWorldReadable];
        }
        else if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = NSLocalizedStringFromTable(@"room_details_history_section_members_only", @"Vector", nil);
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityShared]);
            
            [historyVisibilityTickCells setObject:historyVisibilityCell forKey:kMXRoomHistoryVisibilityShared];
        }
        else if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = NSLocalizedStringFromTable(@"room_details_history_section_members_only_since_invited", @"Vector", nil);
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityInvited]);
            
            [historyVisibilityTickCells setObject:historyVisibilityCell forKey:kMXRoomHistoryVisibilityInvited];
        }
        else if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED)
        {
            historyVisibilityCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
            historyVisibilityCell.label.text = NSLocalizedStringFromTable(@"room_details_history_section_members_only_since_joined", @"Vector", nil);
            
            historyVisibilityCell.enabled = ([visibility isEqualToString:kMXRoomHistoryVisibilityJoined]);
            
            [historyVisibilityTickCells setObject:historyVisibilityCell forKey:kMXRoomHistoryVisibilityJoined];
        }
        
        // Check whether the user can change this option
        historyVisibilityCell.userInteractionEnabled = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomHistoryVisibility]);
        historyVisibilityCell.checkBox.alpha = historyVisibilityCell.userInteractionEnabled ? 1.0f : 0.5f;
        
        cell = historyVisibilityCell;
    }
    else if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
    {
        if (indexPath.row == roomAddressNewAliasIndex)
        {
            MXKTableViewCellWithLabelAndTextField *addAddressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsNewAddressCellViewIdentifier forIndexPath:indexPath];
            
            // Retrieve the current edited value if any
            NSString *currentValue = (addAddressTextField ? addAddressTextField.text : nil);
            
            addAddressCell.mxkLabelLeadingConstraint.constant = 0;
            addAddressCell.mxkTextFieldLeadingConstraint.constant = addAddressCell.separatorInset.left;
            addAddressCell.mxkTextFieldTrailingConstraint.constant = 15;
            
            addAddressCell.mxkLabel.text = nil;
            
            addAddressCell.accessoryType = UITableViewCellAccessoryNone;
            addAddressCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
            
            addAddressTextField = addAddressCell.mxkTextField;
            addAddressTextField.placeholder = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_details_new_address_placeholder", @"Vector", nil), self.mainSession.matrixRestClient.homeserverSuffix];
            addAddressTextField.userInteractionEnabled = YES;
            addAddressTextField.text = currentValue;
            addAddressTextField.textColor = kVectorTextColorGray;
            
            addAddressTextField.tintColor = kVectorColorGreen;
            addAddressTextField.font = [UIFont systemFontOfSize:17];
            addAddressTextField.borderStyle = UITextBorderStyleNone;
            addAddressTextField.textAlignment = NSTextAlignmentLeft;
            
            addAddressTextField.autocorrectionType = UITextAutocorrectionTypeNo;
            addAddressTextField.spellCheckingType = UITextSpellCheckingTypeNo;
            addAddressTextField.delegate = self;
            
            cell = addAddressCell;
        }
        else
        {
            UITableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAddressCellViewIdentifier forIndexPath:indexPath];
            
            addressCell.textLabel.font = [UIFont systemFontOfSize:16];
            addressCell.textLabel.textColor = kVectorTextColorBlack;
            addressCell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
            addressCell.accessoryView = nil;
            addressCell.accessoryType = UITableViewCellAccessoryNone;
            addressCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            // Check whether there is no local addresses
            if (localAddressesCount == 0 && indexPath.row == 0)
            {
                addressCell.textLabel.text = NSLocalizedStringFromTable(@"room_details_no_local_addresses", @"Vector", nil);
            }
            else
            {
                NSInteger row = (localAddressesCount ? indexPath.row : indexPath.row - 1);
                
                if (row < roomAddresses.count)
                {
                    NSString *alias = roomAddresses[row];
                    NSString *canonicalAlias;
                    
                    if ([updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey])
                    {
                        canonicalAlias = [updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey];
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
                            addressCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_alias_icon"]];
                        }
                    }
                }
            }
            
            cell = addressCell;
        }
    }
    else if (indexPath.section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
    {
        UITableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAddressCellViewIdentifier forIndexPath:indexPath];

        addressCell.textLabel.font = [UIFont systemFontOfSize:16];
        addressCell.textLabel.textColor = kVectorTextColorBlack;
        addressCell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        addressCell.accessoryView = nil;
        addressCell.accessoryType = UITableViewCellAccessoryNone;
        addressCell.selectionStyle = UITableViewCellSelectionStyleNone;

        addressCell.textLabel.text = bannedMembers[indexPath.row].userId;

        cell = addressCell;
    }
    else if (indexPath.section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX)
    {
        if (indexPath.row == 0)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAdvancedCellViewIdentifier];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kRoomSettingsAdvancedCellViewIdentifier];
            }

            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.text = NSLocalizedStringFromTable(@"room_details_advanced_room_id", @"Vector", nil);
            cell.textLabel.textColor = kVectorTextColorBlack;

            cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
            cell.detailTextLabel.text = mxRoomState.roomId;
            cell.detailTextLabel.textColor = kVectorTextColorGray;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else if (mxRoom.state.isEncrypted)
        {
            if (indexPath.row == 1)
            {
                MXKTableViewCellWithLabelAndSwitch *roomBlacklistUnverifiedDevicesCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];

                roomBlacklistUnverifiedDevicesCell.mxkLabelLeadingConstraint.constant = roomBlacklistUnverifiedDevicesCell.separatorInset.left;
                roomBlacklistUnverifiedDevicesCell.mxkSwitchTrailingConstraint.constant = 15;

                [roomBlacklistUnverifiedDevicesCell.mxkSwitch addTarget:self action:@selector(onSwitchUpdate:) forControlEvents:UIControlEventValueChanged];
                roomBlacklistUnverifiedDevicesCell.mxkSwitch.onTintColor = kVectorColorGreen;

                roomBlacklistUnverifiedDevicesCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_advanced_e2e_encryption_blacklist_unverified_devices", @"Vector", nil);
                roomBlacklistUnverifiedDevicesCell.mxkLabel.textColor = kVectorTextColorBlack;

                roomEncryptionBlacklistUnverifiedDevicesSwitch = roomBlacklistUnverifiedDevicesCell.mxkSwitch;

                // Workaround to avoid mixing between switches
                // TODO: this is a design issue with switch within UITableViewCell that must fix everywhere
                if (directoryVisibilitySwitch == roomEncryptionBlacklistUnverifiedDevicesSwitch)
                {
                    directoryVisibilitySwitch = nil;
                }
                else if (roomNotifSwitch == roomEncryptionBlacklistUnverifiedDevicesSwitch)
                {
                    roomNotifSwitch = nil;
                }
                else if (roomEncryptionSwitch == roomEncryptionBlacklistUnverifiedDevicesSwitch)
                {
                    roomEncryptionSwitch = nil;
                }

                // For the switch value, use first the changed value made by the user, then the value used by the crypto
                BOOL blacklistUnverifiedDevices;
                if ([updatedItemsDict objectForKey:kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey])
                {
                    blacklistUnverifiedDevices = [((NSNumber*)updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey]) boolValue];
                }
                else
                {
                    blacklistUnverifiedDevices = [mxRoom.mxSession.crypto isBlacklistUnverifiedDevicesInRoom:mxRoom.roomId];
                }

                roomEncryptionBlacklistUnverifiedDevicesSwitch.on = blacklistUnverifiedDevices;

                cell = roomBlacklistUnverifiedDevicesCell;
            }
            else if (indexPath.row == 2)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
                if (!cell)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
                }

                cell.textLabel.font = [UIFont systemFontOfSize:17];
                cell.textLabel.numberOfLines = 0;
                cell.textLabel.text = NSLocalizedStringFromTable(@"room_details_advanced_e2e_encryption_enabled", @"Vector", nil);
                cell.textLabel.textColor = kVectorTextColorBlack;

                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
        else
        {
            // Check user's power level to know whether the user is allowed to turn on the encryption mode
            MXRoomPowerLevels *powerLevels = [mxRoom.state powerLevels];
            NSInteger oneSelfPowerLevel = [powerLevels powerLevelOfUserWithUserID:self.mainSession.myUser.userId];

            if (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomEncryption])
            {
                MXKTableViewCellWithLabelAndSwitch *roomEncryptionCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];

                roomEncryptionCell.mxkLabelLeadingConstraint.constant = roomEncryptionCell.separatorInset.left;
                roomEncryptionCell.mxkSwitchTrailingConstraint.constant = 15;

                [roomEncryptionCell.mxkSwitch addTarget:self action:@selector(onSwitchUpdate:) forControlEvents:UIControlEventValueChanged];
                roomEncryptionCell.mxkSwitch.onTintColor = kVectorColorGreen;

                roomEncryptionCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_advanced_enable_e2e_encryption", @"Vector", nil);
                roomEncryptionCell.mxkLabel.textColor = kVectorTextColorBlack;

                roomEncryptionSwitch = roomEncryptionCell.mxkSwitch;

                // Workaround to avoid mixing between switches
                // TODO: this is a design issue with switch within UITableViewCell that must fix everywhere
                if (directoryVisibilitySwitch == roomEncryptionSwitch)
                {
                    directoryVisibilitySwitch = nil;
                }
                else if (roomNotifSwitch == roomEncryptionSwitch)
                {
                    roomNotifSwitch = nil;
                }
                else if (roomEncryptionBlacklistUnverifiedDevicesSwitch == roomEncryptionSwitch)
                {
                    roomEncryptionBlacklistUnverifiedDevicesSwitch = nil;
                }

                roomEncryptionSwitch.on = ([updatedItemsDict objectForKey:kRoomSettingsEncryptionKey] != nil);

                cell = roomEncryptionCell;
            }
            else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
                if (!cell)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kRoomSettingsAdvancedE2eEnabledCellViewIdentifier];
                }

                cell.textLabel.font = [UIFont systemFontOfSize:17];
                cell.textLabel.numberOfLines = 0;
                cell.textLabel.text = NSLocalizedStringFromTable(@"room_details_advanced_e2e_encryption_disabled", @"Vector", nil);
                cell.textLabel.textColor = kVectorTextColorBlack;

                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
        }
    }

    // Sanity check
    if (!cell)
    {
        NSLog(@"[RoomSettingsViewController] cellForRowAtIndexPath: invalid indexPath");
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX && indexPath.row != roomAddressNewAliasIndex)
    {
        if (localAddressesCount != 0 || indexPath.row != 0)
        {
            // The user is allowed to remove a room alias only if he is allowed to create alias too.
            return (roomAddressNewAliasIndex != -1);
        }
    }
    return NO;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // iOS8 requires this method to enable editing (see editActionsForRowAtIndexPath).
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        [self dismissFirstResponder];
        
        if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
        {
            if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
            {
                [self onRoomAvatarTap:nil];
            }
            else if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC)
            {
                if (topicTextView.editable)
                {
                    [self editRoomTopic];
                }
            }
        }
        else if (indexPath.section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
        {
            BOOL isUpdated = NO;
            
            if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_INVITED_ONLY)
            {
                // Ignore the selection if the option is already enabled
                if (! accessInvitedOnlyTickCell.isEnabled)
                {
                    // Enable this option
                    accessInvitedOnlyTickCell.enabled = YES;
                    // Disable other options
                    accessAnyoneApartGuestTickCell.enabled = NO;
                    accessAnyoneTickCell.enabled = NO;
                    
                    // Check the actual option
                    if ([mxRoomState.joinRule isEqualToString:kMXRoomJoinRuleInvite])
                    {
                        // No change on room access
                        [updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        [updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                    }
                    else
                    {
                        [updatedItemsDict setObject:kMXRoomJoinRuleInvite forKey:kRoomSettingsJoinRuleKey];
                        
                        // Update guest access to allow guest on invitation.
                        // Note: if guest_access is "forbidden" here, guests cannot join this room even if explicitly invited.
                        if ([mxRoomState.guestAccess isEqualToString:kMXRoomGuestAccessCanJoin])
                        {
                            [updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                        }
                        else
                        {
                            [updatedItemsDict setObject:kMXRoomGuestAccessCanJoin forKey:kRoomSettingsGuestAccessKey];
                        }
                    }
                    
                    isUpdated = YES;
                }
            }
            else if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE_APART_FROM_GUEST)
            {
                // Ignore the selection if the option is already enabled
                if (! accessAnyoneApartGuestTickCell.isEnabled)
                {
                    // Enable this option
                    accessAnyoneApartGuestTickCell.enabled = YES;
                    // Disable other options
                    accessInvitedOnlyTickCell.enabled = NO;
                    accessAnyoneTickCell.enabled = NO;
                    
                    // Check the actual option
                    if ([mxRoomState.joinRule isEqualToString:kMXRoomJoinRulePublic] && [mxRoomState.guestAccess isEqualToString:kMXRoomGuestAccessForbidden])
                    {
                        // No change on room access
                        [updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        [updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                    }
                    else
                    {
                        if ([mxRoomState.joinRule isEqualToString:kMXRoomJoinRulePublic])
                        {
                            [updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        }
                        else
                        {
                            [updatedItemsDict setObject:kMXRoomJoinRulePublic forKey:kRoomSettingsJoinRuleKey];
                        }
                        
                        if ([mxRoomState.guestAccess isEqualToString:kMXRoomGuestAccessForbidden])
                        {
                            [updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                        }
                        else
                        {
                            [updatedItemsDict setObject:kMXRoomGuestAccessForbidden forKey:kRoomSettingsGuestAccessKey];
                        }
                    }
                    
                    isUpdated = YES;
                }
            }
            else if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE)
            {
                // Ignore the selection if the option is already enabled
                if (! accessAnyoneTickCell.isEnabled)
                {
                    // Enable this option
                    accessAnyoneTickCell.enabled = YES;
                    // Disable other options
                    accessInvitedOnlyTickCell.enabled = NO;
                    accessAnyoneApartGuestTickCell.enabled = NO;
                    
                    // Check the actual option
                    if ([mxRoomState.joinRule isEqualToString:kMXRoomJoinRulePublic] && [mxRoomState.guestAccess isEqualToString:kMXRoomGuestAccessCanJoin])
                    {
                        // No change on room access
                        [updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        [updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                    }
                    else
                    {
                        if ([mxRoomState.joinRule isEqualToString:kMXRoomJoinRulePublic])
                        {
                            [updatedItemsDict removeObjectForKey:kRoomSettingsJoinRuleKey];
                        }
                        else
                        {
                            [updatedItemsDict setObject:kMXRoomJoinRulePublic forKey:kRoomSettingsJoinRuleKey];
                        }
                        
                        if ([mxRoomState.guestAccess isEqualToString:kMXRoomGuestAccessCanJoin])
                        {
                            [updatedItemsDict removeObjectForKey:kRoomSettingsGuestAccessKey];
                        }
                        else
                        {
                            [updatedItemsDict setObject:kMXRoomGuestAccessCanJoin forKey:kRoomSettingsGuestAccessKey];
                        }
                    }
                    
                    isUpdated = YES;
                }
            }
            else if (indexPath.row == missingAddressWarningIndex)
            {
                // Scroll to room addresses section
                NSIndexPath *addressIndexPath = [NSIndexPath indexPathForRow:0 inSection:ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX];
                [tableView scrollToRowAtIndexPath:addressIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
            
            if (isUpdated)
            {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX];
                [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                
                [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
            }
        }
        else if (indexPath.section == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX)
        {
            // Ignore the selection if the option is already enabled
            TableViewCellWithCheckBoxAndLabel *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (! selectedCell.isEnabled)
            {
                MXRoomHistoryVisibility historyVisibility;
                
                if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE)
                {
                    historyVisibility = kMXRoomHistoryVisibilityWorldReadable;
                }
                else if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY)
                {
                    historyVisibility = kMXRoomHistoryVisibilityShared;
                }
                else if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED)
                {
                    historyVisibility = kMXRoomHistoryVisibilityInvited;
                }
                else if (indexPath.row == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED)
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
        else if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
        {
            if (indexPath.row == roomAddressNewAliasIndex)
            {
                NSString *roomAlias = addAddressTextField.text;
                if (!roomAlias.length || [self addRoomAlias:roomAlias])
                {
                    // Reset the input field
                    addAddressTextField.text = nil;
                }
            }
            else if (localAddressesCount != 0 || indexPath.row != 0)
            {
                // Prompt user on selected room alias
                UITableViewCell *addressCell = [tableView cellForRowAtIndexPath:indexPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self promptUserOnSelectedRoomAlias:addressCell.textLabel];
                    
                });
            }
        }
        else if (indexPath.section == ROOM_SETTINGS_BANNED_USERS_SECTION_INDEX)
        {
            // Show the RoomMemberDetailsViewController on this member so that 
            // if the user has enough power level, he will be able to unban him
            RoomMemberDetailsViewController *roomMemberDetailsViewController = [RoomMemberDetailsViewController roomMemberDetailsViewController];
            [roomMemberDetailsViewController displayRoomMember:bannedMembers[indexPath.row] withMatrixRoom:mxRoom];
            roomMemberDetailsViewController.delegate = self;
            roomMemberDetailsViewController.enableVoipCall = NO;

            [self.parentViewController.navigationController pushViewController:roomMemberDetailsViewController animated:NO];
        }
        else if (indexPath.section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX && indexPath.row == 0)
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

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // Add the swipe to delete only on addresses section
    if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX && indexPath.row != roomAddressNewAliasIndex)
    {
        if (localAddressesCount != 0 || indexPath.row != 0)
        {
            actions = [[NSMutableArray alloc] init];
            
            // Patch: Force the width of the button by adding whitespace characters into the title string.
            UITableViewRowAction *removeAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"   "  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
                
                [self removeAddressAtIndexPath:indexPath];
                
            }];
            
            removeAction.backgroundColor = [MXKTools convertImageToPatternColor:@"remove_icon" backgroundColor:kVectorColorLightGrey patternSize:CGSizeMake(44, 44) resourceSize:CGSizeMake(25, 24)];
            [actions insertObject:removeAction atIndex:0];
        }
    }
    
    return actions;
}

#pragma mark -

- (void)shouldChangeHistoryVisibility:(MXRoomHistoryVisibility)historyVisibility
{
    // Prompt the user before applying the change on room history visibility
    [currentAlert dismiss:NO];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_details_history_section_prompt_title", @"Vector", nil) message:NSLocalizedStringFromTable(@"room_details_history_section_prompt_msg", @"Vector", nil) style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
        }
        
    }];
    
    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            [strongSelf changeHistoryVisibility:historyVisibility];
        }
        
    }];
    
    currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCChangeHistoryVisibilityAlert";
    [currentAlert showInViewController:self];
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
            [updatedItemsDict setObject:historyVisibility forKey:kRoomSettingsHistoryVisibilityKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

- (void)shouldRemoveCanonicalAlias:(void (^)())didRemoveCanonicalAlias
{
    // Prompt the user before removing the current main address
    [currentAlert dismiss:NO];
    
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_details_addresses_disable_main_address_prompt_title", @"Vector", nil) message:NSLocalizedStringFromTable(@"room_details_addresses_disable_main_address_prompt_msg", @"Vector", nil) style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
        }
        
    }];
    
    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            // Remove the canonical address
            if (strongSelf->mxRoomState.canonicalAlias.length)
            {
                [strongSelf->updatedItemsDict setObject:@"" forKey:kRoomSettingsCanonicalAliasKey];
            }
            else
            {
                [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
            }
            
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX];
            [strongSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            
            [strongSelf getNavigationItem].rightBarButtonItem.enabled = (strongSelf->updatedItemsDict.count != 0);
            
            if (didRemoveCanonicalAlias)
            {
                didRemoveCanonicalAlias();
            }
        }
        
    }];
    
    currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCRemoveCanonicalAliasAlert";
    [currentAlert showInViewController:self];
}

#pragma mark - MediaPickerViewController Delegate

- (void)dismissMediaPicker
{
    if (mediaPicker)
    {
        [mediaPicker withdrawViewControllerAnimated:YES completion:nil];
        mediaPicker = nil;
    }
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectImage:(UIImage*)image withURL:(NSURL *)imageURL
{
    [self dismissMediaPicker];
    
    if (image)
    {
        [self getNavigationItem].rightBarButtonItem.enabled = YES;
        
        [updatedItemsDict setObject:image forKey:kRoomSettingsAvatarKey];
        
        [self refreshRoomSettings];
    }
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL
{
    // this method should not be called
    [self dismissMediaPicker];
}

#pragma mark - MXKRoomMemberDetailsViewControllerDelegate

- (void)roomMemberDetailsViewController:(MXKRoomMemberDetailsViewController *)roomMemberDetailsViewController startChatWithMemberId:(NSString *)matrixId completion:(void (^)(void))completion
{
    [[AppDelegate theDelegate] createDirectChatWithUserId:matrixId completion:completion];
}

#pragma mark - actions

- (void)onLeave:(id)sender
{
    // Prompt user before leaving the room
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];
    
    
    currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_participants_leave_prompt_title", @"Vector", nil)
                                           message:NSLocalizedStringFromTable(@"room_participants_leave_prompt_msg", @"Vector", nil)
                                             style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                style:MXKAlertActionStyleCancel
                                                              handler:^(MXKAlert *alert) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                      strongSelf->currentAlert = nil;
                                                                  }
                                                              }];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"leave", @"Vector", nil)
                               style:MXKAlertActionStyleDefault
                             handler:^(MXKAlert *alert) {
                                 
                                 if (weakSelf)
                                 {
                                     __strong __typeof(weakSelf)strongSelf = weakSelf;
                                     strongSelf->currentAlert = nil;
                                     
                                     [strongSelf startActivityIndicator];
                                     [strongSelf->mxRoom leave:^{
                                         
                                         [strongSelf withdrawViewControllerAnimated:YES completion:nil];
                                         
                                     } failure:^(NSError *error) {
                                         
                                         [strongSelf stopActivityIndicator];
                                         
                                         NSLog(@"[RoomSettingsViewController] Leave room failed");
                                         // Alert user
                                         [[AppDelegate theDelegate] showErrorAsAlert:error];
                                         
                                     }];
                                 }
                                 
                             }];
    
    currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCLeaveAlert";
    [currentAlert showInViewController:self];
}

- (void)onRoomAvatarTap:(UITapGestureRecognizer *)recognizer
{
    mediaPicker = [MediaPickerViewController mediaPickerViewController];
    mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaPicker.delegate = self;
    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:mediaPicker animated:NO];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)onSwitchUpdate:(UISwitch*)theSwitch
{
    if (theSwitch == roomNotifSwitch)
    {
        if (roomNotifSwitch.on == (mxRoom.isMute || mxRoom.isMentionsOnly))
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
        }
        else
        {
            [updatedItemsDict setObject:[NSNumber numberWithBool:roomNotifSwitch.on] forKey:kRoomSettingsMuteNotifKey];
        }
    }
    else if (theSwitch == directoryVisibilitySwitch)
    {
        MXRoomDirectoryVisibility visibility = directoryVisibilitySwitch.on ? kMXRoomDirectoryVisibilityPublic : kMXRoomDirectoryVisibilityPrivate;

        // Check whether the actual settings has been retrieved
        if (actualDirectoryVisibility)
        {
            if ([visibility isEqualToString:actualDirectoryVisibility])
            {
                [updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
            }
            else
            {
                [updatedItemsDict setObject:visibility forKey:kRoomSettingsDirectoryKey];
            }
        }
        else
        {
            [updatedItemsDict setObject:visibility forKey:kRoomSettingsDirectoryKey];
        }
    }
    else if (theSwitch == roomEncryptionSwitch)
    {
        if (roomEncryptionSwitch.on)
        {
            // Prompt here user before turning on the data encryption
            __weak typeof(self) weakSelf = self;
            
            [currentAlert dismiss:NO];
            
            currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_details_advanced_e2e_encryption_prompt_title", @"Vector", nil)
                                                   message:NSLocalizedStringFromTable(@"room_details_advanced_e2e_encryption_prompt_message", @"Vector", nil)
                                                     style:MXKAlertStyleAlert];
            
            currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                        style:MXKAlertActionStyleDefault
                                                                      handler:^(MXKAlert *alert) {
                                                                          
                                                                          if (weakSelf)
                                                                          {
                                                                              __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                              strongSelf->currentAlert = nil;
                                                                          }
                                                                          
                                                                          // Reset switch change
                                                                          theSwitch.on = NO;
                                                                      }];
            
            [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                       style:MXKAlertActionStyleDefault
                                     handler:^(MXKAlert *alert) {
                                         
                                         if (weakSelf)
                                         {
                                             __strong __typeof(weakSelf)strongSelf = weakSelf;
                                             strongSelf->currentAlert = nil;
                                             
                                             [strongSelf->updatedItemsDict setObject:@(YES) forKey:kRoomSettingsEncryptionKey];
                                             
                                             [strongSelf getNavigationItem].rightBarButtonItem.enabled = strongSelf->updatedItemsDict.count;
                                         }
                                     }];
            
            currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCEnableEncryptionAlert";
            [currentAlert showInViewController:self];
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsEncryptionKey];
        }
    }
    else if (theSwitch == roomEncryptionBlacklistUnverifiedDevicesSwitch)
    {
        if ([mxRoom.mxSession.crypto isBlacklistUnverifiedDevicesInRoom:mxRoom.roomId] != roomEncryptionBlacklistUnverifiedDevicesSwitch.on)
        {
            updatedItemsDict[kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey] = @(roomEncryptionBlacklistUnverifiedDevicesSwitch.on);
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsEncryptionBlacklistUnverifiedDevicesKey];
        }
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
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
        [updatedItemsDict setObject:alias forKey:kRoomSettingsCanonicalAliasKey];
    }
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
}

- (void)removeAddressAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = (localAddressesCount ? indexPath.row : indexPath.row - 1);
    
    if (row < roomAddresses.count)
    {
        NSString *alias = roomAddresses[indexPath.row];
        [self removeRoomAlias:alias];
    }
}

- (void)removeRoomAlias:(NSString*)roomAlias
{
    NSString *canonicalAlias;
    
    if ([updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey])
    {
        canonicalAlias = [updatedItemsDict objectForKey:kRoomSettingsCanonicalAliasKey];
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
        NSMutableArray<NSString *> *addedAlias = [updatedItemsDict objectForKey:kRoomSettingsNewAliasesKey];
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
            NSMutableArray<NSString *> *removedAlias = [updatedItemsDict objectForKey:kRoomSettingsRemovedAliasesKey];
            if (!removedAlias)
            {
                removedAlias = [NSMutableArray array];
                [updatedItemsDict setObject:removedAlias forKey:kRoomSettingsRemovedAliasesKey];
            }
            
            [removedAlias addObject:roomAlias];
        }
        
        NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet indexSet];
        
        if (roomAddresses.count <= 1)
        {
            // The user remove here all the room addresses, reload the room access section to display potential warning message
            [mutableIndexSet addIndex:ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX];
        }
        
        [mutableIndexSet addIndex:ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX];
        [self.tableView reloadSections:mutableIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

- (BOOL)addRoomAlias:(NSString*)roomAlias
{
    // Check whether the provided alias is valid
    if ([MXTools isMatrixRoomAlias:roomAlias])
    {
        // Check whether this alias has just been deleted
        NSMutableArray<NSString *> *removedAlias = [updatedItemsDict objectForKey:kRoomSettingsRemovedAliasesKey];
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
            NSMutableArray<NSString *> *addedAlias = [updatedItemsDict objectForKey:kRoomSettingsNewAliasesKey];
            if (!addedAlias)
            {
                addedAlias = [NSMutableArray array];
                [updatedItemsDict setObject:addedAlias forKey:kRoomSettingsNewAliasesKey];
            }
            
            [addedAlias addObject:roomAlias];
        }
        
        NSMutableIndexSet *mutableIndexSet = [NSMutableIndexSet indexSet];
        
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
                [updatedItemsDict setObject:roomAlias forKey:kRoomSettingsCanonicalAliasKey];
            }
            
            if (missingAddressWarningIndex != -1)
            {
                // Reload room access section to remove warning message
                [mutableIndexSet addIndex:ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX];
            }
        }
        
        [mutableIndexSet addIndex:ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX];
        [self.tableView reloadSections:mutableIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
        
        return YES;
    }
    
    // Prompt here user for invalid alias
    __weak typeof(self) weakSelf = self;
    
    [currentAlert dismiss:NO];
    
    NSString *alertMsg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_details_addresses_invalid_address_prompt_msg", @"Vector", nil), roomAlias];
    
    currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_details_addresses_invalid_address_prompt_title", @"Vector", nil)
                                           message:alertMsg
                                             style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                style:MXKAlertActionStyleDefault
                                                              handler:^(MXKAlert *alert) {
                                                                  
                                                                  if (weakSelf)
                                                                  {
                                                                      __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                      strongSelf->currentAlert = nil;
                                                                  }
                                                              }];
    
    currentAlert.mxkAccessibilityIdentifier = @"RoomSettingsVCAddAliasAlert";
    [currentAlert showInViewController:self];
    
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
            NSString *updatedRoomTag = [updatedItemsDict objectForKey:kRoomSettingsTagKey];
            
            // Check the actual tag on mxRoom
            if (mxRoom.accountData.tags[tappedRoomTag])
            {
                // The actual tag must be updated, check whether another tag is already set
                if (!updatedRoomTag)
                {
                    [updatedItemsDict setObject:@"" forKey:kRoomSettingsTagKey];
                }
            }
            else if (updatedRoomTag && [updatedRoomTag isEqualToString:tappedRoomTag])
            {
                // Cancel the updated tag, but take into account the cancellation of another tag when 'tappedRoomTag' was selected.
                if (mxRoom.accountData.tags.count)
                {
                    [updatedItemsDict setObject:@"" forKey:kRoomSettingsTagKey];
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
                [updatedItemsDict setObject:tappedRoomTag forKey:kRoomSettingsTagKey];
            }
            
            // Select the tapped tag
            [roomTagCell setCheckBoxValue:YES atIndex:index];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

@end


