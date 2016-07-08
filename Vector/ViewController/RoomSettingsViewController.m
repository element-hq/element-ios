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

#import "MXRoom+Vector.h"

#import "AppDelegate.h"

#define ROOM_SETTINGS_MAIN_SECTION_INDEX               0
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX        1
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX 2
#define ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX     3
#define ROOM_SETTINGS_ADVANCED_SECTION_INDEX           4
#define ROOM_SETTINGS_SECTION_COUNT                    5

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
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_DIRECTORY_TOGGLE        3
#define ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_COUNT                   4

#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_ANYONE                     0
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY               1
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_INVITED 2
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_MEMBERS_ONLY_SINCE_JOINED  3
#define ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_COUNT                      4

#define ROOM_TOPIC_CELL_HEIGHT 124

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
    TableViewCellWithCheckBoxAndLabel *accessInvitedOnlyTickCell;
    TableViewCellWithCheckBoxAndLabel *accessAnyoneApartGuestTickCell;
    TableViewCellWithCheckBoxAndLabel *accessAnyoneTickCell;
    UISwitch *directoryVisibilitySwitch;
    MXRoomDirectoryVisibility actualDirectoryVisibility;
    
    // History Visibility items
    NSMutableDictionary<MXRoomHistoryVisibility, TableViewCellWithCheckBoxAndLabel*> *historyVisibilityTickCells;
    
    // Room aliases
    NSMutableArray<NSString *> *roomAddresses;
    NSUInteger localAddressesCount;
    
    // The potential image loader
    MXKMediaLoader *uploader;
    
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
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id appDelegateDidTapStatusBarNotificationObserver;
}
@end

@implementation RoomSettingsViewController

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
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    updatedItemsDict = [[NSMutableDictionary alloc] init];
    historyVisibilityTickCells = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndMXKImageView.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithLabelAndLargeTextView.class forCellReuseIdentifier:[TableViewCellWithLabelAndLargeTextView defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithButton.class forCellReuseIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithCheckBoxes.class forCellReuseIdentifier:[TableViewCellWithCheckBoxes defaultReuseIdentifier]];
    [self.tableView registerClass:TableViewCellWithCheckBoxAndLabel.class forCellReuseIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCell.class forCellReuseIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    
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
    
    if (appDelegateDidTapStatusBarNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:appDelegateDidTapStatusBarNotificationObserver];
        appDelegateDidTapStatusBarNotificationObserver = nil;
    }
    
    updatedItemsDict = nil;
    historyVisibilityTickCells = nil;
    
    roomAddresses = nil;
    
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
    // Check whether a text input is currently edited
    BOOL isNameEdited = nameTextField ? nameTextField.isFirstResponder : NO;
    BOOL isTopicEdited = topicTextView ? topicTextView.isFirstResponder : NO;
    
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
}

- (void)startActivityIndicator
{
    // Lock user interaction
    self.tableView.userInteractionEnabled = NO;
    
    // Check whether the current view controller is displayed inside a segmented view controller in order to run the right activity view
    if (self.parentViewController && [self.parentViewController isKindOfClass:SegmentedViewController.class])
    {
        [((SegmentedViewController*)self.parentViewController) startActivityIndicator];
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
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"room_details_with_updates", @"Vector", nil) style:MXKAlertStyleAlert];
    
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
    
    [currentAlert showInViewController:self];
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
        
        // Check whether the topic has been actually changed
        if ((textView.text || currentTopic) && ([textView.text isEqualToString:currentTopic] == NO))
        {
            [updatedItemsDict setObject:(textView.text ? textView.text : @"") forKey:kRoomSettingsTopicKey];
        }
        else
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsTopicKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

#pragma mark - actions

