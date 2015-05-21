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
#import "APNSHandler.h"

#import "ContactManager.h"

#import "SettingsTableViewCell.h"

#define SETTINGS_SECTION_ACCOUNTS_INDEX      0
#define SETTINGS_SECTION_NOTIFICATIONS_INDEX 1
#define SETTINGS_SECTION_CONTACTS_INDEX      2
#define SETTINGS_SECTION_ROOMS_INDEX         3
#define SETTINGS_SECTION_CONFIGURATION_INDEX 4
#define SETTINGS_SECTION_COMMANDS_INDEX      5
#define SETTINGS_SECTION_COUNT               6

#define SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX         0
#define SETTINGS_SECTION_ROOMS_SHOW_REDACTIONS_INDEX            1
#define SETTINGS_SECTION_ROOMS_SHOW_UNSUPPORTED_EVENTS_INDEX    2
#define SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX               3
#define SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX       4
#define SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX             5
#define SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX                6
#define SETTINGS_SECTION_ROOMS_INDEX_COUNT                      7

NSString *const kSettingsAccountCellIdentifier = @"kSettingsAccountCellIdentifier";
NSString *const kSettingsLogoutCellIdentifier = @"kSettingsLogoutCellIdentifier";


NSString* const kUserInfoNotificationRulesText = @"To configure global notification settings (like rules), go find a webclient and hit Settings > Notifications.";
NSString* const kConfigurationFormatText = @"Console version: %@\r\nMatrixKit version: %@\r\nMatrixSDK version: %@\r\n%@";
NSString* const kBuildFormatText = @"Build: %@\r\n";
NSString* const kCommandsDescriptionText = @"The following commands are available in the room chat:\r\n\r\n /nick <display_name>: change your display name\r\n /me <action>: send the action you are doing. /me will be replaced by your display name\r\n /join <room_alias>: join a room\r\n /kick <user_id> [<reason>]: kick the user\r\n /ban <user_id> [<reason>]: ban the user\r\n /unban <user_id>: unban the user\r\n /op <user_id> <power_level>: set user power level\r\n /deop <user_id>: reset user power level to the room default value";

@interface SettingsViewController () {
    
    MXKAccount *selectedAccount;
    
    // Notifications
    UISwitch *apnsNotificationsSwitch;
    UISwitch *inAppNotificationsSwitch;
    // Dynamic rows in the Notifications section
    NSInteger enablePushNotifRowIndex;
    NSInteger enableInAppNotifRowIndex;
    NSInteger userInfoNotifRowIndex;
    
    // Contacts
    UISwitch *contactsSyncSwitch;
    // Country codes management
    NSArray* countryCodes;
    NSString* countryCode;
    NSString* selectedCountryCode;
    BOOL isSelectingCountryCode;
    // Dynamic rows in Contacts section
    NSInteger syncLocalContactsRowIndex;
    NSInteger countryCodeRowIndex;
    
    // Rooms settings
    UISwitch *allEventsSwitch;
    UISwitch *redactionsSwitch;
    UISwitch *unsupportedEventsSwitch;
    UISwitch *sortMembersSwitch;
    UISwitch *displayLeftMembersSwitch;
    SettingsCellWithLabelAndSlider* maxCacheSizeCell;
    NSUInteger minimumCacheSize;
    
    // Keep reference on potential pushed view controller to release it correctly
    id pushedViewController;
}

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Consider the standard settings by default
    _settings = [MXKAppSettings standardAppSettings];
    
    // Initialize the minimum cache size with the current value
    minimumCacheSize = self.minCachesSize;

    // country selection
    NSString *path = [[NSBundle mainBundle] pathForResource:@"countryCodes" ofType:@"plist"];
    countryCodes = [NSArray arrayWithContentsOfFile:path];
    isSelectingCountryCode = NO;
    
    // Setup `MXKRoomMemberListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy {
    [self reset];
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_settings) {
        // Consider the standard settings by default
        _settings = [MXKAppSettings standardAppSettings];
    }
    
    selectedCountryCode = countryCode = [_settings phonebookCountryCode];
    
    // Update the minimum cache size with the current value
    // Dispatch this operation to not freeze the app
    dispatch_async(dispatch_get_main_queue(), ^{
        minimumCacheSize = self.minCachesSize;
    });
    
    // Refresh display
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAPNSHandlerHasBeenUpdated) name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (pushedViewController) {
        // Force the pushed view controller to dispose its resources
        if ([pushedViewController respondsToSelector:@selector(destroy)]) {
            [pushedViewController destroy];
        }
        pushedViewController = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // if country has been updated
    // update the contact phonenumbers
    // and check if they match now to Matrix Users
    if (![countryCode isEqualToString:selectedCountryCode]) {
        
        [_settings setPhonebookCountryCode:selectedCountryCode];
        countryCode = selectedCountryCode;
        
        [[ContactManager sharedManager] internationalizePhoneNumbers:countryCode];
        [[ContactManager sharedManager] fullRefresh];
    }
    
    countryCode = [_settings phonebookCountryCode];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPNSHandlerHasBeenUpdated object:nil];
}

