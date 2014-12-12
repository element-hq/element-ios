/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "AppDelegate.h"
#import "AppSettings.h"
#import "APNSHandler.h"
#import "MatrixHandler.h"
#import "MediaManager.h"

#import "SettingsTableViewCell.h"

#define SETTINGS_SECTION_NOTIFICATIONS_INDEX 0
#define SETTINGS_SECTION_ROOMS_INDEX         1
#define SETTINGS_SECTION_CONFIGURATION_INDEX 2
#define SETTINGS_SECTION_COMMANDS_INDEX      3

NSString* const kConfigurationFormatText = @"Home server: %@\r\nIdentity server: %@\r\nUser ID: %@\r\nAccess token: %@";
NSString* const kCommandsDescriptionText = @"The following commands are available in the room chat:\r\n\r\n /nick <display_name>: change your display name\r\n /me <action>: send the action you are doing. /me will be replaced by your display name\r\n /join <room_alias>: join a room\r\n /kick <user_id> [<reason>]: kick the user\r\n /ban <user_id> [<reason>]: ban the user\r\n /unban <user_id>: unban the user\r\n /op <user_id> <power_level>: set user power level\r\n /deop <user_id>: reset user power level to the room default value";

@interface SettingsViewController () {
    id imageLoader;
    
    NSString *currentDisplayName;
    NSString *currentPictureURL;
    NSString *uploadedPictureURL;
    
    // Listen user's settings change
    id userUpdateListener;
    
    NSMutableArray *errorAlerts;
    
    UIButton *logoutBtn;
    UISwitch *apnsNotificationsSwitch;
    UISwitch *inAppNotificationsSwitch;
    UISwitch *allEventsSwitch;
    UISwitch *unsupportedMsgSwitch;
    UISwitch *sortMembersSwitch;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIButton *userPicture;
@property (weak, nonatomic) IBOutlet UITextField *userDisplayName;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)onButtonPressed:(id)sender;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Add logout button in nav bar
    logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    logoutBtn.frame = CGRectMake(0, 0, 60, 44);
    [logoutBtn setTitle:@"Logout" forState:UIControlStateNormal];
    [logoutBtn setTitle:@"Logout" forState:UIControlStateHighlighted];
    [logoutBtn addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logoutBtn];
    
    errorAlerts = [NSMutableArray array];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isInitialSyncDone" options:0 context:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
}

- (void)dealloc {
    [self reset];
    
    errorAlerts = nil;
    
    logoutBtn = nil;
    apnsNotificationsSwitch = nil;
    inAppNotificationsSwitch = nil;
    allEventsSwitch = nil;
    unsupportedMsgSwitch = nil;
    sortMembersSwitch = nil;
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isInitialSyncDone"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh display
    [self configureView];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isResumeDone" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAPNSHandlerHasBeenUpdated) name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isResumeDone"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPNSHandlerHasBeenUpdated object:nil];
}

#pragma mark - Internal methods

- (void)onAPNSHandlerHasBeenUpdated {
    // Force table reload to update notifications section
    apnsNotificationsSwitch = nil;
    [self.tableView reloadData];
}

- (void)reset {
    // Cancel picture loader (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    
    // Cancel potential error alerts
    for (CustomAlert *alert in errorAlerts){
        [alert dismiss:NO];
    }
    
    // Remove listener
    if (userUpdateListener) {
        [[MatrixHandler sharedHandler].mxSession.myUser removeListener:userUpdateListener];
        userUpdateListener = nil;
    }
    
    currentPictureURL = nil;
    uploadedPictureURL = nil;
    UIImage *image = [UIImage imageNamed:@"default-profile"];
    [self.userPicture setImage:image forState:UIControlStateNormal];
    [self.userPicture setImage:image forState:UIControlStateHighlighted];
    
    currentDisplayName = nil;
    self.userDisplayName.text = nil;
}

- (void)configureView {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    [_activityIndicator startAnimating];
    // Disable user's interactions
    _userPicture.enabled = NO;
    _userDisplayName.enabled = NO;
    
    if ([mxHandler isInitialSyncDone]) {
        if (!userUpdateListener) {
            // Set current user's information and add observers
            [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl];
            currentDisplayName = mxHandler.mxSession.myUser.displayname;
            self.userDisplayName.text = currentDisplayName;
            
            // Register listener to update user's information
            userUpdateListener = [mxHandler.mxSession.myUser listenToUserUpdate:^(MXEvent *event) {
                // Update displayName
                if (![currentDisplayName isEqualToString:mxHandler.mxSession.myUser.displayname]) {
                    currentDisplayName = mxHandler.mxSession.myUser.displayname;
                    self.userDisplayName.text = mxHandler.mxSession.myUser.displayname;
                }
                // Update user's avatar
                [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl];
                // TODO display user's presence
            }];
        }
    } else {
        [self reset];
    }
    
    if ([mxHandler isResumeDone]) {
        [_activityIndicator stopAnimating];
        _userPicture.enabled = YES;
        _userDisplayName.enabled = YES;
    }
    [self.tableView reloadData];
}

