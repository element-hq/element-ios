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

#import "TableViewCellWithLabelAndTextField.h"
#import "TableViewCellWithLabelAndLargeTextView.h"
#import "TableViewCellWithLabelAndSwitch.h"

#import "SegmentedViewController.h"

#import "RageShakeManager.h"

#import "VectorDesignValues.h"

#import "AvatarGenerator.h"

#import "MXRoom+Vector.h"

#import "AppDelegate.h"

#define ROOM_SETTINGS_MAIN_SECTION_INDEX 0
#define ROOM_SETTINGS_SECTION_COUNT      1

#define ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO               0
#define ROOM_SETTINGS_MAIN_SECTION_ROW_NAME                1
#define ROOM_SETTINGS_MAIN_SECTION_ROW_TOPIC               2
#define ROOM_SETTINGS_MAIN_SECTION_ROW_PRIV_PUB            3
#define ROOM_SETTINGS_MAIN_SECTION_ROW_MUTE_NOTIFICATIONS  4
#define ROOM_SETTINGS_MAIN_SECTION_ROW_COUNT               5

#define ROOM_TOPIC_CELL_HEIGHT 124

NSString *const kRoomSettingsAvatarKey = @"kRoomSettingsAvatarKey";
NSString *const kRoomSettingsAvatarURLKey = @"kRoomSettingsAvatarURLKey";
NSString *const kRoomSettingsNameKey = @"kRoomSettingsNameKey";
NSString *const kRoomSettingsTopicKey = @"kRoomSettingsTopicKey";
NSString *const kRoomSettingsMuteNotifKey = @"kRoomSettingsMuteNotifKey";

@interface RoomSettingsViewController ()
{
    // The updated user data
    NSMutableDictionary<NSString*, id> *updatedItemsDict;
    
    // The current table items
    UITextField* nameTextField;
    UITextView* topicTextView;
    
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

#pragma mark - actions

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
    [self startActivityIndicator];
    