#pragma mark - Internal methods

- (void)onAPNSHandlerHasBeenUpdated {
    // Force table reload to update notifications section
    apnsNotificationsSwitch = nil;
    
    [self.tableView reloadData];
}

- (void)logout {
    [[AppDelegate theDelegate] logout];
}

- (void)reset {
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    selectedAccount = nil;
    
    contactsSyncSwitch = nil;
    
    apnsNotificationsSwitch = nil;
    inAppNotificationsSwitch = nil;
    
    allEventsSwitch = nil;
    unsupportedEventsSwitch = nil;
    sortMembersSwitch = nil;
    displayLeftMembersSwitch = nil;
    maxCacheSizeCell = nil;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    
    if (sender == apnsNotificationsSwitch) {
        [APNSHandler sharedHandler].isActive = apnsNotificationsSwitch.on;
        apnsNotificationsSwitch.enabled = NO;
    } else if (sender == inAppNotificationsSwitch) {
        _settings.enableInAppNotifications = inAppNotificationsSwitch.on;
        [self.tableView reloadData];
    } else if (sender == allEventsSwitch) {
        _settings.showAllEventsInRoomHistory = allEventsSwitch.on;
    } else if (sender == redactionsSwitch) {
        _settings.showRedactionsInRoomHistory = redactionsSwitch.on;
    } else if (sender == unsupportedEventsSwitch) {
        _settings.showUnsupportedEventsInRoomHistory = unsupportedEventsSwitch.on;
    } else if (sender == sortMembersSwitch) {
        _settings.sortRoomMembersUsingLastSeenTime = sortMembersSwitch.on;
    } else if (sender == displayLeftMembersSwitch) {
        _settings.showLeftMembersInRoomMemberList = displayLeftMembersSwitch.on;
    } else if (sender == contactsSyncSwitch) {
    	_settings.syncLocalContacts = contactsSyncSwitch.on;
        isSelectingCountryCode = NO;
        
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
         });
    }
}