- (IBAction)onTextFieldUpdate:(UITextField*)textField
{
    if (nameTextField == textField)
    {
        NSString* currentName = mxRoomState.name;
        
        // Check whether the name has been actually changed
        if ((textField.text || currentName) && ([textField.text isEqualToString:currentName] == NO))
        {
            [updatedItemsDict setObject:(textField.text ? textField.text : @"") forKey:kRoomSettingsNameKey];
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
                uploader = [MXKMediaManager prepareUploaderWithMatrixSession:mxRoom.mxSession initialRange:0 andRange:1.0];
                
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
            [mxRoom setMute:roomNotifSwitch.on completion:^{
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    [strongSelf->updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
                    [strongSelf onSave:nil];
                }
                
            }];
            
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
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = NO;
    
    [self stopActivityIndicator];
    
    [self withdrawViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ROOM_SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
    {
        return ROOM_SETTINGS_MAIN_SECTION_ROW_COUNT;
    }
    else if (section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
    {
        return ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_COUNT;
    }
    else if (section == ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_INDEX)
    {
        return ROOM_SETTINGS_HISTORY_VISIBILITY_SECTION_ROW_COUNT;
    }
    else if (section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
    {
        roomAddresses = nil;
        localAddressesCount = 0;
        
        NSArray *removedAliases = [updatedItemsDict objectForKey:kRoomSettingsRemovedAliasesKey];
        
        NSArray *aliases = mxRoomState.aliases;
        if (aliases)
        {
            roomAddresses = [NSMutableArray arrayWithCapacity:aliases.count];
            
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
        
        return (localAddressesCount ? roomAddresses.count : roomAddresses.count + 1);
    }
    else if (section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX)
    {
        return 1;
    }
    
    return 0;
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
    else if (section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX)
    {
        return NSLocalizedStringFromTable(@"room_details_advanced_section", @"Vector", nil);
    }
    
    return nil;
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
            
            UIEdgeInsets separatorInset = roomNotifCell.separatorInset;
            
            roomNotifCell.mxkLabelLeadingConstraint.constant = separatorInset.left;
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
                roomNotifSwitch.on = mxRoom.isMute;
            }
            
            cell = roomNotifCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
        {
            MXKTableViewCellWithLabelAndMXKImageView *roomPhotoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            roomPhotoCell.mxkLabelLeadingConstraint.constant = 15;
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
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndLargeTextView defaultReuseIdentifier] forIndexPath:indexPath];
            
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
            MXKTableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier] forIndexPath:indexPath];
            
            UIEdgeInsets separatorInset = roomNameCell.separatorInset;
            
            roomNameCell.mxkLabelLeadingConstraint.constant = separatorInset.left;
            roomNameCell.mxkTextFieldTrailingConstraint.constant = 15;
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_room_name", @"Vector", nil);
            roomNameCell.mxkLabel.textColor = kVectorTextColorBlack;
            
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            
            nameTextField = roomNameCell.mxkTextField;
            
            nameTextField.tintColor = kVectorColorGreen;
            nameTextField.font = [UIFont systemFontOfSize:17];
            nameTextField.borderStyle = UITextBorderStyleNone;
            nameTextField.textAlignment = NSTextAlignmentRight;
            
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
            leaveCell.mxkButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            
            [leaveCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [leaveCell.mxkButton addTarget:self action:@selector(onLeave:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = leaveCell;
        }
    }
    else if (indexPath.section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
    {
        if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_DIRECTORY_TOGGLE)
        {
            MXKTableViewCellWithLabelAndSwitch *directoryToggleCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
            
            UIEdgeInsets separatorInset = directoryToggleCell.separatorInset;
            
            directoryToggleCell.mxkLabelLeadingConstraint.constant = separatorInset.left;
            directoryToggleCell.mxkSwitchTrailingConstraint.constant = 15;
            
            directoryToggleCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_access_section_directory_toggle", @"Vector", nil);
            directoryToggleCell.mxkLabel.textColor = kVectorTextColorBlack;
            
            directoryVisibilitySwitch = directoryToggleCell.mxkSwitch;
            
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
                
                // Trigger a request to check the actual directory visibility
                [self startActivityIndicator];
                
                __weak typeof(self) weakSelf = self;
                
                pendingOperation = [mxRoom directoryVisibility:^(MXRoomDirectoryVisibility directoryVisibility) {
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf->pendingOperation = nil;
                        
                        strongSelf->actualDirectoryVisibility = directoryVisibility;
                        
                        // Check a potential change before update
                        if ([updatedItemsDict objectForKey:kRoomSettingsDirectoryKey])
                        {
                            if (directoryVisibilitySwitch.on == ([directoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic]))
                            {
                                // The requested change corresponds to the actual settings
                                [updatedItemsDict removeObjectForKey:kRoomSettingsDirectoryKey];
                                
                                [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
                            }
                        }
                        else
                        {
                            directoryVisibilitySwitch.on = ([directoryVisibility isEqualToString:kMXRoomDirectoryVisibilityPublic]);
                        }
                        
                        [strongSelf stopActivityIndicator];
                    }
                    
                } failure:^(NSError *error) {
                    
                    NSLog(@"[RoomSettingsViewController] request to get directory visibility failed");
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        strongSelf->pendingOperation = nil;
                        
                        [strongSelf stopActivityIndicator];
                    }
                }];
            }
            
            // Check whether the user can change this option
            directoryVisibilitySwitch.enabled = (oneSelfPowerLevel >= powerLevels.stateDefault);
            
            cell = directoryToggleCell;
        }
        else
        {
            TableViewCellWithCheckBoxAndLabel *roomAccessCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithCheckBoxAndLabel defaultReuseIdentifier] forIndexPath:indexPath];
            
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
                roomAccessCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
                roomAccessCell.label.text = NSLocalizedStringFromTable(@"room_details_access_section_invited_only", @"Vector", nil);
                
                roomAccessCell.enabled = ([joinRule isEqualToString:kMXRoomJoinRuleInvite]);
                
                accessInvitedOnlyTickCell = roomAccessCell;
            }
            else if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE_APART_FROM_GUEST)
            {
                roomAccessCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
                roomAccessCell.label.text = NSLocalizedStringFromTable(@"room_details_access_section_anyone_apart_from_guest", @"Vector", nil);
                
                roomAccessCell.enabled = ([joinRule isEqualToString:kMXRoomJoinRulePublic] && [guestAccess isEqualToString:kMXRoomGuestAccessForbidden]);
                
                accessAnyoneApartGuestTickCell = roomAccessCell;
            }
            else if (indexPath.row == ROOM_SETTINGS_ROOM_ACCESS_SECTION_ROW_ANYONE)
            {
                roomAccessCell.label.lineBreakMode = NSLineBreakByTruncatingMiddle;
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
        MXKTableViewCell *addressCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
        
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
                NSString *alias = roomAddresses[indexPath.row];
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
    else if (indexPath.section == ROOM_SETTINGS_ADVANCED_SECTION_INDEX)
    {
        MXKTableViewCell *roomIdCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
        
        roomIdCell.textLabel.font = [UIFont systemFontOfSize:16];
        roomIdCell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_details_advanced_room_id", @"Vector", nil), mxRoomState.roomId];
        roomIdCell.textLabel.textColor = kVectorTextColorBlack;
        roomIdCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell = roomIdCell;
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
    if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
    {
        if (localAddressesCount != 0 || indexPath.row != 0)
        {
            return YES;
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
        }
        else if (indexPath.section == ROOM_SETTINGS_ROOM_ACCESS_SECTION_INDEX)
        {
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
                }
            }
            
            [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
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
        else if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX && (localAddressesCount != 0 || indexPath.row != 0))
        {
            NSInteger row = (localAddressesCount ? indexPath.row : indexPath.row - 1);
            
            if (row < roomAddresses.count)
            {
                NSString *alias = roomAddresses[row];
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
                
                if (canonicalAlias)
                {
                    if ([alias isEqualToString:canonicalAlias])
                    {
                        // Prompt user before removing the current main address
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self shouldRemoveCanonicalAlias:nil];
                        });
                        
                    }
                    else
                    {
                        // Update the current canonical address
                        if ([alias isEqualToString:currentCanonicalAlias])
                        {
                            [updatedItemsDict removeObjectForKey:kRoomSettingsCanonicalAliasKey];
                        }
                        else
                        {
                            [updatedItemsDict setObject:alias forKey:kRoomSettingsCanonicalAliasKey];
                        }
                        
                        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX, 1)];
                        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                        
                        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
                    }
                }
            }
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* actions;
    
    // Add the swipe to delete only on addresses section
    if (indexPath.section == ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX)
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
            [strongSelf->updatedItemsDict setObject:@"" forKey:kRoomSettingsCanonicalAliasKey];
            
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX, 1)];
            [strongSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            
            [strongSelf getNavigationItem].rightBarButtonItem.enabled = (strongSelf->updatedItemsDict.count != 0);
            
            if (didRemoveCanonicalAlias)
            {
                didRemoveCanonicalAlias();
            }
        }
        
    }];
    
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
        if (roomNotifSwitch.on == mxRoom.isMute)
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
        NSMutableArray<NSString *> *removedAlias = [updatedItemsDict objectForKey:kRoomSettingsRemovedAliasesKey];
        if (!removedAlias)
        {
            removedAlias = [NSMutableArray array];
        }
        
        [removedAlias addObject:roomAlias];
        
        [updatedItemsDict setObject:removedAlias forKey:kRoomSettingsRemovedAliasesKey];
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(ROOM_SETTINGS_ROOM_ADDRESSES_SECTION_INDEX, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
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


