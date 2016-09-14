/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "SettingsViewController.h"

#import "RageShakeManager.h"

#import "AppDelegate.h"

#import "VectorDesignValues.h"

#import "AvatarGenerator.h"

#import <Photos/Photos.h>
#import <MediaPlayer/MediaPlayer.h>

#define SETTINGS_SECTION_SIGN_OUT_INDEX                 0
#define SETTINGS_SECTION_USER_SETTINGS_INDEX            1
#define SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX   2
#define SETTINGS_SECTION_IGNORED_USERS_INDEX            3
#define SETTINGS_SECTION_CONTACTS_INDEX                 4
#define SETTINGS_SECTION_ADVANCED_INDEX                 5
#define SETTINGS_SECTION_OTHER_INDEX                    6
#define SETTINGS_SECTION_LABS_INDEX                     7
#define SETTINGS_SECTION_COUNT                          7   // Not 8 because the LABS section is currently hidden

#define NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX                 0
#define NOTIFICATION_SETTINGS_GLOBAL_SETTINGS_INDEX             1
//#define NOTIFICATION_SETTINGS_CONTAINING_MY_USER_NAME_INDEX     1
//#define NOTIFICATION_SETTINGS_CONTAINING_MY_DISPLAY_NAME_INDEX  2
//#define NOTIFICATION_SETTINGS_SENT_TO_ME_INDEX                  3
//#define NOTIFICATION_SETTINGS_INVITED_TO_ROOM_INDEX             4
//#define NOTIFICATION_SETTINGS_PEOPLE_LEAVE_JOIN_INDEX           5
//#define NOTIFICATION_SETTINGS_CALL_INVITATION_INDEX             6
#define NOTIFICATION_SETTINGS_COUNT                             2

#define CONTACTS_SETTINGS_ENABLE_LOCAL_CONTACTS_SYNC    0
#define CONTACTS_SETTINGS_COUNT                         1

#define OTHER_VERSION_INDEX          0
#define OTHER_COPYRIGHT_INDEX        1
#define OTHER_TERM_CONDITIONS_INDEX  2
#define OTHER_PRIVACY_INDEX          3
#define OTHER_THIRD_PARTY_INDEX      4
#define OTHER_CRASH_REPORT_INDEX     5
#define OTHER_MARK_ALL_AS_READ_INDEX 6
#define OTHER_CLEAR_CACHE_INDEX      7
#define OTHER_COUNT                  8

#define LABS_COUNT                   0

#define SECTION_TITLE_PADDING_WHEN_HIDDEN 0.01f

typedef void (^blockSettingsViewController_onReadyToDestroy)();


@interface SettingsViewController ()
{
    // Current alert (if any).
    MXKAlert *currentAlert;

    // listener
    id removedAccountObserver;
    id accountUserInfoObserver;
    id apnsInfoUpdateObserver;
    
    id notificationCenterWillUpdateObserver;
    id notificationCenterDidUpdateObserver;
    id notificationCenterDidFailObserver;
    
    // picker
    MediaPickerViewController* mediaPicker;
    
    // profile updates
    // avatar
    UIImage* newAvatarImage;
    // the avatar image has been uploaded
    NSString* uploadedAvatarURL;
    
    // new display name
    NSString* newDisplayName;
    
    // password update
    UITextField* currentPasswordTextField;
    UITextField* newPasswordTextField1;
    UITextField* newPasswordTextField2;
    UIAlertAction* savePasswordAction;

    // New email address to bind
    UITextField* newEmailTextField;

    // Dynamic rows in the user settings section
    NSInteger userSettingsProfilePictureIndex;
    NSInteger userSettingsDisplayNameIndex;
    NSInteger userSettingsFirstNameIndex;
    NSInteger userSettingsSurnameIndex;
    NSInteger userSettingsEmailStartIndex;  // The user can have several linked emails. Hence, the dynamic section items count
    NSInteger userSettingsNewEmailIndex;    // This index also marks the end of the emails list
    NSInteger userSettingsChangePasswordIndex;
    NSInteger userSettingsPhoneNumberIndex;
    NSInteger userSettingsNightModeSepIndex;
    NSInteger userSettingsNightModeIndex;
    
    // Observe kAppDelegateDidTapStatusBarNotification to handle tap on clock status bar.
    id kAppDelegateDidTapStatusBarNotificationObserver;
    
    // Postpone destroy operation when saving, pwd reset or email binding is in progress
    BOOL isSavingInProgress;
    BOOL isResetPwdInProgress;
    BOOL isEmailBindingInProgress;
    blockSettingsViewController_onReadyToDestroy onReadyToDestroyHandler;
    
    //
    UIAlertController *resetPwdAlertController;
}

/**
 Flag indicating whether the user is typing an email to bind.
 */