- (IBAction)onSliderValueChange:(id)sender {
    if (sender == maxCacheSizeCell.settingSlider) {
        
        UISlider* slider = maxCacheSizeCell.settingSlider;
        
        // check if the upper bounds have been updated
        if (slider.maximumValue != self.maxAllowedCachesSize) {
            slider.maximumValue = self.maxAllowedCachesSize;
        }
        
        // check if the value does not exceed the bounds
        if (slider.value < minimumCacheSize) {
            slider.value = minimumCacheSize;
        }
        
        [self setCurrentMaxCachesSize:slider.value];
        
        maxCacheSizeCell.settingLabel.text = [NSString stringWithFormat:@"Maximum cache size (%@)", [NSByteCountFormatter stringFromByteCount:self.currentMaxCachesSize countStyle:NSByteCountFormatterCountStyleFile]];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    pushedViewController = [segue destinationViewController];
    
    if ([[segue identifier] isEqualToString:@"showAccountDetails"]) {
        
        MXKAccountDetailsViewController *accountViewController = (MXKAccountDetailsViewController *)pushedViewController;
        accountViewController.mxAccount = selectedAccount;
        selectedAccount = nil;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (section == SETTINGS_SECTION_ACCOUNTS_INDEX) {
        count = [[MXKAccountManager sharedManager] accounts].count + 1; // Add one cell in this section to display "logout all" option.
    } else if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        enableInAppNotifRowIndex = enablePushNotifRowIndex = userInfoNotifRowIndex = -1;
        
        if ([APNSHandler sharedHandler].isAvailable) {
            enablePushNotifRowIndex = count++;
        }
        enableInAppNotifRowIndex = count++;
        userInfoNotifRowIndex = count++;
    } else if (section == SETTINGS_SECTION_CONTACTS_INDEX) {
        countryCodeRowIndex = syncLocalContactsRowIndex = -1;

        // init row index
        syncLocalContactsRowIndex = count++;
        if ([_settings syncLocalContacts]) {
            countryCodeRowIndex = count++;
        }
    } else if (section == SETTINGS_SECTION_ROOMS_INDEX) {
        count = SETTINGS_SECTION_ROOMS_INDEX_COUNT;
    } else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        count = 1;
    } else if (section == SETTINGS_SECTION_COMMANDS_INDEX) {
        count = 1;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_SECTION_ACCOUNTS_INDEX) {
        NSArray *accounts = [[MXKAccountManager sharedManager] accounts];
        if (indexPath.row < accounts.count) {
            MXKAccountTableViewCell *accountCell = [[MXKAccountTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsAccountCellIdentifier];
            if (!accountCell) {
                accountCell = [[MXKAccountTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsAccountCellIdentifier];
            }
            
            accountCell.mxAccount = [accounts objectAtIndex:indexPath.row];
            cell = accountCell;
        } else {
            MXKTableViewCellWithButton *logoutBtnCell = [[MXKTableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsLogoutCellIdentifier];
            if (!logoutBtnCell) {
                logoutBtnCell = [[MXKTableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsLogoutCellIdentifier];
            }
            [logoutBtnCell.mxkButton setTitle:@"Logout all accounts" forState:UIControlStateNormal];
            [logoutBtnCell.mxkButton setTitle:@"Logout all accounts" forState:UIControlStateHighlighted];
            [logoutBtnCell.mxkButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
            
            cell = logoutBtnCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == userInfoNotifRowIndex) {
            SettingsCellWithTextView *userInfoCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
            userInfoCell.settingTextView.text = kUserInfoNotificationRulesText;
            cell = userInfoCell;
        } else {
            SettingsCellWithSwitch *notificationsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            if (indexPath.row == enableInAppNotifRowIndex) {
                notificationsCell.settingLabel.text = @"Enable In-App notifications";
                notificationsCell.settingSwitch.on = [_settings enableInAppNotifications];
                inAppNotificationsSwitch = notificationsCell.settingSwitch;
            } else /* enablePushNotifRowIndex */{
                notificationsCell.settingLabel.text = @"Enable push notifications";
                notificationsCell.settingSwitch.on = [[APNSHandler sharedHandler] isActive];
                notificationsCell.settingSwitch.enabled = YES;
                apnsNotificationsSwitch = notificationsCell.settingSwitch;
            }
            cell = notificationsCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX) {
        if (indexPath.row  == syncLocalContactsRowIndex) {
            SettingsCellWithSwitch *contactsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            
            contactsCell.settingLabel.text = @"Sync local contacts";
            contactsCell.settingSwitch.on = [_settings syncLocalContacts];
            contactsSyncSwitch = contactsCell.settingSwitch;
            cell = contactsCell;
        } else if (indexPath.row  == countryCodeRowIndex) {
            
            int index = 0;
            NSString* countryName = @"";
            
            for(NSDictionary* dict in countryCodes) {
                if ([[dict valueForKey:@"id"] isEqualToString:selectedCountryCode]) {
                    countryName = [dict valueForKey:@"country"];
                    break;
                }
                
                index++;
            }
        
            // there is no country code selection
            if (!isSelectingCountryCode) {
                SettingsCellWithLabelAndSubLabel *countryCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndSubLabel" forIndexPath:indexPath];
               
                countryCell.label.text = @"Select your country";
                countryCell.sublabel.text = countryName;
                countryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell = countryCell;
                
            } else {
                // there is a selection in progress
                SettingsCellWithPicker *pickerCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithPicker" forIndexPath:indexPath];
                
                // display a picker
                pickerCell.pickerView.delegate = self;
                pickerCell.pickerView.dataSource = self;
                
                if (countryName.length > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [pickerCell.pickerView selectRow:index inComponent:0 animated:NO];
                    });
                }
                
                cell = pickerCell;
            }
        }
        
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ClearCacheCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ClearCacheCell"];
            }
            cell.textLabel.text = [NSString stringWithFormat:@"Clear Cache (%@)", [NSByteCountFormatter stringFromByteCount:self.cachesSize countStyle:NSByteCountFormatterCountStyleFile]];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor =  [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor;
        } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX) {
            maxCacheSizeCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndSilder" forIndexPath:indexPath];
            maxCacheSizeCell.settingSlider.minimumValue = 0;
            maxCacheSizeCell.settingSlider.maximumValue = self.maxAllowedCachesSize;
            maxCacheSizeCell.settingSlider.value = self.currentMaxCachesSize;
            
            [self onSliderValueChange:maxCacheSizeCell.settingSlider];
            cell = maxCacheSizeCell;
        } else {
            SettingsCellWithSwitch *roomsSettingCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            
            if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Display all events";
                roomsSettingCell.settingSwitch.on = [_settings showAllEventsInRoomHistory];
                allEventsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SHOW_REDACTIONS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Show redactions";
                roomsSettingCell.settingSwitch.on = [_settings showRedactionsInRoomHistory];
                redactionsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SHOW_UNSUPPORTED_EVENTS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Show unsupported events";
                roomsSettingCell.settingSwitch.on = [_settings showUnsupportedEventsInRoomHistory];
                unsupportedEventsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Sort members by last seen time";
                roomsSettingCell.settingSwitch.on = [_settings sortRoomMembersUsingLastSeenTime];
                sortMembersSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Display left members";
                roomsSettingCell.settingSwitch.on = [_settings showLeftMembersInRoomMemberList];
                displayLeftMembersSwitch = roomsSettingCell.settingSwitch;
            }
            
            cell = roomsSettingCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        SettingsCellWithTextView *configurationCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length) {
            build = [NSString stringWithFormat:kBuildFormatText, build];
        }
        configurationCell.settingTextView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixKitVersion, MatrixSDKVersion, build];
        cell = configurationCell;
    } else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX) {
        SettingsCellWithTextView *commandsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        commandsCell.settingTextView.text = kCommandsDescriptionText;
        cell = commandsCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SETTINGS_SECTION_ACCOUNTS_INDEX) {
        return 70;
    } else if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == userInfoNotifRowIndex) {
            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
            textView.font = [UIFont systemFontOfSize:14];
            textView.text = kUserInfoNotificationRulesText;
            CGSize contentSize = [textView sizeThatFits:textView.frame.size];
            return contentSize.height + 1;
        }
    } else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX) {
        
        if ((indexPath.row == countryCodeRowIndex) && isSelectingCountryCode) {
            
            return 164;
        }
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX) {
            return 88;
        }
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length) {
            build = [NSString stringWithFormat:kBuildFormatText, build];
        }
        textView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixKitVersion, MatrixSDKVersion, build];
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
    
    if (section == SETTINGS_SECTION_ACCOUNTS_INDEX) {
        sectionHeader.text = @" Accounts";
    } else if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        sectionHeader.text = @" Notifications";
    } else if (section == SETTINGS_SECTION_CONTACTS_INDEX) {
        sectionHeader.text = @" Contacts";
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

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView == aTableView) {
        if (indexPath.section == SETTINGS_SECTION_ACCOUNTS_INDEX) {
            NSArray *accounts = [[MXKAccountManager sharedManager] accounts];
            if (indexPath.row < accounts.count) {
                selectedAccount = [accounts objectAtIndex:indexPath.row];
                
                [self performSegueWithIdentifier:@"showAccountDetails" sender:self];
            }
        } else if ((indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) && (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX)) {
            // tap on clear application caches
            [[AppDelegate theDelegate] reloadMatrixSessions:YES];
        } else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX) {
            if (indexPath.row == countryCodeRowIndex) {
                isSelectingCountryCode = YES;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }
        }
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [countryCodes count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[countryCodes objectAtIndex:row] valueForKey:@"country"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    // sanity check
    if ((row >= 0) && (row < countryCodes.count)) {
        NSDictionary* dict = [countryCodes objectAtIndex:row];
        selectedCountryCode = [dict valueForKey:@"id"];
    }
    
    isSelectingCountryCode = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Cache handling

// return the MX cache size in bytes
- (NSUInteger) MXCacheSize {
    
    if (self.mxSession.store && [self.mxSession.store isKindOfClass:[MXFileStore class]]) {
        MXFileStore *fileStore = (MXFileStore*)self.mxSession.store;
        return fileStore.diskUsage;
    }
    
    return 0;
}

// return the sum of the caches (MX cache + media cache ...) in bytes
- (NSUInteger) cachesSize {
    return self.MXCacheSize + [MXKMediaManager cacheSize];
}

// defines the min allow cache size in bytes
- (NSUInteger) minCachesSize {
    // add a 50MB margin to avoid cache file deletion
    return self.MXCacheSize + [MXKMediaManager minCacheSize] + 50 * 1024 * 1024;
}

// defines the current max caches size in bytes
- (NSUInteger) currentMaxCachesSize {
    return self.MXCacheSize + [MXKMediaManager currentMaxCacheSize];
}

- (void)setCurrentMaxCachesSize:(NSUInteger)maxCachesSize {
    [MXKMediaManager setCurrentMaxCacheSize:maxCachesSize - self.MXCacheSize];
}

// defines the max allowed caches size in bytes
- (NSUInteger) maxAllowedCachesSize {
    return self.MXCacheSize + [MXKMediaManager maxAllowedCacheSize];
}

@end
