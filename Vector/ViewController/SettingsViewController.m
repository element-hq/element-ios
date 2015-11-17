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
#define SETTINGS_SECTION_CONFIGURATION_INDEX 1
#define SETTINGS_SECTION_COUNT               2

@interface SettingsViewController ()
{
    MXKAccount *selectedAccount;
    id removedAccountObserver;
    id accountUserInfoObserver;
    
    UIButton *clearCacheButton;
}

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKRoomMemberListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Add observer to handle removed accounts
    removedAccountObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountManagerDidRemoveAccountNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXKAccount *account = notif.object;
        if (account)
        {
            if (self.childViewControllers.count)
            {
                for (id viewController in self.childViewControllers)
                {
                    // Check whether details of this account was displayed
                    if ([viewController isKindOfClass:[MXKAccountDetailsViewController class]])
                    {
                        MXKAccountDetailsViewController *accountDetailsViewController = viewController;
                        if ([accountDetailsViewController.mxAccount.mxCredentials.userId isEqualToString:account.mxCredentials.userId])
                        {
                            // pop the account details view controller
                            [self.navigationController popToRootViewControllerAnimated:YES];
                            break;
                        }
                    }
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

    // Add each matrix session, to update the view controller appearance according to mx sessions state
    // FIXME GFO We should observe added/removed matrix sessions during view controller use.
    NSArray *sessions = [AppDelegate theDelegate].mxSessions;
    for (MXSession *mxSession in sessions)
    {
        [self addMatrixSession:mxSession];
    }
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
    
    // Refresh display
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    // Logout all matrix account
    [[MXKAccountManager sharedManager] logout];
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == clearCacheButton)
    {
        [[AppDelegate theDelegate] reloadMatrixSessions:YES];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"showAccountDetails"])
    {
        MXKAccountDetailsViewController *accountViewController = segue.destinationViewController;
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
    else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        count = 2;
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
            MXKAccountTableViewCell *accountCell = [tableView dequeueReusableCellWithIdentifier:[MXKAccountTableViewCell defaultReuseIdentifier]];
            if (!accountCell)
            {
                accountCell = [[MXKAccountTableViewCell alloc] init];
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
            MXKTableViewCellWithButton *logoutBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!logoutBtnCell)
            {
                logoutBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            [logoutBtnCell.mxkButton setTitle:NSLocalizedStringFromTable(@"account_logout_all", @"Vector", nil) forState:UIControlStateNormal];
            [logoutBtnCell.mxkButton setTitle:NSLocalizedStringFromTable(@"account_logout_all", @"Vector", nil) forState:UIControlStateHighlighted];
            
            [logoutBtnCell.mxkButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [logoutBtnCell.mxkButton addTarget:self action:@selector(logout:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = logoutBtnCell;
        }
    }
    else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        if (indexPath.row == 0)
        {
            MXKTableViewCellWithTextView *configurationCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
            if (!configurationCell)
            {
                configurationCell = [[MXKTableViewCellWithTextView alloc] init];
            }
            
            NSString* appVersion = [AppDelegate theDelegate].appVersion;
            NSString* build = [AppDelegate theDelegate].build;
            if (build.length)
            {
                build = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_config_build_number", @"Vector", nil), build];
            }
            NSString *configurationFormatText = [NSString stringWithFormat:@"%@\n%@\n%@\n%@", NSLocalizedStringFromTable(@"settings_config_ios_console_version", @"Vector", nil), NSLocalizedStringFromTable(@"settings_config_ios_kit_version", @"Vector", nil), NSLocalizedStringFromTable(@"settings_config_ios_sdk_version", @"Vector", nil), @"%@"];
            configurationCell.mxkTextView.text = [NSString stringWithFormat:configurationFormatText, appVersion, MatrixKitVersion, MatrixSDKVersion, build];
            cell = configurationCell;
        }
        else if (indexPath.row == 1)
        {
            MXKTableViewCellWithButton *clearCacheBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!clearCacheBtnCell)
            {
                clearCacheBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            
            NSString *btnTitle = [NSString stringWithFormat:@"%@", NSLocalizedStringFromTable(@"settings_clear_cache", @"Vector", nil)];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
            [clearCacheBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
            
            clearCacheButton = clearCacheBtnCell.mxkButton;
            
            [clearCacheButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [clearCacheButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = clearCacheBtnCell;
        }
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
    else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX && indexPath.row == 0)
    {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length)
        {
            build = [NSString stringWithFormat:NSLocalizedStringFromTable(@"settings_config_build_number", @"Vector", nil), build];
        }
        NSString *configurationFormatText = [NSString stringWithFormat:@"%@\n%@\n%@\n%@", NSLocalizedStringFromTable(@"settings_config_ios_console_version", @"Vector", nil), NSLocalizedStringFromTable(@"settings_config_ios_kit_version", @"Vector", nil), NSLocalizedStringFromTable(@"settings_config_ios_sdk_version", @"Vector", nil), @"%@"];
        textView.text = [NSString stringWithFormat:configurationFormatText, appVersion, MatrixKitVersion, MatrixSDKVersion, build];
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
        sectionLabel.text = NSLocalizedStringFromTable(@"accounts", @"Vector", nil);
        
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
    else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX)
    {
        sectionLabel.text = NSLocalizedStringFromTable(@"settings_title_config", @"Vector", nil);
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
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
