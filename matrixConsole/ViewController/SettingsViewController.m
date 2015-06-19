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

#define SETTINGS_SECTION_ACCOUNTS_INDEX      0
#define SETTINGS_SECTION_CONTACTS_INDEX      1
#define SETTINGS_SECTION_ROOMS_INDEX         2
#define SETTINGS_SECTION_CONFIGURATION_INDEX 3
#define SETTINGS_SECTION_COMMANDS_INDEX      4
#define SETTINGS_SECTION_COUNT               5

#define SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX         0
#define SETTINGS_SECTION_ROOMS_SHOW_REDACTIONS_INDEX            1
#define SETTINGS_SECTION_ROOMS_SHOW_UNSUPPORTED_EVENTS_INDEX    2
#define SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX               3
#define SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX       4
#define SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX             5
#define SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX                6
#define SETTINGS_SECTION_ROOMS_INDEX_COUNT                      7

NSString *const kSettingsAccountCellIdentifier = @"kSettingsAccountCellIdentifier";
NSString *const kSettingsButtonCellIdentifier = @"kSettingsButtonCellIdentifier";
NSString *const kSettingsUserInfoCellIdentifier = @"kSettingsUserInfoCellIdentifier";
NSString *const kSettingsSwitchCellIdentifier = @"kSettingsSwitchCellIdentifier";
NSString *const kSettingsCountryCellIdentifier = @"kSettingsCountryCellIdentifier";
NSString *const kSettingsPickerCellIdentifier = @"kSettingsPickerCellIdentifier";
NSString *const kSettingsSliderCellIdentifier = @"kSettingsSliderCellIdentifier";

NSString* const kConfigurationFormatText = @"Console version: %@\r\nMatrixKit version: %@\r\nMatrixSDK version: %@\r\n%@";
NSString* const kBuildFormatText = @"Build: %@";
NSString* const kCommandsDescriptionText = @"The following commands are available in the room chat:\r\n\r\n /nick <display_name>: change your display name\r\n /me <action>: send the action you are doing. /me will be replaced by your display name\r\n /join <room_alias>: join a room\r\n /kick <user_id> [<reason>]: kick the user\r\n /ban <user_id> [<reason>]: ban the user\r\n /unban <user_id>: unban the user\r\n /op <user_id> <power_level>: set user power level\r\n /deop <user_id>: reset user power level to the room default value";

@interface SettingsViewController ()
{
    MXKAccount *selectedAccount;
    id removedAccountObserver;
    id accountUserInfoObserver;
    
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
    MXKTableViewCellWithLabelAndSlider* maxCacheSizeCell;
    NSUInteger minimumCacheSize;
    UIButton *clearCacheButton;
    
