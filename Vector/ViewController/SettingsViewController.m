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
#define SETTINGS_SECTION_OTHER_INDEX                    3
#define SETTINGS_SECTION_COUNT                          4

#define NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX                 0
#define NOTIFICATION_SETTINGS_GLOBAL_SETTINGS_INDEX             1
//#define NOTIFICATION_SETTINGS_CONTAINING_MY_USER_NAME_INDEX     1
//#define NOTIFICATION_SETTINGS_CONTAINING_MY_DISPLAY_NAME_INDEX  2
//#define NOTIFICATION_SETTINGS_SENT_TO_ME_INDEX                  3
//#define NOTIFICATION_SETTINGS_INVITED_TO_ROOM_INDEX             4
//#define NOTIFICATION_SETTINGS_PEOPLE_LEAVE_JOIN_INDEX           5
//#define NOTIFICATION_SETTINGS_CALL_INVITATION_INDEX             6
#define NOTIFICATION_SETTINGS_COUNT                             2

#define OTHER_VERSION_INDEX         0
#define OTHER_TERM_CONDITIONS_INDEX 1
#define OTHER_PRIVACY_INDEX         2
#define OTHER_CLEAR_CACHE_INDEX     3
#define OTHER_COUNT                 4


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
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Refresh table to remove this account
        [self.tableView reloadData];
        
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
    [self reset];
    
    [super destroy];
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

    currentAlert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"account_email_validation_title"]
                                              message:message
                                                style:MXKAlertStyleAlert];

    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"abort"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert){

        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf->currentAlert = nil;

        [strongSelf stopActivityIndicator];

         // Reset new email adding
         strongSelf.newEmailEditingEnabled = NO;
    }];

    __strong __typeof(threePID)strongThreePID = threePID;

    [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"continue"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {

        // We always bind emails when registering, so let's do the same here
        [threePID add3PIDToUser:YES success:^{

            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;

            [strongSelf stopActivityIndicator];

            // Reset new email adding
            strongSelf.newEmailEditingEnabled = NO;

            // Update linked emails
            [strongSelf loadLinkedEmails];

        } failure:^(NSError *error) {

            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->currentAlert = nil;

            NSLog(@"[SettingsViewController] Failed to bind email: %@", error);

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
        }];
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
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        count = OTHER_COUNT;
    }
    
    return count;
}