- (void)saveDisplayName {
    // Check whether the display name has been changed
    NSString *displayname = self.userDisplayName.text;
    if ([displayname isEqualToString:currentDisplayName] == NO) {
        // Save display name
        [_activityIndicator startAnimating];
        _userDisplayName.enabled = NO;

         MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        [mxHandler.mxSession.myUser setDisplayName:displayname success:^{
            currentDisplayName = displayname;
            [_activityIndicator stopAnimating];
            _userDisplayName.enabled = YES;
        } failure:^(NSError *error) {
            NSLog(@"Set displayName failed: %@", error);
            [_activityIndicator stopAnimating];
            _userDisplayName.enabled = YES;
            
            //Alert user
            NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
            if (!title) {
                title = @"Display name change failed";
            }
            NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            
            CustomAlert *alert = [[CustomAlert alloc] initWithTitle:title message:msg style:CustomAlertStyleAlert];
            [errorAlerts addObject:alert];
            alert.cancelButtonIndex = [alert addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                [errorAlerts removeObject:alert];
                // Remove change
                self.userDisplayName.text = currentDisplayName;
            }];
            [alert addActionWithTitle:@"Retry" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                [errorAlerts removeObject:alert];
                [self saveDisplayName];
            }];
            [alert showInViewController:self];
        }];
    }
}

- (void)savePicture {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Save picture
    [_activityIndicator startAnimating];
    _userPicture.enabled = NO;
    
    if (uploadedPictureURL == nil) {
        // Upload picture
        [mxHandler.mxRestClient uploadContent:UIImageJPEGRepresentation([self.userPicture imageForState:UIControlStateNormal], 0.5)
                                     mimeType:@"image/jpeg"
                                      timeout:30
                                      success:^(NSString *url) {
                                          // Store uploaded picture url and trigger picture saving
                                          uploadedPictureURL = url;
                                          [self savePicture];
                                      } failure:^(NSError *error) {
                                          NSLog(@"Upload image failed: %@", error);
                                          [_activityIndicator stopAnimating];
                                          _userPicture.enabled = YES;
                                          [self handleErrorDuringPictureSaving:error];
                                      }];
    } else {
        [mxHandler.mxSession.myUser setAvatarUrl:uploadedPictureURL
                                     success:^{
                                         [self updateUserPicture:uploadedPictureURL];
                                         uploadedPictureURL = nil;
                                         [_activityIndicator stopAnimating];
                                         _userPicture.enabled = YES;
                                     } failure:^(NSError *error) {
                                         NSLog(@"Set avatar url failed: %@", error);
                                         [_activityIndicator stopAnimating];
                                         _userPicture.enabled = YES;
                                         [self handleErrorDuringPictureSaving:error];
                                     }];
    }
}

- (void)handleErrorDuringPictureSaving:(NSError*)error {
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title) {
        title = @"Picture change failed";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    CustomAlert *alert = [[CustomAlert alloc] initWithTitle:title message:msg style:CustomAlertStyleAlert];
    [errorAlerts addObject:alert];
    alert.cancelButtonIndex = [alert addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
        [errorAlerts removeObject:alert];
        // Remove change
        uploadedPictureURL = nil;
        [self updateUserPicture:[MatrixHandler sharedHandler].mxSession.myUser.avatarUrl];
    }];
    [alert addActionWithTitle:@"Retry" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
        [errorAlerts removeObject:alert];
        [self savePicture];
    }];
    
    [alert showInViewController:self];
}

- (void)updateUserPicture:(NSString *)avatar_url {
    if (currentPictureURL == nil || [currentPictureURL isEqualToString:avatar_url] == NO) {
        // Cancel previous loader (if any)
        if (imageLoader) {
            [MediaManager cancel:imageLoader];
            imageLoader = nil;
        }
        
        currentPictureURL = [avatar_url isEqual:[NSNull null]] ? nil : avatar_url;
        if (currentPictureURL) {
            // Load user's picture
            imageLoader = [MediaManager loadPicture:currentPictureURL success:^(UIImage *image) {
                [self.userPicture setImage:image forState:UIControlStateNormal];
                [self.userPicture setImage:image forState:UIControlStateHighlighted];
            } failure:^(NSError *error) {
                // Reset picture URL in order to try next time
                currentPictureURL = nil;
            }];
        } else {
            // Set placeholder
            UIImage *image = [UIImage imageNamed:@"default-profile"];
            [self.userPicture setImage:image forState:UIControlStateNormal];
            [self.userPicture setImage:image forState:UIControlStateHighlighted];
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"isInitialSyncDone" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    } else if ([@"isResumeDone" isEqualToString:keyPath]) {
        if ([[MatrixHandler sharedHandler] isResumeDone]) {
            [_activityIndicator stopAnimating];
            _userPicture.enabled = YES;
            _userDisplayName.enabled = YES;
        } else {
            [_activityIndicator startAnimating];
            _userPicture.enabled = NO;
            _userDisplayName.enabled = NO;
        }
    }
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _userPicture) {
        // Open picture gallery
        UIImagePickerController *mediaPicker = [[UIImagePickerController alloc] init];
        mediaPicker.delegate = self;
        mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        mediaPicker.allowsEditing = NO;
        [[AppDelegate theDelegate].masterTabBarController presentMediaPicker:mediaPicker];
    } else if (sender == logoutBtn) {
        [[AppDelegate theDelegate] logout];
    } else if (sender == apnsNotificationsSwitch) {
        [APNSHandler sharedHandler].isActive = apnsNotificationsSwitch.on;
    } else if (sender == inAppNotificationsSwitch) {
        [AppSettings sharedSettings].enableInAppNotifications = inAppNotificationsSwitch.on;
    } else if (sender == allEventsSwitch) {
        [AppSettings sharedSettings].displayAllEvents = allEventsSwitch.on;
    } else if (sender == unsupportedMsgSwitch) {
        [AppSettings sharedSettings].hideUnsupportedMessages = unsupportedMsgSwitch.on;
    } else if (sender == sortMembersSwitch) {
        [AppSettings sharedSettings].sortMembersUsingLastSeenTime = sortMembersSwitch.on;
    }
}