    // Keep reference on potential pushed view controller to release it correctly
    id pushedViewController;
}

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
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
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXKAccount *account = notif.object;
        if (account)
        {
            // Check whether details of this account was displayed
            if ([pushedViewController isKindOfClass:[MXKAccountDetailsViewController class]])
            {
                MXKAccountDetailsViewController *accountDetailsViewController = (MXKAccountDetailsViewController*)pushedViewController;
                if ([accountDetailsViewController.mxAccount.mxCredentials.userId isEqualToString:account.mxCredentials.userId])
                {
                    // pop the account details view controller
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
        }
        
        // Refresh table to remove this account
        [self.tableView reloadData];
    }];
    
    // Add observer to handle accounts update
    accountUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountUserInfoDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        // Refresh table to remove this account
        [self.tableView reloadData];
    }];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_settings)
    {
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (pushedViewController)
    {
        // Force the pushed view controller to dispose its resources
        if ([pushedViewController respondsToSelector:@selector(destroy)])
        {
            [pushedViewController destroy];
        }
        pushedViewController = nil;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // if country has been updated
    // update the contact phonenumbers
    // and check if they match now to Matrix Users
    if (![countryCode isEqualToString:selectedCountryCode])
    {
        
        [_settings setPhonebookCountryCode:selectedCountryCode];
        countryCode = selectedCountryCode;
    }
    
    countryCode = [_settings phonebookCountryCode];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    selectedAccount = nil;
    
    contactsSyncSwitch = nil;
    
    allEventsSwitch = nil;
    redactionsSwitch = nil;
    unsupportedEventsSwitch = nil;
    sortMembersSwitch = nil;
    displayLeftMembersSwitch = nil;
    maxCacheSizeCell = nil;
    clearCacheButton = nil;
}

- (IBAction)onAccountToggleChange:(id)sender
{
    UISwitch *accountSwitchToggle = sender;
    
    NSArray *accounts = [[MXKAccountManager sharedManager] accounts];
    if (accountSwitchToggle.tag < accounts.count)
    {
        MXKAccount *account = [accounts objectAtIndex:accountSwitchToggle.tag];
        account.disabled = !accountSwitchToggle.on;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Actions

- (IBAction)addAccount:(id)sender
{
    [self performSegueWithIdentifier:@"addAccount" sender:self];
}

- (IBAction)logout:(id)sender
{
    [[AppDelegate theDelegate] logout];
}

- (IBAction)onButtonPressed:(id)sender
{
    
    if (sender == allEventsSwitch)
    {
        _settings.showAllEventsInRoomHistory = allEventsSwitch.on;
    }
    else if (sender == redactionsSwitch)
    {
        _settings.showRedactionsInRoomHistory = redactionsSwitch.on;
    }
    else if (sender == unsupportedEventsSwitch)
    {
        _settings.showUnsupportedEventsInRoomHistory = unsupportedEventsSwitch.on;
    }
    else if (sender == sortMembersSwitch)
    {
        _settings.sortRoomMembersUsingLastSeenTime = sortMembersSwitch.on;
    }
    else if (sender == displayLeftMembersSwitch)
    {
        _settings.showLeftMembersInRoomMemberList = displayLeftMembersSwitch.on;
    }
    else if (sender == contactsSyncSwitch)
    {
        _settings.syncLocalContacts = contactsSyncSwitch.on;
        isSelectingCountryCode = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else if (sender == clearCacheButton)
    {
        [[AppDelegate theDelegate] reloadMatrixSessions:YES];
    }
}

- (IBAction)onSliderValueChange:(id)sender
{
    if (sender == maxCacheSizeCell.mxkSlider)
    {
        
        UISlider* slider = maxCacheSizeCell.mxkSlider;
        
        // check if the upper bounds have been updated
        if (slider.maximumValue != self.maxAllowedCachesSize)
        {
            slider.maximumValue = self.maxAllowedCachesSize;
        }
        
        // check if the value does not exceed the bounds
        if (slider.value < minimumCacheSize)
        {
            slider.value = minimumCacheSize;
        }
        
        [self setCurrentMaxCachesSize:slider.value];
        
        maxCacheSizeCell.mxkLabel.text = [NSString stringWithFormat:@"Maximum cache size (%@)", [NSByteCountFormatter stringFromByteCount:self.currentMaxCachesSize countStyle:NSByteCountFormatterCountStyleFile]];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    pushedViewController = [segue destinationViewController];
    
    if ([[segue identifier] isEqualToString:@"showAccountDetails"])
    {
        
        MXKAccountDetailsViewController *accountViewController = (MXKAccountDetailsViewController *)pushedViewController;
        accountViewController.mxAccount = selectedAccount;
        selectedAccount = nil;
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == SETTINGS_SECTION_ACCOUNTS_INDEX)
    {
        count = [[MXKAccountManager sharedManager] accounts].count + 1; // Add one cell in this section to display "logout all" option.
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        countryCodeRowIndex = syncLocalContactsRowIndex = -1;
        
        // init row index
        syncLocalContactsRowIndex = count++;
        if ([_settings syncLocalContacts])
        {
            countryCodeRowIndex = count++;
        }
    }
    else if (section == SETTINGS_SECTION_ROOMS_INDEX)
    {
        count = SETTINGS_SECTION_ROOMS_INDEX_COUNT;
    }
    else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        count = 1;
    }
    else if (section == SETTINGS_SECTION_COMMANDS_INDEX)
    {
        count = 1;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_SECTION_ACCOUNTS_INDEX)
    {
        NSArray *accounts = [[MXKAccountManager sharedManager] accounts];
        if (indexPath.row < accounts.count)
        {
            MXKAccountTableViewCell *accountCell = [[MXKAccountTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsAccountCellIdentifier];
            if (!accountCell)
            {
                accountCell = [[MXKAccountTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsAccountCellIdentifier];
            }
            
            accountCell.mxAccount = [accounts objectAtIndex:indexPath.row];
            
            // Display switch toggle in case of multiple accounts
            if (accounts.count > 1 || accountCell.mxAccount.disabled)
            {
                accountCell.accountSwitchToggle.tag = indexPath.row;
                accountCell.accountSwitchToggle.hidden = NO;
                [accountCell.accountSwitchToggle addTarget:self action:@selector(onAccountToggleChange:) forControlEvents:UIControlEventValueChanged];
            }
            
            cell = accountCell;
        }
        else
        {
            MXKTableViewCellWithButton *logoutBtnCell = [[MXKTableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsButtonCellIdentifier];
            if (!logoutBtnCell)
            {
                logoutBtnCell = [[MXKTableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsButtonCellIdentifier];
            }
            [logoutBtnCell.mxkButton setTitle:@"Logout all accounts" forState:UIControlStateNormal];
            [logoutBtnCell.mxkButton setTitle:@"Logout all accounts" forState:UIControlStateHighlighted];
            [logoutBtnCell.mxkButton addTarget:self action:@selector(logout:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = logoutBtnCell;
        }
    }
    else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        if (indexPath.row  == syncLocalContactsRowIndex)
        {
            MXKTableViewCellWithLabelAndSwitch *contactsCell = [[MXKTableViewCellWithLabelAndSwitch alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsSwitchCellIdentifier];
            if (!contactsCell)
            {
                contactsCell = [[MXKTableViewCellWithLabelAndSwitch alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsSwitchCellIdentifier];
            }
            
            [contactsCell.mxkSwitch addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventValueChanged];
            
            contactsCell.mxkLabel.text = @"Sync local contacts";
            contactsCell.mxkSwitch.on = [_settings syncLocalContacts];
            contactsSyncSwitch = contactsCell.mxkSwitch;
            cell = contactsCell;
        }
        else if (indexPath.row  == countryCodeRowIndex)
        {
            int index = 0;
            NSString* countryName = @"";
            
            for(NSDictionary* dict in countryCodes)
            {
                if ([[dict valueForKey:@"id"] isEqualToString:selectedCountryCode])
                {
                    countryName = [dict valueForKey:@"country"];
                    break;
                }
                
                index++;
            }
            
            // there is no country code selection
            if (!isSelectingCountryCode)
            {
                MXKTableViewCellWithLabelAndSubLabel *countryCell = [[MXKTableViewCellWithLabelAndSubLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsCountryCellIdentifier];
                if (!countryCell)
                {
                    countryCell = [[MXKTableViewCellWithLabelAndSubLabel alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsCountryCellIdentifier];
                }
                
                countryCell.mxkLabel.text = @"Select your country";
                countryCell.mxkSublabel.text = countryName;
                countryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell = countryCell;
                
            }
            else
            {
                // there is a selection in progress
                MXKTableViewCellWithPicker *pickerCell = [[MXKTableViewCellWithPicker alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsPickerCellIdentifier];
                if (!pickerCell)
                {
                    pickerCell = [[MXKTableViewCellWithPicker alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsPickerCellIdentifier];
                }
                
                // display a picker
                pickerCell.mxkPickerView.delegate = self;
                pickerCell.mxkPickerView.dataSource = self;
                
                if (countryName.length > 0)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [pickerCell.mxkPickerView selectRow:index inComponent:0 animated:NO];
                    });
                }
                
                cell = pickerCell;
            }
        }
        
    }
    else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX)
    {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX)
        {
            MXKTableViewCellWithButton *clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsButtonCellIdentifier];
            if (!clearCacheBtnCell)
            {
                clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsButtonCellIdentifier];
            }
            
            NSString *btnTitle = [NSString stringWithFormat:@"Clear Cache (%@)", [NSByteCountFormatter stringFromByteCount:self.cachesSize countStyle:NSByteCountFormatterCountStyleFile]];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            
            clearCacheButton = clearCacheBtnCell.mxkButton;
            [clearCacheBtnCell.mxkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = clearCacheBtnCell;
        }
        else if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX)
        {
            maxCacheSizeCell = [[MXKTableViewCellWithLabelAndSlider alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsSliderCellIdentifier];
            if (!maxCacheSizeCell)
            {
                maxCacheSizeCell = [[MXKTableViewCellWithLabelAndSlider alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsSliderCellIdentifier];
            }
            
            maxCacheSizeCell.mxkSlider.minimumValue = 0;
            maxCacheSizeCell.mxkSlider.maximumValue = self.maxAllowedCachesSize;
            maxCacheSizeCell.mxkSlider.value = self.currentMaxCachesSize;
            
            [self onSliderValueChange:maxCacheSizeCell.mxkSlider];
            cell = maxCacheSizeCell;
        }
        else
        {
            MXKTableViewCellWithLabelAndSwitch *roomsSettingCell = [[MXKTableViewCellWithLabelAndSwitch alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsSwitchCellIdentifier];
            if (!roomsSettingCell)
            {
                roomsSettingCell = [[MXKTableViewCellWithLabelAndSwitch alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsSwitchCellIdentifier];
            }
            
            [roomsSettingCell.mxkSwitch addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventValueChanged];
            
            if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX)
            {
                roomsSettingCell.mxkLabel.text = @"Display all events";
                roomsSettingCell.mxkSwitch.on = [_settings showAllEventsInRoomHistory];
                allEventsSwitch = roomsSettingCell.mxkSwitch;
            }
            else if (indexPath.row == SETTINGS_SECTION_ROOMS_SHOW_REDACTIONS_INDEX)
            {
                roomsSettingCell.mxkLabel.text = @"Show redactions";
                roomsSettingCell.mxkSwitch.on = [_settings showRedactionsInRoomHistory];
                redactionsSwitch = roomsSettingCell.mxkSwitch;
            }
            else if (indexPath.row == SETTINGS_SECTION_ROOMS_SHOW_UNSUPPORTED_EVENTS_INDEX)
            {
                roomsSettingCell.mxkLabel.text = @"Show unsupported events";
                roomsSettingCell.mxkSwitch.on = [_settings showUnsupportedEventsInRoomHistory];
                unsupportedEventsSwitch = roomsSettingCell.mxkSwitch;
            }
            else if (indexPath.row == SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX)
            {
                roomsSettingCell.mxkLabel.text = @"Sort members by last seen time";
                roomsSettingCell.mxkSwitch.on = [_settings sortRoomMembersUsingLastSeenTime];
                sortMembersSwitch = roomsSettingCell.mxkSwitch;
            }
            else if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX)
            {
                roomsSettingCell.mxkLabel.text = @"Display left members";
                roomsSettingCell.mxkSwitch.on = [_settings showLeftMembersInRoomMemberList];
                displayLeftMembersSwitch = roomsSettingCell.mxkSwitch;
            }
            
            cell = roomsSettingCell;
        }
    }
    else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        MXKTableViewCellWithTextView *configurationCell = [[MXKTableViewCellWithTextView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsUserInfoCellIdentifier];
        if (!configurationCell)
        {
            configurationCell = [[MXKTableViewCellWithTextView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsUserInfoCellIdentifier];
        }
        
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length)
        {
            build = [NSString stringWithFormat:kBuildFormatText, build];
        }
        configurationCell.mxkTextView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixKitVersion, MatrixSDKVersion, build];
        cell = configurationCell;
    }
    else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX)
    {
        MXKTableViewCellWithTextView *commandsCell = [[MXKTableViewCellWithTextView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsUserInfoCellIdentifier];
        if (!commandsCell)
        {
            commandsCell = [[MXKTableViewCellWithTextView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSettingsUserInfoCellIdentifier];
        }
        
        commandsCell.mxkTextView.text = kCommandsDescriptionText;
        cell = commandsCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SETTINGS_SECTION_ACCOUNTS_INDEX)
    {
        return 50;
    }
    else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        
        if ((indexPath.row == countryCodeRowIndex) && isSelectingCountryCode)
        {
            
            return 164;
        }
    }
    else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX)
    {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX)
        {
            return 88;
        }
    }
    else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length)
        {
            build = [NSString stringWithFormat:kBuildFormatText, build];
        }
        textView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixKitVersion, MatrixSDKVersion, build];
        CGSize contentSize = [textView sizeThatFits:textView.frame.size];
        return contentSize.height + 1;
    }
    else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX)
    {
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
    UIView *sectionHeader = [[UIView alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, sectionHeader.frame.size.width - 10, sectionHeader.frame.size.height - 10)];
    sectionLabel.font = [UIFont boldSystemFontOfSize:16];
    sectionLabel.backgroundColor = [UIColor clearColor];
    [sectionHeader addSubview:sectionLabel];
    
    if (section == SETTINGS_SECTION_ACCOUNTS_INDEX)
    {
        sectionLabel.text = @"Accounts";
        
        UIButton *addAccount = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [addAccount addTarget:self action:@selector(addAccount:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect frame = addAccount.frame;
        frame.origin.x = sectionHeader.frame.size.width - frame.size.width - 8;
        frame.origin.y = (sectionHeader.frame.size.height - frame.size.height) / 2;
        addAccount.frame = frame;
        
        [sectionHeader addSubview:addAccount];
        addAccount.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
        
        sectionHeader.userInteractionEnabled = YES;
    }
    else if (section == SETTINGS_SECTION_CONTACTS_INDEX)
    {
        sectionLabel.text = @"Contacts";
    }
    else if (section == SETTINGS_SECTION_ROOMS_INDEX)
    {
        sectionLabel.text = @"Rooms";
    }
    else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        sectionLabel.text = @"Configuration";
    }
    else if (section == SETTINGS_SECTION_COMMANDS_INDEX)
    {
        sectionLabel.text = @"Commands";
    }
    else
    {
        sectionHeader = nil;
    }
    return sectionHeader;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        if (indexPath.section == SETTINGS_SECTION_ACCOUNTS_INDEX)
        {
            NSArray *accounts = [[MXKAccountManager sharedManager] accounts];
            if (indexPath.row < accounts.count)
            {
                selectedAccount = [accounts objectAtIndex:indexPath.row];
                
                [self performSegueWithIdentifier:@"showAccountDetails" sender:self];
            }
        }
        else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX)
        {
            if (indexPath.row == countryCodeRowIndex)
            {
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

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [countryCodes count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[countryCodes objectAtIndex:row] valueForKey:@"country"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // sanity check
    if ((row >= 0) && (row < countryCodes.count))
    {
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
- (NSUInteger)MXCacheSize
{
    NSUInteger cacheSize = 0;
    
    NSArray *mxSessions = self.mxSessions;
    for (MXSession *mxSession in mxSessions)
    {
        if (mxSession.store && [mxSession.store isKindOfClass:[MXFileStore class]])
        {
            MXFileStore *fileStore = (MXFileStore*)mxSession.store;
            cacheSize += fileStore.diskUsage;
        }
    }
    
    return cacheSize;
}

// return the sum of the caches (MX cache + media cache ...) in bytes
- (NSUInteger)cachesSize
{
    return self.MXCacheSize + [MXKMediaManager cacheSize];
}

// defines the min allow cache size in bytes
- (NSUInteger)minCachesSize
{
    // add a 50MB margin to avoid cache file deletion
    return self.MXCacheSize + [MXKMediaManager minCacheSize] + 50 * 1024 * 1024;
}

// defines the current max caches size in bytes
- (NSUInteger)currentMaxCachesSize
{
    return self.MXCacheSize + [MXKMediaManager currentMaxCacheSize];
}

- (void)setCurrentMaxCachesSize:(NSUInteger)maxCachesSize
{
    [MXKMediaManager setCurrentMaxCacheSize:maxCachesSize - self.MXCacheSize];
}

// defines the max allowed caches size in bytes
- (NSUInteger) maxAllowedCachesSize
{
    return self.MXCacheSize + [MXKMediaManager maxAllowedCacheSize];
}

@end