@property (nonatomic) BOOL newEmailEditingEnabled;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    self.tableView.backgroundColor = kVectorColorLightGrey;
    
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndMXKImageView.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        if ([MXKAccountManager sharedManager].accounts.count)
        {
            // Refresh table to remove this account
            [self.tableView reloadData];
        }
        
    }];
    
    // Add observer to handle accounts update
    accountUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountUserInfoDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self stopActivityIndicator];
        [self.tableView reloadData];
        
    }];
    
    // Add observer to apns
    apnsInfoUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountAPNSActivityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self stopActivityIndicator];
        [self.tableView reloadData];
        
    }];
    
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSave:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    if (isSavingInProgress || isResetPwdInProgress || isEmailBindingInProgress)
    {
        __weak typeof(self) weakSelf = self;
        onReadyToDestroyHandler = ^() {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf destroy];
            }
            
        };
    }
    else
    {
        // Dispose all resources
        [self reset];
        
        [super destroy];
    }
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
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"Settings"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    if ([MXKAccountManager sharedManager].activeAccounts.count > 0)
    {
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        
        // Refresh existing notification rules
        [account.mxSession.notificationCenter refreshRules:^{
            
            [self stopActivityIndicator];
            [self.tableView reloadData];
            
        } failure:^(NSError *error) {
            
            [self stopActivityIndicator];
            
        }];
        
        notificationCenterWillUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterWillUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self startActivityIndicator];
        }];
        
        notificationCenterDidUpdateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidUpdateRules object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self stopActivityIndicator];
            [self.tableView reloadData];
        }];
        
        notificationCenterDidFailObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXNotificationCenterDidFailRulesUpdate object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self stopActivityIndicator];
            
            // Notify MatrixKit user
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:note.userInfo[kMXNotificationCenterErrorKey]];
        }];
    }
    
    // Refresh display
    [self.tableView reloadData];

    // Refresh linked emails in parallel
    [self loadLinkedEmails];
    
    // Observe kAppDelegateDidTapStatusBarNotificationObserver.
    kAppDelegateDidTapStatusBarNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kAppDelegateDidTapStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self.tableView setContentOffset:CGPointMake(-self.tableView.contentInset.left, -self.tableView.contentInset.top) animated:YES];
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (currentAlert)
    {
        [currentAlert dismiss:NO];
        currentAlert = nil;
    }
    
    if (resetPwdAlertController)
    {
        [resetPwdAlertController dismissViewControllerAnimated:NO completion:nil];
        resetPwdAlertController = nil;
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
    
    if (apnsInfoUpdateObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:apnsInfoUpdateObserver];
        apnsInfoUpdateObserver = nil;
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

        // Update the top-rigth corner button
        if (!_newEmailEditingEnabled)
        {
            newEmailTextField = nil;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(onSave:)];
        }
        else
        {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddNewEmail:)];
        }

        // And refresh the corresponding table view cell with animation
        [self.tableView reloadRowsAtIndexPaths:@[
                                                 [NSIndexPath indexPathForRow:userSettingsNewEmailIndex inSection:SETTINGS_SECTION_USER_SETTINGS_INDEX]
                                                 ]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)showValidationEmailDialogWithMessage:(NSString*)message for3PID:(MXK3PID*)threePID
{
    __weak typeof(self) weakSelf = self;

    [currentAlert dismiss:NO];
    currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"account_email_validation_title"]
                                              message:message
                                                style:MXKAlertStyleAlert];

    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"abort"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert){

        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
            [strongSelf stopActivityIndicator];
            
            // Reset new email adding
            strongSelf.newEmailEditingEnabled = NO;
        }
        
    }];

    __strong __typeof(threePID)strongThreePID = threePID;

    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->isEmailBindingInProgress = YES;
            
            // We always bind emails when registering, so let's do the same here
            [threePID add3PIDToUser:YES success:^{
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->isEmailBindingInProgress = NO;
                    
                    // Check whether destroy has been called during email binding
                    if (strongSelf->onReadyToDestroyHandler)
                    {
                        // Ready to destroy
                        strongSelf->onReadyToDestroyHandler();
                        strongSelf->onReadyToDestroyHandler = nil;
                    }
                    else
                    {
                        strongSelf->currentAlert = nil;
                        
                        [strongSelf stopActivityIndicator];
                        
                        // Reset new email adding
                        strongSelf.newEmailEditingEnabled = NO;
                        
                        // Update linked emails
                        [strongSelf loadLinkedEmails];
                    }
                }
                
            } failure:^(NSError *error) {
                
                NSLog(@"[SettingsViewController] Failed to bind email: %@", error);
                
                if (weakSelf)
                {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->isEmailBindingInProgress = NO;
                    
                    // Check whether destroy has been called during email binding
                    if (strongSelf->onReadyToDestroyHandler)
                    {
                        // Ready to destroy
                        strongSelf->onReadyToDestroyHandler();
                        strongSelf->onReadyToDestroyHandler = nil;
                    }
                    else
                    {
                        strongSelf->currentAlert = nil;
                        
                        // Display the same popup again if the error is M_THREEPID_AUTH_FAILED
                        MXError *mxError = [[MXError alloc] initWithNSError:error];
                        if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringThreePIDAuthFailed])
                        {
                            [strongSelf showValidationEmailDialogWithMessage:[NSBundle mxk_localizedStringForKey:@"account_email_validation_error"] for3PID:strongThreePID];
                        }
                        else
                        {
                            [strongSelf stopActivityIndicator];
                            
                            // Notify MatrixKit user
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                        }
                    }
                }
                
            }];
        }
        
    }];

    [currentAlert showInViewController:self];
}

- (void)loadLinkedEmails
{
    // Refresh the account 3PIDs list
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    [account load3PIDs:^{

        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(SETTINGS_SECTION_USER_SETTINGS_INDEX, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];

    } failure:^(NSError *error) {
        // Display the data that has been loaded last time
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(SETTINGS_SECTION_USER_SETTINGS_INDEX, 1)];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
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
    
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == SETTINGS_SECTION_SIGN_OUT_INDEX)
    {
        count = 1;
    }
    else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;

        userSettingsProfilePictureIndex = 0;
        userSettingsDisplayNameIndex = 1;
        userSettingsChangePasswordIndex = 2;
        userSettingsEmailStartIndex = 3;
        userSettingsNewEmailIndex = userSettingsEmailStartIndex + account.linkedEmails.count;

        // Hide some unsupported account settings
        userSettingsFirstNameIndex = -1;
        userSettingsSurnameIndex = -1;
        userSettingsPhoneNumberIndex = -1;
        userSettingsNightModeSepIndex = -1;
        userSettingsNightModeIndex = -1;

        count = userSettingsNewEmailIndex + 1;
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        count = NOTIFICATION_SETTINGS_COUNT;
    }
    else if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        if ([AppDelegate theDelegate].mxSessions.count > 0)
        {
            MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
            count = session.ignoredUsers.count;
        }
        else
        {
            count = 0;
        }
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        count = CONTACTS_SETTINGS_COUNT;
    }
    else if (section == SETTINGS_SECTION_ADVANCED_INDEX)
    {
        count = 1;
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        count = OTHER_COUNT;
    }
    else if (section == SETTINGS_SECTION_LABS_INDEX)
    {
        count = LABS_COUNT;
    }
    return count;
}