    // check if there is some updates related to room state
    if (mxRoomState && updatedItemsDict.count)
    {
        __weak typeof(self) weakSelf = self;
        
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
                        
                        [strongSelf onSaveFailed:NSLocalizedStringFromTable(@"room_details_fail_to_update_avatar", @"Vector", nil) withKey:kRoomSettingsAvatarKey];
                        
                    });
                }
                
            }];
            
            return;
        }
        
        if ([updatedItemsDict objectForKey:kRoomSettingsAvatarURLKey])
        { 
            NSString* photoUrl = [updatedItemsDict objectForKey:kRoomSettingsAvatarURLKey];
            
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
                        
                        [strongSelf onSaveFailed:NSLocalizedStringFromTable(@"room_details_fail_to_update_avatar", @"Vector", nil) withKey:kRoomSettingsAvatarURLKey];
                        
                    });
                }
                
            }];
            
            return;
        }
        
        // has a new room name
        if ([updatedItemsDict objectForKey:kRoomSettingsNameKey])
        {
            NSString* newName = [updatedItemsDict objectForKey:kRoomSettingsNameKey];
            
            pendingOperation = [mxRoom setName:newName success:^{
                
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
                        
                        [strongSelf onSaveFailed:NSLocalizedStringFromTable(@"room_details_fail_to_update_room_name", @"Vector", nil) withKey:kRoomSettingsNameKey];
                        
                    });
                }
                
            }];
            
            return;
        }
        
        // has a new room topic
        if ([updatedItemsDict objectForKey:kRoomSettingsTopicKey])
        {
            NSString* newTopic = [updatedItemsDict objectForKey:kRoomSettingsTopicKey];
            
            pendingOperation = [mxRoom setTopic:newTopic success:^{
                
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
                        
                        [strongSelf onSaveFailed:NSLocalizedStringFromTable(@"room_details_fail_to_update_topic", @"Vector", nil) withKey:kRoomSettingsTopicKey];
                        
                    });
                }
                
            }];
            
            return;
        }
    }
    
    if ([updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey])
    {
        [mxRoom setMute:roomNotifSwitch.on completion:nil];
        [updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
        [self onSave:nil];
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    
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
    
    return 0;
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
            TableViewCellWithLabelAndSwitch *roomNotifCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
            
            if (!roomNotifCell)
            {
                roomNotifCell = [[TableViewCellWithLabelAndSwitch alloc] init];
                [roomNotifCell.mxkSwitch addTarget:self action:@selector(onSwitchUpdate:) forControlEvents:UIControlEventValueChanged];
                roomNotifCell.mxkSwitch.onTintColor = kVectorColorGreen;
            }
            
            roomNotifCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_mute_notifs", @"Vector", nil);
            roomNotifSwitch = roomNotifCell.mxkSwitch;
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:kRoomSettingsMuteNotifKey])
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
            MXKTableViewCellWithLabelAndMXKImageView *roomPhotoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
            
            if (!roomPhotoCell)
            {
                roomPhotoCell = [[MXKTableViewCellWithLabelAndMXKImageView alloc] init];
                
                roomPhotoCell.mxkLabelLeadingConstraint.constant = 15;
                roomPhotoCell.mxkImageViewTrailingConstraint.constant = 10;
                
                roomPhotoCell.mxkImageViewWidthConstraint.constant = roomPhotoCell.mxkImageViewHeightConstraint.constant = 30;
                
                roomPhotoCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
                
                // tap on avatar to update it
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRoomAvatarTap:)];
                [roomPhotoCell.mxkImageView addGestureRecognizer:tap];
                
                roomPhotoCell.mxkImageView.backgroundColor = [UIColor clearColor];
            }
            
            roomPhotoCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_photo", @"Vector", nil);
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:kRoomSettingsAvatarKey])
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
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndLargeTextView defaultReuseIdentifier]];
            
            if (!roomTopicCell)
            {
                roomTopicCell = [[TableViewCellWithLabelAndLargeTextView alloc] init];
                
                // define the cell height
                CGRect frame = roomTopicCell.frame;
                frame.size.height = ROOM_TOPIC_CELL_HEIGHT;
                roomTopicCell.frame = frame;
            }
            
            roomTopicCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_topic", @"Vector", nil);
            
            topicTextView = roomTopicCell.mxkTextView;
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:kRoomSettingsTopicKey])
            {
                topicTextView.text = (NSString*)[updatedItemsDict objectForKey:kRoomSettingsTopicKey];
            }
            else
            {
                topicTextView.text = mxRoomState.topic;
            }
                        
            topicTextView.tintColor = kVectorColorGreen;
            topicTextView.font = [UIFont systemFontOfSize:16];
            topicTextView.bounces = NO;
            topicTextView.delegate = self;
            
            // disable the edition if the user cannot update it
            topicTextView.editable = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomTopic]);
            topicTextView.textColor = kVectorTextColorGray;
            
            cell = roomTopicCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_NAME)
        {
            TableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            
            if (!roomNameCell)
            {
                roomNameCell = [[TableViewCellWithLabelAndTextField alloc] init];
            }
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_room_name", @"Vector", nil);
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            
            nameTextField = roomNameCell.mxkTextField;
            
            nameTextField.userInteractionEnabled = YES;
            nameTextField.tintColor = kVectorColorGreen;
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:kRoomSettingsNameKey])
            {
                nameTextField.text = (NSString*)[updatedItemsDict objectForKey:kRoomSettingsNameKey];
            }
            else
            {
                nameTextField.text = mxRoomState.name;
            }
            
            // disable the edition if the user cannot update it
            roomNameCell.editable = (oneSelfPowerLevel >= [powerLevels minimumPowerLevelForSendingEventAsStateEvent:kMXEventTypeStringRoomName]);
            nameTextField.textColor = kVectorTextColorGray;
            
            // Add a "textFieldDidChange" notification method to the text field control.
            [nameTextField addTarget:self action:@selector(onTextFieldUpdate:) forControlEvents:UIControlEventEditingChanged];
            
            cell = roomNameCell;
        }
        else if (row == ROOM_SETTINGS_MAIN_SECTION_ROW_PRIV_PUB)
        {
            TableViewCellWithLabelAndTextField *privPublicCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            
            if (!privPublicCell)
            {
                privPublicCell = [[TableViewCellWithLabelAndTextField alloc] init];
            }
            
            privPublicCell.mxkTextField.userInteractionEnabled = NO;
            privPublicCell.mxkTextField.text = @"";
            // FIXME: Do we want to display that the join rule of this room is public?
            privPublicCell.mxkLabel.text = mxRoom.state.isJoinRulePublic ?  NSLocalizedStringFromTable(@"room_details_room_is_public", @"Vector", nil) : NSLocalizedStringFromTable(@"room_details_room_is_private", @"Vector", nil);
            
            cell = privPublicCell;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        [self dismissFirstResponder];
        
        if (indexPath.section == ROOM_SETTINGS_MAIN_SECTION_INDEX)
        {
            if (indexPath.row == ROOM_SETTINGS_MAIN_SECTION_ROW_PHOTO)
            {
                [self onRoomAvatarTap:nil];
            }
        }
    }
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

- (void)onRoomAvatarTap:(UITapGestureRecognizer *)recognizer
{
    mediaPicker = [MediaPickerViewController mediaPickerViewController];
    mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaPicker.delegate = self;
    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:mediaPicker animated:NO];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)onSwitchUpdate:(UISwitch*)uiSwitch
{
    if (uiSwitch == roomNotifSwitch)
    {
        if (roomNotifSwitch.on == mxRoom.isMute)
        {
            [updatedItemsDict removeObjectForKey:kRoomSettingsMuteNotifKey];
        }
        else
        {
            [updatedItemsDict setObject:[NSNumber numberWithBool:roomNotifSwitch.on] forKey:kRoomSettingsMuteNotifKey];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    }
}

@end


