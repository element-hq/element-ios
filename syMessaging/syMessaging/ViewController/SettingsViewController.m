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
#import "MatrixHandler.h"
#import "MediaManager.h"

#import "SettingsTableViewCell.h"

#define SETTINGS_SECTION_NOTIFICATIONS_INDEX 0
#define SETTINGS_SECTION_MESSAGES_INDEX      1
#define SETTINGS_SECTION_CONFIGURATION_INDEX 2
#define SETTINGS_SECTION_COMMANDS_INDEX      3

NSString* const kConfigurationFormatText = @"Home server: %@\r\nIdentity server: %@\r\nUser ID: %@\r\nAccess token: %@";
NSString* const kCommandsDescriptionText = @"The following commands are available in the room chat:\r\n\r\n /nick <display_name>: change your display name\r\n /me <action>: send the action you are doing. /me will be replaced by your display name\r\n /join <room_alias>: join a room\r\n /kick <user_id> [<reason>]: kick the user\r\n /ban <user_id> [<reason>]: ban the user\r\n /unban <user_id>: unban the user\r\n /op <user_id> <power_level>: set user power level\r\n /deop <user_id>: reset user power level to the room default value";

@interface SettingsViewController () {
    id imageLoader;
    
    NSString *currentDisplayName;
    NSString *currentPictureURL;
    BOOL      shouldSavePicture;
    
    UIButton *logoutBtn;
    UISwitch *notificationsSwitch;
    UISwitch *allEventsSwitch;
    
    UIImagePickerController *imagePicker;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIButton *userPicture;
@property (weak, nonatomic) IBOutlet UITextField *userDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
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
    