- (MXKTableViewCellWithLabelAndTextField*)getLabelAndTextFieldCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndTextField *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = cell.separatorInset.left;
    cell.mxkTextFieldLeadingConstraint.constant = 16;
    cell.mxkTextFieldTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = kVectorTextColorBlack;
    
    cell.mxkTextField.userInteractionEnabled = YES;
    cell.mxkTextField.borderStyle = UITextBorderStyleNone;
    cell.mxkTextField.textAlignment = NSTextAlignmentRight;
    cell.mxkTextField.textColor = kVectorTextColorGray;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    cell.alpha = 1.0f;
    cell.userInteractionEnabled = YES;
    
    return cell;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableview forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = cell.separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = kVectorTextColorBlack;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor redColor];
    
    // check if there is a valid session
    if (([AppDelegate theDelegate].mxSessions.count == 0) || ([MXKAccountManager sharedManager].activeAccounts.count == 0))
    {
        // else use a default cell
        return cell;
    }
    
    MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;

    if (section == SETTINGS_SECTION_SIGN_OUT_INDEX)
    {
        MXKTableViewCellWithButton *signOutCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        if (!signOutCell)
        {
            signOutCell = [[MXKTableViewCellWithButton alloc] init];
        }
        
        NSString* title = NSLocalizedStringFromTable(@"settings_sign_out", @"Vector", nil);
        
        [signOutCell.mxkButton setTitle:title forState:UIControlStateNormal];
        [signOutCell.mxkButton setTitle:title forState:UIControlStateHighlighted];
        [signOutCell.mxkButton setTintColor:kVectorColorGreen];
        signOutCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
        
        [signOutCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [signOutCell.mxkButton addTarget:self action:@selector(onSignout:) forControlEvents:UIControlEventTouchUpInside];
        
        cell = signOutCell;
    }
    else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        MXMyUser* myUser = session.myUser;
        
        if (row == userSettingsProfilePictureIndex)
        {
            MXKTableViewCellWithLabelAndMXKImageView *profileCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier] forIndexPath:indexPath];
            
            profileCell.mxkLabelLeadingConstraint.constant = profileCell.separatorInset.left;
            profileCell.mxkImageViewTrailingConstraint.constant = 10;
            
            profileCell.mxkImageViewWidthConstraint.constant = profileCell.mxkImageViewHeightConstraint.constant = 30;
            profileCell.mxkImageViewDisplayBoxType = MXKTableViewCellDisplayBoxTypeCircle;
            
            if (!profileCell.mxkImageView.gestureRecognizers.count)
            {
                // tap on avatar to update it
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onProfileAvatarTap:)];
                [profileCell.mxkImageView addGestureRecognizer:tap];
            }
            
            profileCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_profile_picture", @"Vector", nil);
            profileCell.mxkLabel.textColor = kVectorTextColorBlack;
            
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
                    
                    [profileCell.mxkImageView setImageURL:[session.matrixRestClient urlOfContentThumbnail:myUser.avatarUrl toFitViewSize:profileCell.mxkImageView.frame.size withMethod:MXThumbnailingMethodCrop] withType:nil andImageOrientation:UIImageOrientationUp previewImage:avatarImage];
                }
                else
                {
                    profileCell.mxkImageView.image = avatarImage;
                }
            }
            
            cell = profileCell;
        }
        else if (row == userSettingsDisplayNameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *displaynameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            displaynameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_display_name", @"Vector", nil);
            displaynameCell.mxkTextField.text = myUser.displayname;
            
            displaynameCell.mxkTextField.tag = row;
            displaynameCell.mxkTextField.delegate = self;
            [displaynameCell.mxkTextField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [displaynameCell.mxkTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            
            cell = displaynameCell;
        }
        else if (row == userSettingsFirstNameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *firstCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
        
            firstCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_first_name", @"Vector", nil);
            firstCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = firstCell;
        }
        else if (row == userSettingsSurnameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *surnameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            surnameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_surname", @"Vector", nil);
            surnameCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = surnameCell;
        }
        else if (userSettingsEmailStartIndex <= row &&  row < userSettingsNewEmailIndex)
        {
            MXKTableViewCellWithLabelAndTextField *emailCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            emailCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_email_address", @"Vector", nil);
            emailCell.mxkTextField.text = account.linkedEmails[row - userSettingsEmailStartIndex];
            emailCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = emailCell;
        }
        else if (row == userSettingsNewEmailIndex)
        {
            MXKTableViewCellWithLabelAndTextField *newEmailCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];

            // Render the cell according to the `newEmailEditingEnabled` property
            if (!_newEmailEditingEnabled)
            {
                newEmailCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_add_email_address", @"Vector", nil);
                newEmailCell.mxkTextField.text = nil;
                newEmailCell.mxkTextField.userInteractionEnabled = NO;
                newEmailCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus_icon"]];
            }
            else
            {
                newEmailCell.mxkLabel.text = nil;
                newEmailCell.mxkTextField.text = newEmailTextField.text;
                newEmailCell.mxkTextField.userInteractionEnabled = YES;
                newEmailCell.mxkTextField.keyboardType = UIKeyboardTypeEmailAddress;
                newEmailCell.mxkTextField.autocorrectionType = UITextAutocorrectionTypeNo;
                newEmailCell.mxkTextField.spellCheckingType = UITextSpellCheckingTypeNo;
                newEmailCell.mxkTextField.delegate = self;

                [newEmailCell.mxkTextField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                [newEmailCell.mxkTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

                [newEmailCell.mxkTextField removeTarget:self action:@selector(textFieldDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
                [newEmailCell.mxkTextField addTarget:self action:@selector(textFieldDidEnd:) forControlEvents:UIControlEventEditingDidEnd];

                // When displaying the textfield the 1st time, open the keyboard
                if (!newEmailTextField)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [newEmailCell.mxkTextField becomeFirstResponder];
                    });
                }
                newEmailTextField = newEmailCell.mxkTextField;
            }

            newEmailCell.mxkTextField.tag = row;

            cell = newEmailCell;
        }
        else if (row == userSettingsChangePasswordIndex)
        {
            MXKTableViewCellWithLabelAndTextField *passwordCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            passwordCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_change_password", @"Vector", nil);
            passwordCell.mxkTextField.text = @"*********";
            passwordCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = passwordCell;
        }
        else if (row == userSettingsPhoneNumberIndex)
        {
            MXKTableViewCellWithLabelAndTextField *phonenumberCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
            
            phonenumberCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_phone_number", @"Vector", nil);
            phonenumberCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = phonenumberCell;
        }
        else if (row == userSettingsNightModeSepIndex)
        {
            UITableViewCell *sepCell = [[UITableViewCell alloc] init];
            sepCell.backgroundColor = kVectorColorLightGrey;
            
            cell = sepCell;
        }
        else if (row == userSettingsNightModeIndex)
        {
            MXKTableViewCellWithLabelAndTextField *nightModeCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
                                                                    
            nightModeCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_night_mode", @"Vector", nil);
            nightModeCell.mxkTextField.userInteractionEnabled = NO;
            nightModeCell.mxkTextField.text = NSLocalizedStringFromTable(@"off", @"Vector", nil);
            nightModeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = nightModeCell;
        }
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        if (row == NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* enableAllCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
    
            enableAllCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_enable_push_notif", @"Vector", nil);
            enableAllCell.mxkSwitch.on = account.pushNotificationServiceIsActive;
            [enableAllCell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [enableAllCell.mxkSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = enableAllCell;
        }
        else if (row == NOTIFICATION_SETTINGS_GLOBAL_SETTINGS_INDEX)
        {
            MXKTableViewCell *globalInfoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!globalInfoCell)
            {
                globalInfoCell = [[MXKTableViewCell alloc] init];
            }

            NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

            globalInfoCell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_global_settings_info", @"Vector", nil), appDisplayName];
            globalInfoCell.textLabel.numberOfLines = 0;
            cell = globalInfoCell;
        }
    }
    else if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        MXKTableViewCell *privacyPolicyCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!privacyPolicyCell)
        {
            privacyPolicyCell = [[MXKTableViewCell alloc] init];
            privacyPolicyCell.textLabel.font = [UIFont systemFontOfSize:17];
        }

        NSString *ignoredUserId;
        if (indexPath.row < session.ignoredUsers.count)
        {
            ignoredUserId = session.ignoredUsers[indexPath.row];
        }
        privacyPolicyCell.textLabel.text = ignoredUserId;
        privacyPolicyCell.textLabel.textColor = kVectorTextColorBlack;

        cell = privacyPolicyCell;
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        if (row == CONTACTS_SETTINGS_ENABLE_LOCAL_CONTACTS_SYNC)
        {
            MXKTableViewCellWithLabelAndSwitch* enableAllCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];

            enableAllCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_contacts_discover_matrix_users_with_local_emails", @"Vector", nil);
             enableAllCell.mxkSwitch.on = [MXKAppSettings standardAppSettings].syncLocalContacts;
            [enableAllCell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [enableAllCell.mxkSwitch addTarget:self action:@selector(toggleLocalContactsSync:) forControlEvents:UIControlEventTouchUpInside];

            cell = enableAllCell;
        }
    }
    else if (section == SETTINGS_SECTION_ADVANCED_INDEX)
    {
        MXKTableViewCell *configCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
        if (!configCell)
        {
            configCell = [[MXKTableViewCell alloc] init];
            configCell.textLabel.font = [UIFont systemFontOfSize:17];
        }
        
        NSString *configFormat = [NSString stringWithFormat:@"%@\n%@\n%@", [NSBundle mxk_localizedStringForKey:@"settings_config_user_id"], [NSBundle mxk_localizedStringForKey:@"settings_config_home_server"], [NSBundle mxk_localizedStringForKey:@"settings_config_identity_server"]];
        
        configCell.textLabel.text =[NSString stringWithFormat:configFormat, account.mxCredentials.userId, account.mxCredentials.homeServer, account.identityServerURL];
        configCell.textLabel.numberOfLines = 0;
        configCell.textLabel.textColor = kVectorTextColorBlack;
        
        cell = configCell;
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        if (row == OTHER_VERSION_INDEX)
        {
            MXKTableViewCell *versionCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!versionCell)
            {
                versionCell = [[MXKTableViewCell alloc] init];
                versionCell.textLabel.font = [UIFont systemFontOfSize:17];
            }
            
            NSString* appVersion = [AppDelegate theDelegate].appVersion;
            NSString* build = [AppDelegate theDelegate].build;
            
            versionCell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_version", @"Vector", nil), [NSString stringWithFormat:@"%@ %@", appVersion, build]];
            versionCell.textLabel.textColor = kVectorTextColorBlack;
            
            cell = versionCell;
        }
        else if (row == OTHER_TERM_CONDITIONS_INDEX)
        {
            MXKTableViewCell *termAndConditionCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!termAndConditionCell)
            {
                termAndConditionCell = [[MXKTableViewCell alloc] init];
                termAndConditionCell.textLabel.font = [UIFont systemFontOfSize:17];
            }

            termAndConditionCell.textLabel.text = NSLocalizedStringFromTable(@"settings_term_conditions", @"Vector", nil);
            termAndConditionCell.textLabel.textColor = kVectorTextColorBlack;

            cell = termAndConditionCell;
        }
        else if (row == OTHER_COPYRIGHT_INDEX)
        {
            MXKTableViewCell *copyrightCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!copyrightCell)
            {
                copyrightCell = [[MXKTableViewCell alloc] init];
                copyrightCell.textLabel.font = [UIFont systemFontOfSize:17];
            }

            copyrightCell.textLabel.text = NSLocalizedStringFromTable(@"settings_copyright", @"Vector", nil);
            copyrightCell.textLabel.textColor = kVectorTextColorBlack;

            cell = copyrightCell;
        }
        else if (row == OTHER_PRIVACY_INDEX)
        {
            MXKTableViewCell *privacyPolicyCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!privacyPolicyCell)
            {
                privacyPolicyCell = [[MXKTableViewCell alloc] init];
                privacyPolicyCell.textLabel.font = [UIFont systemFontOfSize:17];
            }
            
            privacyPolicyCell.textLabel.text = NSLocalizedStringFromTable(@"settings_privacy_policy", @"Vector", nil);
            privacyPolicyCell.textLabel.textColor = kVectorTextColorBlack;
            
            cell = privacyPolicyCell;
        }
        else if (row == OTHER_THIRD_PARTY_INDEX)
        {
            MXKTableViewCell *thirdPartyCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!thirdPartyCell)
            {
                thirdPartyCell = [[MXKTableViewCell alloc] init];
                thirdPartyCell.textLabel.font = [UIFont systemFontOfSize:17];
            }
            
            thirdPartyCell.textLabel.text = NSLocalizedStringFromTable(@"settings_third_party_notices", @"Vector", nil);
            thirdPartyCell.textLabel.textColor = kVectorTextColorBlack;
            
            cell = thirdPartyCell;
        }
        else if (row == OTHER_CRASH_REPORT_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* sendCrashReportCell = [self getLabelAndSwitchCell:tableView forIndexPath:indexPath];
            
            sendCrashReportCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_send_crash_report", @"Vector", nil);
            sendCrashReportCell.mxkSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableCrashReport"];
            [sendCrashReportCell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [sendCrashReportCell.mxkSwitch addTarget:self action:@selector(toggleSendCrashReport:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = sendCrashReportCell;
        }
        else if (row == OTHER_MARK_ALL_AS_READ_INDEX)
        {
            MXKTableViewCellWithButton *markAllBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!markAllBtnCell)
            {
                markAllBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            
            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_mark_all_as_read", @"Vector", nil);
            [markAllBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [markAllBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [markAllBtnCell.mxkButton setTintColor:kVectorColorGreen];
            markAllBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [markAllBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [markAllBtnCell.mxkButton addTarget:self action:@selector(markAllAsRead:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = markAllBtnCell;
        }
        else if (row == OTHER_CLEAR_CACHE_INDEX)
        {
            MXKTableViewCellWithButton *clearCacheBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!clearCacheBtnCell)
            {
                clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            
            NSString *btnTitle = NSLocalizedStringFromTable(@"settings_clear_cache", @"Vector", nil);
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            [clearCacheBtnCell.mxkButton setTintColor:kVectorColorGreen];
            clearCacheBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
            
            [clearCacheBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [clearCacheBtnCell.mxkButton addTarget:self action:@selector(clearCache:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = clearCacheBtnCell;
        }
    }
    else if (section == SETTINGS_SECTION_LABS_INDEX)
    {
    }

    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_user_settings", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_notifications_settings", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        if ([AppDelegate theDelegate].mxSessions.count > 0)
        {
            MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
            if (session.ignoredUsers.count)
            {
                return NSLocalizedStringFromTable(@"settings_ignored_users", @"Vector", nil);
            }
        }

        // Hide this section
        return nil;
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_contacts", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_ADVANCED_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_advanced", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_other", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_LABS_INDEX)
    {
        return NSLocalizedStringFromTable(@"settings_labs", @"Vector", nil);
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

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SETTINGS_SECTION_ADVANCED_INDEX)
    {
        // TODO Handle multi accounts
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:17];
        
        NSString *configFormat = [NSString stringWithFormat:@"%@\n%@\n%@",[NSBundle mxk_localizedStringForKey:@"settings_config_user_id"],  [NSBundle mxk_localizedStringForKey:@"settings_config_home_server"], [NSBundle mxk_localizedStringForKey:@"settings_config_identity_server"]];
        
        label.text = [NSString stringWithFormat:configFormat, account.mxCredentials.userId, account.mxCredentials.homeServer, account.identityServerURL];
        
        [label sizeToFit];
        return label.frame.size.height + 16;
    }
    
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        if ([AppDelegate theDelegate].mxSessions.count > 0)
        {
            MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
            if (session.ignoredUsers.count == 0)
            {
                // Hide this section
                return SECTION_TITLE_PADDING_WHEN_HIDDEN;
            }
        }
    }
    
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
    {
        if ([AppDelegate theDelegate].mxSessions.count > 0)
        {
            MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
            if (session.ignoredUsers.count == 0)
            {
                // Hide this section
                return SECTION_TITLE_PADDING_WHEN_HIDDEN;
            }
        }
    }

    return [super tableView:tableView heightForFooterInSection:section];
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;

        if (section == SETTINGS_SECTION_IGNORED_USERS_INDEX)
        {
            MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];

            NSString *ignoredUserId;
            if (indexPath.row < session.ignoredUsers.count)
            {
                ignoredUserId = session.ignoredUsers[indexPath.row];
            }

            if (ignoredUserId)
            {
                [currentAlert dismiss:NO];

                __weak typeof(self) weakSelf = self;

                currentAlert = [[MXKAlert alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_unignore_user", @"Vector", nil), ignoredUserId]
                                                       message:nil
                                                         style:MXKAlertStyleAlert];

                [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"yes"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;

                    MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];

                    // Remove the member from the ignored user list
                    [strongSelf startActivityIndicator];
                    [session unIgnoreUsers:@[ignoredUserId] success:^{

                        [strongSelf stopActivityIndicator];

                    } failure:^(NSError *error) {

                        [strongSelf stopActivityIndicator];

                        NSLog(@"[ContactDetailsViewController] Unignore %@ failed: %@", ignoredUserId, error);

                        // Notify MatrixKit user
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];

                    }];
                }];

                currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"no"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert){

                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->currentAlert = nil;
                    
                }];
                
                [currentAlert showInViewController:self];
            }
        }
        else
        if (section == SETTINGS_SECTION_OTHER_INDEX)
        {
            if (row == OTHER_COPYRIGHT_INDEX)
            {
                MXKWebViewViewController *webViewViewController = [[MXKWebViewViewController alloc] initWithURL:NSLocalizedStringFromTable(@"settings_copyright_url", @"Vector", nil)];
                [self.navigationController pushViewController:webViewViewController animated:YES];
            }
            else if (row == OTHER_TERM_CONDITIONS_INDEX)
            {
                MXKWebViewViewController *webViewViewController = [[MXKWebViewViewController alloc] initWithURL:NSLocalizedStringFromTable(@"settings_term_conditions_url", @"Vector", nil)];
                [self.navigationController pushViewController:webViewViewController animated:YES];
            }
            else if (row == OTHER_PRIVACY_INDEX)
            {
                MXKWebViewViewController *webViewViewController = [[MXKWebViewViewController alloc] initWithURL:NSLocalizedStringFromTable(@"settings_privacy_policy_url", @"Vector", nil)];
                [self.navigationController pushViewController:webViewViewController animated:YES];
            }
            else if (row == OTHER_THIRD_PARTY_INDEX)
            {
                NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"third_party_licenses" ofType:@"html" inDirectory:nil];

                MXKWebViewViewController *webViewViewController = [[MXKWebViewViewController alloc] initWithLocalHTMLFile:htmlFile];
                [self.navigationController pushViewController:webViewViewController animated:YES];
            }
        }
        else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
        {
            if (row == userSettingsProfilePictureIndex)
            {
                [self onProfileAvatarTap:nil];
            }
            else if (row == userSettingsChangePasswordIndex)
            {
                [self displayPasswordAlert];
            }
            else if (row == userSettingsNewEmailIndex)
            {
                // Enable the new email text field
                self.newEmailEditingEnabled = YES;
            }
        }
        
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - actions

- (void)onSignout:(id)sender
{
    // Feedback: disable button and run activity indicator
    UIButton *button = (UIButton*)sender;
    button.enabled = NO;
    [self startActivityIndicator];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [[MXKAccountManager sharedManager] logout];
        
    });
}