#pragma mark - keyboard

- (void)dismissKeyboard
{
    // Hide the keyboard
    [_userDisplayName resignFirstResponder];
    // Save display name change (if any)
    [self saveDisplayName];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    // "Done" key has been pressed
    [self dismissKeyboard];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if ([APNSHandler sharedHandler].isAvailable) {
            return 2;
        }
        return 1;
    } else if (section == SETTINGS_SECTION_ROOMS_INDEX) {
        return 3;
    } else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        return 1;
    } else if (section == SETTINGS_SECTION_COMMANDS_INDEX) {
        return 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        textView.text = [NSString stringWithFormat:kConfigurationFormatText, mxHandler.homeServerURL, nil, mxHandler.userId, mxHandler.accessToken];
        CGSize contentSize = [textView sizeThatFits:textView.frame.size];
        return contentSize.height + 1;
    } else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        textView.text = kCommandsDescriptionText;
        CGSize contentSize = [textView sizeThatFits:textView.frame.size];
        return contentSize.height + 1;
    }
    
    return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}
- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.font = [UIFont boldSystemFontOfSize:16];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        sectionHeader.text = @" Notifications";
    } else if (section == SETTINGS_SECTION_ROOMS_INDEX) {
        sectionHeader.text = @" Rooms";
    } else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        sectionHeader.text = @" Configuration";
    } else if (section == SETTINGS_SECTION_COMMANDS_INDEX) {
        sectionHeader.text = @" Commands";
    } else {
        sectionHeader = nil;
    }
    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingsTableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        SettingsTableCellWithSwitch *notificationsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
        if (indexPath.row == 0) {
            notificationsCell.settingLabel.text = @"Enable In-App notifications";
            notificationsCell.settingSwitch.on = [[AppSettings sharedSettings] enableInAppNotifications];
            inAppNotificationsSwitch = notificationsCell.settingSwitch;
        } else {
            notificationsCell.settingLabel.text = @"Enable push notifications";
            notificationsCell.settingSwitch.on = [[APNSHandler sharedHandler] isActive];
            apnsNotificationsSwitch = notificationsCell.settingSwitch;
        }
        cell = notificationsCell;
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        SettingsTableCellWithSwitch *roomsSettingCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
        if (indexPath.row == 0) {
            roomsSettingCell.settingLabel.text = @"Display all events";
            roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] displayAllEvents];
            allEventsSwitch = roomsSettingCell.settingSwitch;
        } else if (indexPath.row == 1) {
            roomsSettingCell.settingLabel.text = @"Hide unsupported messages";
            roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] hideUnsupportedMessages];
            unsupportedMsgSwitch = roomsSettingCell.settingSwitch;
        } else {
            roomsSettingCell.settingLabel.text = @"Sort members by last seen time";
            roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] sortMembersUsingLastSeenTime];
            sortMembersSwitch = roomsSettingCell.settingSwitch;
        }
        cell = roomsSettingCell;
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        SettingsTableCellWithTextView *configCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        configCell.settingTextView.text = [NSString stringWithFormat:kConfigurationFormatText, mxHandler.homeServerURL, nil, mxHandler.userId, mxHandler.accessToken];
        cell = configCell;
    } else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX) {
        SettingsTableCellWithTextView *commandsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        commandsCell.settingTextView.text = kCommandsDescriptionText;
        cell = commandsCell;
    }
    
    return cell;
}

# pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (selectedImage) {
        [self.userPicture setImage:selectedImage forState:UIControlStateNormal];
        [self.userPicture setImage:selectedImage forState:UIControlStateHighlighted];
        [self savePicture];
    }
    [self dismissMediaPicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissMediaPicker];
}

- (void)dismissMediaPicker {
    [[AppDelegate theDelegate].masterTabBarController dismissMediaPicker];
}

@end