    [self reset];
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
    // Cancel picture loader (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    
    logoutBtn = nil;
    notificationsSwitch = nil;
    allEventsSwitch = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Ignore viewWillAppear if it is related to the mediaPicker use
    if (imagePicker == nil) {
        // Update User information
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        
        // Handle user's display name
        currentDisplayName = mxHandler.userDisplayName;
        self.userDisplayName.text = mxHandler.userDisplayName;
        [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"userDisplayName" options:0 context:nil];
        [mxHandler.mxSession displayName:mxHandler.mxSession.user_id success:^(NSString *displayname) {
            mxHandler.userDisplayName = displayname;
        } failure:^(NSError *error) {
            NSLog(@"Get displayName failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        
        // Handle user's picture url
        [self updateUserPicture:mxHandler.userPictureURL];
        [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"userPictureURL" options:0 context:nil];
        [mxHandler.mxSession avatarUrl:mxHandler.mxSession.user_id success:^(NSString *avatar_url) {
            mxHandler.userPictureURL = avatar_url;
        } failure:^(NSError *error) {
            NSLog(@"Get picture url failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        
        // Refresh settings
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Ignore viewWillDisappear if it is related to the mediaPicker use
    if (imagePicker == nil) {
        [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"userDisplayName"];
        [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"userPictureURL"];
        
        shouldSavePicture = NO;
    }
}

#pragma mark - Internal methods

- (void)save {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Start saving
    [_activityIndicator startAnimating];
    _saveBtn.enabled = NO;
    _saveBtn.alpha = 0.5;
    
    // Check whether the display name has been changed
    NSString *displayname = self.userDisplayName.text;
    if ([displayname isEqualToString:currentDisplayName] == NO) {
        // Save display name
        [mxHandler.mxSession setDisplayName:displayname success:^{
            currentDisplayName = displayname;
            // Loop to save other changes
            [self save];
        } failure:^(NSError *error) {
            // Stop saving
            [_activityIndicator stopAnimating];
            _saveBtn.enabled = YES;
            _saveBtn.alpha = 1;
            
            NSLog(@"Set displayName failed: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
        // Wait for the end of this request before pursuing the saving
        return;
    }
    
    // Check whether the picture has been changed
    if (shouldSavePicture) {
        [mxHandler.mxSession uploadContent:UIImageJPEGRepresentation([self.userPicture imageForState:UIControlStateNormal], 0.5)
                                  mimeType:@"image/jpeg"
                                   timeout:30
                                   success:^(NSString *url) {
                                       [mxHandler.mxSession setAvatarUrl:url
                                                                 success:^{
                                                                     shouldSavePicture = NO;
                                                                     [MatrixHandler sharedHandler].userPictureURL = url;
                                                                     // Loop to save other changes
                                                                     [self save];
                                                                 } failure:^(NSError *error) {
                                                                     // Stop saving
                                                                     [_activityIndicator stopAnimating];
                                                                     _saveBtn.enabled = YES;
                                                                     _saveBtn.alpha = 1;
                                                                     
                                                                     NSLog(@"Set avatar url failed: %@", error);
                                                                     //Alert user
                                                                     [[AppDelegate theDelegate] showErrorAsAlert:error];
                                                                 }];
                                       
                                   } failure:^(NSError *error) {
                                       // Stop saving
                                       [_activityIndicator stopAnimating];
                                       _saveBtn.enabled = YES;
                                       _saveBtn.alpha = 1;
                                       
                                       NSLog(@"Upload image failed: %@", error);
                                       //Alert user
                                       [[AppDelegate theDelegate] showErrorAsAlert:error];
                                   }];
        // Wait for the end of this request before pursuing the saving
        return;
    }
    
    // Stop saving
    [_activityIndicator stopAnimating];
    _saveBtn.enabled = YES;
    _saveBtn.alpha = 1;
}

- (void)reset {
    // Cancel picture loader (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    
    currentPictureURL = nil;
    UIImage *image = [UIImage imageNamed:@"default-profile"];
    [self.userPicture setImage:image forState:UIControlStateNormal];
    [self.userPicture setImage:image forState:UIControlStateHighlighted];
    
    currentDisplayName = nil;
    self.userDisplayName.text = nil;
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
    if ([@"userDisplayName" isEqualToString:keyPath]) {
        // Refresh user's display name
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        if ([currentDisplayName isEqualToString:mxHandler.userDisplayName] == NO) {
            currentDisplayName = mxHandler.userDisplayName;
            self.userDisplayName.text = mxHandler.userDisplayName;
        }
    } else if ([@"userPictureURL" isEqualToString:keyPath]) {
        // Refresh user's picture
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        [self updateUserPicture:mxHandler.userPictureURL];
    }
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _userPicture) {
        // Open picture gallery
        imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.allowsEditing = NO;
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else if (sender == _saveBtn) {
        [self save];
    } else if (sender == logoutBtn) {
        [self reset];
        [[AppDelegate theDelegate] logout];
    } else if (sender == notificationsSwitch) {
        [AppSettings sharedSettings].enableNotifications = notificationsSwitch.on;
    } else if (sender == allEventsSwitch) {
        [AppSettings sharedSettings].displayAllEvents = allEventsSwitch.on;
    }
}

#pragma mark - keyboard

- (void)dismissKeyboard
{
    // Hide the keyboard
    [_userDisplayName resignFirstResponder];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    // "Done" key has been pressed
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        return 1;
    } else if (section == SETTINGS_SECTION_MESSAGES_INDEX) {
        return 1;
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
    } else if (indexPath.section == SETTINGS_SECTION_MESSAGES_INDEX) {
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.font = [UIFont boldSystemFontOfSize:16];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        sectionHeader.text = @" Notifications";
    } else if (section == SETTINGS_SECTION_MESSAGES_INDEX) {
        sectionHeader.text = @" Messages";
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
        notificationsCell.settingLabel.text = @"Enable notifications";
        notificationsCell.settingSwitch.on = [[AppSettings sharedSettings] enableNotifications];
        notificationsSwitch = notificationsCell.settingSwitch;
        cell = notificationsCell;
    } else if (indexPath.section == SETTINGS_SECTION_MESSAGES_INDEX) {
        SettingsTableCellWithSwitch *allEventsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
        allEventsCell.settingLabel.text = @"Display all events";
        allEventsCell.settingSwitch.on = [[AppSettings sharedSettings] displayAllEvents];
        allEventsSwitch = allEventsCell.settingSwitch;
        cell = allEventsCell;
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
        shouldSavePicture = YES;
    }
    [self dismissMediaPicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissMediaPicker];
}

- (void)dismissMediaPicker {
    if (imagePicker) {
        [self dismissViewControllerAnimated:NO completion:nil];
        imagePicker.delegate = nil;
        imagePicker = nil;
    }
}

@end