- (void)togglePushNotifications:(id)sender
{
    // Check first whether the user allow notification from device settings
    if ([[MXKAccountManager sharedManager] isAPNSAvailable] == NO)
    {
        [currentAlert dismiss:NO];
        
        __weak typeof(self) weakSelf = self;

        NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

        currentAlert = [[MXKAlert alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_on_denied_notification", @"Vector", nil), appDisplayName]
                                               message:nil
                                                 style:MXKAlertStyleAlert];
        
        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert){
            
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;
            
        }];
        
        [currentAlert showInViewController:self];
        
        // Keep off the switch
        ((UISwitch*)sender).on = NO;
    }
    else if ([MXKAccountManager sharedManager].activeAccounts.count)
    {
        [self startActivityIndicator];
        
        MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
        
        // toggle the pushes
        [account setEnablePushNotifications:!account.pushNotificationServiceIsActive];
    }
}

- (void)toggleLocalContactsSync:(id)sender
{
    UISwitch *switchButton = (UISwitch*)sender;

    if (switchButton.on)
    {
        [MXKContactManager requestUserConfirmationForLocalContactsSyncInViewController:self completionHandler:^(BOOL granted) {

            [MXKAppSettings standardAppSettings].syncLocalContacts = granted;
            switchButton.on = granted;
        }];
    }
    else
    {
        [MXKAppSettings standardAppSettings].syncLocalContacts = NO;
        switchButton.on = NO;
    }
}