- (MXKTableViewCellWithLabelAndTextField*)getLabelAndTextFieldCell:(UITableView*)tableview
{
    MXKTableViewCellWithLabelAndTextField *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
    
    if (!cell)
    {
        cell = [[MXKTableViewCellWithLabelAndTextField alloc] init];
    }
    
    cell.mxkTextField.userInteractionEnabled = YES;
    cell.mxkTextField.borderStyle = UITextBorderStyleNone;
    cell.mxkTextField.textAlignment = NSTextAlignmentRight;
    cell.mxkTextField.textColor = [UIColor lightGrayColor];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    cell.alpha = 1.0f;
    cell.userInteractionEnabled = YES;
    
    return cell;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableview
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableview dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    
    if (!cell)
    {
        cell = [[MXKTableViewCellWithLabelAndSwitch alloc] init];
    }
    
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
        signOutCell.mxkButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        
        [signOutCell.mxkButton  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [signOutCell.mxkButton addTarget:self action:@selector(onSignout:) forControlEvents:UIControlEventTouchUpInside];
        
        cell = signOutCell;
    }
    else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        MXMyUser* myUser = session.myUser;
        
        if (row == userSettingsProfilePictureIndex)
        {
            MXKTableViewCellWithLabelAndMXKImageView *profileCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
            
            if (!profileCell)
            {
                profileCell = [[MXKTableViewCellWithLabelAndMXKImageView alloc] init];
            }
            
            profileCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_profile_picture", @"Vector", nil);
            
            // if the user defines a new avatar
            if (newAvatarImage)
            {
                profileCell.mxkImageView.image = newAvatarImage;
            }
            else
            {
                UIImage* avatarImage = [AvatarGenerator generateRoomMemberAvatar:myUser.userId displayName:myUser.displayname];
                
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
            
            [profileCell.mxkImageView.layer setCornerRadius:profileCell.mxkImageView.frame.size.width / 2];
            profileCell.mxkImageView.clipsToBounds = YES;
            
            cell = profileCell;
        }
        else if (row == userSettingsDisplayNameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *displaynameCell = [self getLabelAndTextFieldCell:tableView];
            
            displaynameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_display_name", @"Vector", nil);
            displaynameCell.mxkTextField.text = myUser.displayname;
            
            displaynameCell.mxkTextField.tag = row;
            [displaynameCell.mxkTextField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            [displaynameCell.mxkTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            
            cell = displaynameCell;
        }
        else if (row == userSettingsFirstNameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *firstCell = [self getLabelAndTextFieldCell:tableView];
        
            firstCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_first_name", @"Vector", nil);
            firstCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = firstCell;
        }
        else if (row == userSettingsSurnameIndex)
        {
            MXKTableViewCellWithLabelAndTextField *surnameCell = [self getLabelAndTextFieldCell:tableView];
            
            surnameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_surname", @"Vector", nil);
            surnameCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = surnameCell;
        }
        else if (userSettingsEmailStartIndex <= row &&  row < userSettingsNewEmailIndex)
        {
            MXKTableViewCellWithLabelAndTextField *emailCell = [self getLabelAndTextFieldCell:tableView];
            
            emailCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_email_address", @"Vector", nil);
            emailCell.mxkTextField.text = account.linkedEmails[row - userSettingsEmailStartIndex];
            emailCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = emailCell;
        }
        else if (row == userSettingsNewEmailIndex)
        {
            MXKTableViewCellWithLabelAndTextField *newEmailCell = [self getLabelAndTextFieldCell:tableView];

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
            MXKTableViewCellWithLabelAndTextField *passwordCell = [self getLabelAndTextFieldCell:tableView];
            
            passwordCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_change_password", @"Vector", nil);
            passwordCell.mxkTextField.text = @"*********";
            passwordCell.mxkTextField.userInteractionEnabled = NO;
            
            cell = passwordCell;
        }
        else if (row == userSettingsPhoneNumberIndex)
        {
            MXKTableViewCellWithLabelAndTextField *phonenumberCell = [self getLabelAndTextFieldCell:tableView];
            
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
            MXKTableViewCellWithLabelAndTextField *nightModeCell = [self getLabelAndTextFieldCell:tableView];
                                                                    
            nightModeCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_night_mode", @"Vector", nil);
            nightModeCell.mxkTextField.userInteractionEnabled = NO;
            nightModeCell.mxkTextField.text = NSLocalizedStringFromTable(@"off", @"Vector", nil);
            nightModeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = nightModeCell;
        }
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        
//        MXPushRule *rule;
        
        if (row == NOTIFICATION_SETTINGS_ENABLE_PUSH_INDEX)
        {
            MXKTableViewCellWithLabelAndSwitch* enableAllCell = [self getLabelAndSwitchCell:tableView];
    
            enableAllCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_enable_push_notif", @"Vector", nil);
            enableAllCell.mxkSwitch.on = account.pushNotificationServiceIsActive;
            [enableAllCell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [enableAllCell.mxkSwitch addTarget:self action:@selector(togglePushNotifications:) forControlEvents:UIControlEventTouchUpInside];
            
            [enableAllCell layoutIfNeeded];
            cell = enableAllCell;
        }
        else if (row == NOTIFICATION_SETTINGS_GLOBAL_SETTINGS_INDEX)
        {
            MXKTableViewCell *globalInfoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
            if (!globalInfoCell)
            {
                globalInfoCell = [[MXKTableViewCell alloc] init];
            }
            
            globalInfoCell.textLabel.text = NSLocalizedStringFromTable(@"settings_global_settings_info", @"Vector", nil);
            globalInfoCell.textLabel.numberOfLines = 0;
            cell = globalInfoCell;
        }
//        else if (row == NOTIFICATION_SETTINGS_CONTAINING_MY_USER_NAME_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* myNameCell = [self getLabelAndSwitchCell:tableView];
//            
//            myNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_messages_my_user_name", @"Vector", nil);
//            rule = [session.notificationCenter ruleById:kMXNotificationCenterContainUserNameRuleID];
//            cell = myNameCell;
//        }
//        else if (row == NOTIFICATION_SETTINGS_CONTAINING_MY_DISPLAY_NAME_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* myNameCell = [self getLabelAndSwitchCell:tableView];
//            
//            myNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_messages_my_display_name", @"Vector", nil);
//            rule = [session.notificationCenter ruleById:kMXNotificationCenterContainDisplayNameRuleID];
//            cell = myNameCell;
//        }
//        else if (row == NOTIFICATION_SETTINGS_SENT_TO_ME_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* sentToMeCell = [self getLabelAndSwitchCell:tableView];
//            sentToMeCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_messages_sent_to_me", @"Vector", nil);
//            rule = [session.notificationCenter ruleById:kMXNotificationCenterOneToOneRoomRuleID];
//            cell = sentToMeCell;
//        }
//        else if (row == NOTIFICATION_SETTINGS_INVITED_TO_ROOM_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* invitedToARoom = [self getLabelAndSwitchCell:tableView];
//            invitedToARoom.mxkLabel.text = NSLocalizedStringFromTable(@"settings_invited_to_room", @"Vector", nil);
//            rule = [session.notificationCenter ruleById:kMXNotificationCenterInviteMeRuleID];
//            cell = invitedToARoom;
//        }
//        else if (row == NOTIFICATION_SETTINGS_PEOPLE_LEAVE_JOIN_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* peopleJoinLeaveCell = [self getLabelAndSwitchCell:tableView];
//            peopleJoinLeaveCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_join_leave_rooms", @"Vector", nil);
//            rule = [session.notificationCenter ruleById:kMXNotificationCenterMemberEventRuleID];
//            cell = peopleJoinLeaveCell;
//        }
//        else if (row == NOTIFICATION_SETTINGS_CALL_INVITATION_INDEX)
//        {
//            MXKTableViewCellWithLabelAndSwitch* callInvitationCell = [self getLabelAndSwitchCell:tableView];
//            callInvitationCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_call_invitations", @"Vector", nil);
//            rule = [session.notificationCenter ruleById:kMXNotificationCenterCallRuleID];
//            cell = callInvitationCell;
//        }
        
//        // common management
//        MXKTableViewCellWithLabelAndSwitch* switchCell = (MXKTableViewCellWithLabelAndSwitch*)cell;
//        switchCell.mxkSwitch.tag = row;
//        
//        if (rule)
//        {
//            switchCell.mxkSwitch.on = rule.enabled;
//        }
//        
//        [switchCell.mxkSwitch  removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
//        [switchCell.mxkSwitch addTarget:self action:@selector(onRuleUpdate:) forControlEvents:UIControlEventTouchUpInside];
    
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        if (row == OTHER_VERSION_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *versionCell = [self getLabelAndTextFieldCell:tableView];
            
            NSString* appVersion = [AppDelegate theDelegate].appVersion;
            NSString* build = [AppDelegate theDelegate].build;
            
            versionCell.mxkLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_version", @"Vector", nil), [NSString stringWithFormat:@"%@ %@", appVersion, build]];
            versionCell.mxkTextField.userInteractionEnabled = NO;
            versionCell.mxkTextField.text = nil;
            
            cell = versionCell;
        }
        else if (row == OTHER_TERM_CONDITIONS_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *termAndConditionCell = [self getLabelAndTextFieldCell:tableView];
            
            termAndConditionCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_term_conditions", @"Vector", nil);
            termAndConditionCell.mxkTextField.userInteractionEnabled = NO;
            termAndConditionCell.mxkTextField.text = nil;
            
            cell = termAndConditionCell;
        }
        else if (row == OTHER_PRIVACY_INDEX)
        {
            MXKTableViewCellWithLabelAndTextField *privacyPolicyCell = [self getLabelAndTextFieldCell:tableView];
            
            privacyPolicyCell.mxkLabel.text = NSLocalizedStringFromTable(@"settings_privacy_policy", @"Vector", nil);
            privacyPolicyCell.mxkTextField.userInteractionEnabled = NO;
            privacyPolicyCell.mxkTextField.text = nil;
            
            cell = privacyPolicyCell;
        }
        else if (row == OTHER_CLEAR_CACHE_INDEX)
        {
            MXKTableViewCellWithButton *clearCacheBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!clearCacheBtnCell)
            {
                clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            
            NSString *btnTitle = [NSString stringWithFormat:@"%@", NSLocalizedStringFromTable(@"settings_clear_cache", @"Vector", nil)];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            
            [clearCacheBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [clearCacheBtnCell.mxkButton addTarget:self action:@selector(onClearCache:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = clearCacheBtnCell;
        }
    }

    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SETTINGS_SECTION_SIGN_OUT_INDEX)
    {
        return 30;
    }
    
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeader = [[UIView alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.backgroundColor = kVectorColorLightGrey;
    
    if (section == SETTINGS_SECTION_SIGN_OUT_INDEX)
    {
        return sectionHeader;
    }
    
    UILabel *sectionLabel = [[UILabel alloc] init];
    sectionLabel.font = [UIFont boldSystemFontOfSize:16];
    sectionLabel.backgroundColor = [UIColor clearColor];
    
    if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
    {
        sectionLabel.text = NSLocalizedStringFromTable(@"settings_user_settings", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_NOTIFICATIONS_SETTINGS_INDEX)
    {
        sectionLabel.text = NSLocalizedStringFromTable(@"settings_notifications_settings", @"Vector", nil);
    }
    else if (section == SETTINGS_SECTION_OTHER_INDEX)
    {
        sectionLabel.text = NSLocalizedStringFromTable(@"settings_other", @"Vector", nil);
    }
    
    [sectionLabel sizeToFit];
    sectionLabel.frame = CGRectMake(10,  sectionHeader.frame.size.height - sectionLabel.frame.size.height - 5, sectionHeader.frame.size.width - 20, sectionLabel.frame.size.height);
    [sectionHeader addSubview:sectionLabel];

    return sectionHeader;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        if (section == SETTINGS_SECTION_OTHER_INDEX)
        {
           if (row == OTHER_TERM_CONDITIONS_INDEX)
           {
               MXKWebViewViewController *webViewViewController = [[MXKWebViewViewController alloc] initWithURL:@"https://vector.im/tac.html"];
               [self.navigationController pushViewController:webViewViewController animated:YES];
           }
           else if (row == OTHER_PRIVACY_INDEX)
           {
               MXKWebViewViewController *webViewViewController = [[MXKWebViewViewController alloc] initWithURL:@"https://vector.im/privacy.html"];
               [self.navigationController pushViewController:webViewViewController animated:YES];
           }
        }
        else if (section == SETTINGS_SECTION_USER_SETTINGS_INDEX)
        {
            if (row == userSettingsProfilePictureIndex)
            {
                mediaPicker = [MediaPickerViewController mediaPickerViewController];
                mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
                mediaPicker.delegate = self;
                UINavigationController *navigationController = [UINavigationController new];
                [navigationController pushViewController:mediaPicker animated:NO];
                
                [self presentViewController:navigationController animated:YES completion:nil];
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
   [[MXKAccountManager sharedManager] logout];
}

- (void)togglePushNotifications:(id)sender
{
    // Check first whether the user allow notification from device settings
    if ([[MXKAccountManager sharedManager] isAPNSAvailable] == NO)
    {
        [currentAlert dismiss:NO];
        
        __weak typeof(self) weakSelf = self;
        
        currentAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"settings_on_denied_notification", @"Vector", nil)
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

- (void)onClearCache:(id)sender
{
    [[AppDelegate theDelegate] reloadMatrixSessions:YES];
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
    
    MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
    MXMyUser* myUser = account.mxSession.myUser;
    
    if (newDisplayName && ![myUser.displayname isEqualToString:newDisplayName])
    {
        // Save display name
        __weak typeof(self) weakSelf = self;
        [account setUserDisplayName:newDisplayName success:^{
            
            // Update the current displayname
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            strongSelf->newDisplayName = nil;
            
            // Go to the next change saving step
            [strongSelf onSave:nil];
            
        } failure:^(NSError *error) {
            
            NSLog(@"[Vector Settings View Controller] Failed to set displayName");
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            
            // Alert user
            NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
            if (!title)
            {
                title = [NSBundle mxk_localizedStringForKey:@"account_error_display_name_change_failed"];
            }
            NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            
            MXKAlert *alert = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
;
            alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"abort"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                                       {
                                           strongSelf->newDisplayName = nil;
                                           // Loop to end saving
                                           [strongSelf onSave:nil];
                                       }];
            [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"retry"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
             {
                 // Loop to retry saving
                 [strongSelf onSave:nil];
             }];
            [alert showInViewController:strongSelf];
        }];
        
        return;
    }
    
    if (newAvatarImage)
    {
        // Retrieve the current picture and make sure its orientation is up
        UIImage *updatedPicture = [MXKTools forceImageOrientationUp:newAvatarImage];
        
        // Upload picture
        MXKMediaLoader *uploader = [MXKMediaManager prepareUploaderWithMatrixSession:account.mxSession initialRange:0 andRange:1.0];
        
        [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url)
         {
             // Store uploaded picture url and trigger picture saving
             uploadedAvatarURL = url;
             newAvatarImage = nil;
             
             [self onSave:nil];
         } failure:^(NSError *error)
         {
             NSLog(@"[Vector SettingsViewController] Failed to upload image");
             uploadedAvatarURL = nil;
             newAvatarImage = nil;
         }];
        
    }
    else if (uploadedAvatarURL)
    {
        __weak typeof(self) weakSelf = self;
        [account setUserAvatarUrl:uploadedAvatarURL
                             success:^{
                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 strongSelf->uploadedAvatarURL = nil;
                                 [strongSelf onSave:nil];
                             }
                             failure:^(NSError *error) {
                                 NSLog(@"[Vector SettingsViewController] Failed to set avatar url");
                                
                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 strongSelf->uploadedAvatarURL = nil;
                                 [strongSelf onSave:nil];
                             }];
    }
    
    [self stopActivityIndicator];
    [self.tableView reloadData];
}

- (IBAction)onAddNewEmail:(id)sender
{
    // Email check
    if (![MXTools isEmailAddress:newEmailTextField.text])
    {
        MXKAlert *alert = [[MXKAlert alloc] initWithTitle:[NSBundle mxk_localizedStringForKey:@"account_error_email_wrong_title"] message:[NSBundle mxk_localizedStringForKey:@"account_error_email_wrong_description"] style:MXKAlertStyleAlert];

        alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        }];
        [alert showInViewController:self];

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
        newDisplayName = textField.text;
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
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self onAddNewEmail:textField];
    return YES;
}

#pragma password update management

- (IBAction)passwordTextFieldDidChange:(id)sender
{
    savePasswordAction.enabled = (currentPasswordTextField.text.length > 0) && (newPasswordTextField1.text.length > 2) && [newPasswordTextField1.text isEqualToString:newPasswordTextField2.text];
}

- (void)displayPasswordAlert
{
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:NSLocalizedStringFromTable(@"settings_change_password", @"Vector", nil)
                                   message:nil
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    savePasswordAction = [UIAlertAction
                         actionWithTitle:NSLocalizedStringFromTable(@"save", @"Vector", nil)
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             if ([MXKAccountManager sharedManager].activeAccounts.count > 0)
                             {
                                [self startActivityIndicator];
                                 
                                 MXKAccount* account = [MXKAccountManager sharedManager].activeAccounts.firstObject;
                                 [account changePassword:currentPasswordTextField.text with:newPasswordTextField1.text success:^{
            
                                     [self stopActivityIndicator];

                                     MXKAlert *alert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"settings_password_updated", @"Vector", nil) style:MXKAlertStyleAlert];
                                     
                                     alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                                     }];
                                     
                                     [alert showInViewController:self];
                                     
                                 } failure:^(NSError *error) {
                                     
                                      [self stopActivityIndicator];
                                     
                                     MXKAlert *alert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"settings_fail_to_update_password", @"Vector", nil) style:MXKAlertStyleAlert];
                                     
                                     alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                                     }];
                                     
                                     [alert showInViewController:self];                                     
                                 }];
                             }
                             else
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }
                             
                         }];
    
    // disable by default
    // check if the textfields have the right value
    savePasswordAction.enabled = NO;
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
        currentPasswordTextField = textField;
        currentPasswordTextField.placeholder = NSLocalizedStringFromTable(@"settings_old_password", @"Vector", nil);
        currentPasswordTextField.secureTextEntry = YES;
        [currentPasswordTextField addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
         
     }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         newPasswordTextField1 = textField;
         newPasswordTextField1.placeholder = NSLocalizedStringFromTable(@"settings_new_password", @"Vector", nil);
         newPasswordTextField1.secureTextEntry = YES;
         [newPasswordTextField1 addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
         
     }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         newPasswordTextField2 = textField;
         newPasswordTextField2.placeholder = NSLocalizedStringFromTable(@"settings_confirm_password", @"Vector", nil);
         newPasswordTextField2.secureTextEntry = YES;
         [newPasswordTextField2 addTarget:self action:@selector(passwordTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
         
         newPasswordTextField2 = textField;
     }];

    
    [alert addAction:cancel];
    [alert addAction:savePasswordAction];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