- (void)toggleSendCrashReport:(id)sender
{
    BOOL enable = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableCrashReport"];
    if (enable)
    {
        NSLog(@"[SettingsViewController] disable automatic crash report sending");
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableCrashReport"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[AppDelegate theDelegate] stopGoogleAnalytics];
        
        // Remove potential crash file.
        [MXLogger deleteCrashLog];
    }
    else
    {
        NSLog(@"[SettingsViewController] enable automatic crash report sending");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableCrashReport"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[AppDelegate theDelegate] startGoogleAnalytics];
    }
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
    [self startActivityIndicator];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [[AppDelegate theDelegate] reloadMatrixSessions:YES];
        
    });
}

//- (void)onRuleUpdate:(id)sender
//{
//    MXPushRule* pushRule = nil;
//    MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
//    
//    NSInteger row = ((UIView*)sender).tag;
//    
//    if (row == NOTIFICATION_SETTINGS_CONTAINING_MY_DISPLAY_NAME_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterContainDisplayNameRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_CONTAINING_MY_USER_NAME_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterContainUserNameRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_SENT_TO_ME_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterOneToOneRoomRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_INVITED_TO_ROOM_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterInviteMeRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_PEOPLE_LEAVE_JOIN_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterMemberEventRuleID];
//    }
//    else if (row == NOTIFICATION_SETTINGS_CALL_INVITATION_INDEX)
//    {
//        pushRule = [session.notificationCenter ruleById:kMXNotificationCenterCallRuleID];
//    }
//    
//    if (pushRule)
//    {
//        // toggle the rule
//        [session.notificationCenter enableRule:pushRule isEnabled:!pushRule.enabled];
//    }
//}

//
- (void)onSave:(id)sender
{
    // sanity check
    if ([MXKAccountManager sharedManager].activeAccounts.count == 0)
    {
        return;
    }
    
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
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->newDisplayName = nil;
                
                // Go to the next change saving step
                [strongSelf onSave:nil];
            }
            
        } failure:^(NSError *error) {
            
            NSLog(@"[SettingsViewController] Failed to set displayName");
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf handleErrorDuringProfileChangeSaving:error];
            }
            
        }];
        
        return;
    }
    
    if (newAvatarImage)
    {
        // Retrieve the current picture and make sure its orientation is up
        UIImage *updatedPicture = [MXKTools forceImageOrientationUp:newAvatarImage];
        
        // Upload picture
        MXKMediaLoader *uploader = [MXKMediaManager prepareUploaderWithMatrixSession:account.mxSession initialRange:0 andRange:1.0];
        
        [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                // Store uploaded picture url and trigger picture saving
                strongSelf->uploadedAvatarURL = url;
                strongSelf->newAvatarImage = nil;
                [strongSelf onSave:nil];
            }
            
            
        } failure:^(NSError *error) {
            
            NSLog(@"[SettingsViewController] Failed to upload image");
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf handleErrorDuringProfileChangeSaving:error];
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
                                     __strong __typeof(weakSelf)strongSelf = weakSelf;
                                     strongSelf->uploadedAvatarURL = nil;
                                     [strongSelf onSave:nil];
                                 }
                                 
                             }
                             failure:^(NSError *error) {
                                 
                                 NSLog(@"[SettingsViewController] Failed to set avatar url");
                                
                                 if (weakSelf)
                                 {
                                     __strong __typeof(weakSelf)strongSelf = weakSelf;
                                     [strongSelf handleErrorDuringProfileChangeSaving:error];
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
        [self.tableView reloadData];
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
            title = [NSBundle mxk_localizedStringForKey:@"settings_fail_to_update_profile"];
        }
        NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
        
        [currentAlert dismiss:NO];
        currentAlert = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
        
        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"abort"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                strongSelf->currentAlert = nil;
                
                // Reset the updated displayname
                strongSelf->newDisplayName = nil;
                
                // Discard picture change
                strongSelf->uploadedAvatarURL = nil;
                strongSelf->newAvatarImage = nil;
                
                // Loop to end saving
                [strongSelf onSave:nil];
            }
            
        }];
        
        [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"retry"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                strongSelf->currentAlert = nil;
                
                // Loop to retry saving
                [strongSelf onSave:nil];
            }
            
        }];
        
        
        [currentAlert showInViewController:rootViewController];
    }
}

- (IBAction)onAddNewEmail:(id)sender
{
    // Email check
    if (![MXTools isEmailAddress:newEmailTextField.text])
    {
        [currentAlert dismiss:NO];
        __weak typeof(self) weakSelf = self;
        
        currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"account_error_email_wrong_title"] message:[NSBundle mxk_localizedStringForKey:@"account_error_email_wrong_description"] style:MXKAlertStyleAlert];

        currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            
            if (weakSelf)
            {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                
                strongSelf->currentAlert = nil;
            }
            
        }];
        [currentAlert showInViewController:self];

        return;
    }

    [self startActivityIndicator];

    // Dismiss the keyboard
    [newEmailTextField resignFirstResponder];

    MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];

    MXK3PID *new3PID = [[MXK3PID alloc] initWithMedium:kMX3PIDMediumEmail andAddress:newEmailTextField.text];
    [new3PID requestValidationTokenWithMatrixRestClient:session.matrixRestClient nextLink:nil success:^{

        [self showValidationEmailDialogWithMessage:[NSBundle mxk_localizedStringForKey:@"account_email_validation_message"] for3PID:new3PID];

    } failure:^(NSError *error) {

        [self stopActivityIndicator];

        NSLog(@"[SettingsViewController] Failed to request email token: %@", error);

        // Notify MatrixKit user
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];

    }];
}

- (void)updateSaveButtonStatus
{
    if ([AppDelegate theDelegate].mxSessions.count > 0)
    {
        BOOL saveButtonEnabled;
        if (!_newEmailEditingEnabled)
        {
            MXSession* session = [[AppDelegate theDelegate].mxSessions objectAtIndex:0];
            MXMyUser* myUser = session.myUser;

            saveButtonEnabled = (nil != newAvatarImage);

            if (!saveButtonEnabled)
            {
                if (newDisplayName)
                {
                    saveButtonEnabled = ![myUser.displayname isEqualToString:newDisplayName];
                }
            }
        }
        else
        {
            saveButtonEnabled = (0 != newEmailTextField.text.length);
        }
        
        self.navigationItem.rightBarButtonItem.enabled = saveButtonEnabled;
    }
}

- (void)onProfileAvatarTap:(UITapGestureRecognizer *)recognizer
{
    mediaPicker = [MediaPickerViewController mediaPickerViewController];
    mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaPicker.delegate = self;
    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:mediaPicker animated:NO];
    
    [self presentViewController:navigationController animated:YES completion:nil];
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
    newAvatarImage = image;
    
    [self.tableView reloadData];
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL
{
    // this method should not be called
    [self dismissMediaPicker];
}

#pragma mark - TextField listener

- (IBAction)textFieldDidChange:(id)sender
{
    UITextField* textField = (UITextField*)sender;
    
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        // Remove white space from both ends
        newDisplayName = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self updateSaveButtonStatus];
    }
    else if (textField.tag == userSettingsNewEmailIndex)
    {
        [self updateSaveButtonStatus];
    }
}

- (IBAction)textFieldDidEnd:(id)sender
{
    UITextField* textField = (UITextField*)sender;

    // Disable the new email edition if the user leaves the text field empty
    if (textField.tag == userSettingsNewEmailIndex && textField.text.length == 0)
    {
        self.newEmailEditingEnabled = NO;
    }
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        textField.textAlignment = NSTextAlignmentLeft;
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        textField.textAlignment = NSTextAlignmentRight;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == userSettingsDisplayNameIndex)
    {
        [textField resignFirstResponder];
    }
    else if (textField.tag == userSettingsNewEmailIndex)
    {
        [self onAddNewEmail:textField];
    }
    
    return YES;
}

#pragma password update management

- (IBAction)passwordTextFieldDidChange:(id)sender
{
    savePasswordAction.enabled = (currentPasswordTextField.text.length > 0) && (newPasswordTextField1.text.length > 2) && [newPasswordTextField1.text isEqualToString:newPasswordTextField2.text];
}

- (void)displayPasswordAlert
{
    __weak typeof(self) weakSelf = self;
    [resetPwdAlertController dismissViewControllerAnimated:NO completion:nil];
    
    resetPwdAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_change_password", @"Vector", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    savePasswordAction = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"save", @"Vector", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf->resetPwdAlertController = nil;
            
            if ([MXKAccountManager sharedManager].activeAccounts.count > 0)
            {
                [strongSelf startActivityIndicator];
                strongSelf->isResetPwdInProgress = YES;
                
                MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
                
                [account changePassword:currentPasswordTextField.text with:newPasswordTextField1.text success:^{
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->isResetPwdInProgress = NO;
                        [strongSelf stopActivityIndicator];
                        
                        // Display a successful message only if the settings screen is still visible (destroy is not called yet)
                        if (!strongSelf->onReadyToDestroyHandler)
                        {
                            [strongSelf->currentAlert dismiss:NO];
                            
                            strongSelf->currentAlert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"settings_password_updated", @"Vector", nil) style:MXKAlertStyleAlert];
                            
                            strongSelf->currentAlert.cancelButtonIndex = [strongSelf->currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                                
                                if (weakSelf)
                                {
                                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                                    
                                    strongSelf->currentAlert = nil;
                                    
                                    // Check whether destroy has been called durign pwd change
                                    if (strongSelf->onReadyToDestroyHandler)
                                    {
                                        // Ready to destroy
                                        strongSelf->onReadyToDestroyHandler();
                                        strongSelf->onReadyToDestroyHandler = nil;
                                    }
                                }
                                
                            }];
                            
                            [strongSelf->currentAlert showInViewController:strongSelf];
                        }
                        else
                        {
                            // Ready to destroy
                            strongSelf->onReadyToDestroyHandler();
                            strongSelf->onReadyToDestroyHandler = nil;
                        }
                    }
                    
                } failure:^(NSError *error) {
                    
                    if (weakSelf)
                    {
                        __strong __typeof(weakSelf)strongSelf = weakSelf;
                        
                        strongSelf->isResetPwdInProgress = NO;
                        [strongSelf stopActivityIndicator];
                        
                        // Display a failure message on the current screen
                        UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
                        if (rootViewController)
                        {
                            [strongSelf->currentAlert dismiss:NO];
                            strongSelf->currentAlert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"settings_fail_to_update_password", @"Vector", nil) style:MXKAlertStyleAlert];
                            
                            strongSelf->currentAlert.cancelButtonIndex = [strongSelf->currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                                
                                if (weakSelf)
                                {
                                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                                    
                                    strongSelf->currentAlert = nil;
                                    
                                    // Check whether destroy has been called durign pwd change
                                    if (strongSelf->onReadyToDestroyHandler)
                                    {
                                        // Ready to destroy
                                        strongSelf->onReadyToDestroyHandler();
                                        strongSelf->onReadyToDestroyHandler = nil;
                                    }
                                }
                                
                            }];
                            
                            [strongSelf->currentAlert showInViewController:rootViewController];
                        }
                    }
                    
                }];
            }
        }
        
    }];
    
    // disable by default
    // check if the textfields have the right value
    savePasswordAction.enabled = NO;
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf->resetPwdAlertController = nil;
        }
        
    }];
    
    [resetPwdAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf->currentPasswordTextField = textField;
            strongSelf->currentPasswordTextField.placeholder = NSLocalizedStringFromTable(@"settings_old_password", @"Vector", nil);
            strongSelf->currentPasswordTextField.secureTextEntry = YES;
            [strongSelf->currentPasswordTextField addTarget:strongSelf action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }
         
     }];
    
    [resetPwdAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf->newPasswordTextField1 = textField;
            strongSelf->newPasswordTextField1.placeholder = NSLocalizedStringFromTable(@"settings_new_password", @"Vector", nil);
            strongSelf->newPasswordTextField1.secureTextEntry = YES;
            [strongSelf->newPasswordTextField1 addTarget:strongSelf action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }
        
    }];
    
    [resetPwdAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        if (weakSelf)
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            strongSelf->newPasswordTextField2 = textField;
            strongSelf->newPasswordTextField2.placeholder = NSLocalizedStringFromTable(@"settings_confirm_password", @"Vector", nil);
            strongSelf->newPasswordTextField2.secureTextEntry = YES;
            [strongSelf->newPasswordTextField2 addTarget:strongSelf action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }
    }];

    
    [resetPwdAlertController addAction:cancel];
    [resetPwdAlertController addAction:savePasswordAction];

    [self presentViewController:resetPwdAlertController animated:YES completion:nil];
}

@end
