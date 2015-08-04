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

#import "AccountDetailsViewController.h"

#import "RageShakeManager.h"

NSString* const kAccountDetailsNotificationRulesUserInfo = @"To configure global notification settings (like rules), go find a webclient and hit Settings > Notifications.";

@interface AccountDetailsViewController()
{
    NSInteger globalNotificationSettingsRowIndex;
    
    // The "Global Notification Settings" button
    UIButton *globalNotifSettingsButton;
}
@end

@implementation AccountDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKRoomMemberListViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)destroy
{
    [super destroy];
    
    globalNotifSettingsButton = nil;
}

#pragma mark - TableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [super tableView:tableView numberOfRowsInSection:section];
    
    // Add one button in notification section to edit global notification settings
    if (section == notificationsSection)
    {
        globalNotificationSettingsRowIndex = count++;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == notificationsSection && indexPath.row == globalNotificationSettingsRowIndex)
    {
        MXKTableViewCellWithButton *globalNotifSettingsBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
        if (!globalNotifSettingsBtnCell)
        {
            globalNotifSettingsBtnCell = [[MXKTableViewCellWithButton alloc] init];
        }
        [globalNotifSettingsBtnCell.mxkButton setTitle:@"Global Notification Settings" forState:UIControlStateNormal];
        [globalNotifSettingsBtnCell.mxkButton setTitle:@"Global Notification Settings" forState:UIControlStateHighlighted];
        [globalNotifSettingsBtnCell.mxkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        globalNotifSettingsButton = globalNotifSettingsBtnCell.mxkButton;
        
        cell = globalNotifSettingsBtnCell;
        
        
//        MXKTableViewCellWithTextView *userInfoCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
//        if (!userInfoCell)
//        {
//            userInfoCell = [[MXKTableViewCellWithTextView alloc] init];
//        }
//        
//        userInfoCell.mxkTextView.text = kAccountDetailsNotificationRulesUserInfo;
//        cell = userInfoCell;
    }
    else
    {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    return cell;
}


#pragma mark - TableView delegate

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (indexPath.section == notificationsSection)
//    {
//        if (indexPath.row == globalNotificationSettingsRowIndex)
//        {
//            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
//            textView.font = [UIFont systemFontOfSize:14];
//            textView.text = kAccountDetailsNotificationRulesUserInfo;
//            CGSize contentSize = [textView sizeThatFits:textView.frame.size];
//            return contentSize.height + 1;
//        }
//    }
//    
//    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
//}

- (void)onButtonPressed:(id)sender
{
    if (sender == globalNotifSettingsButton)
    {
        [self performSegueWithIdentifier:@"showGlobalNotificationSettings" sender:self];
    }
    else
    {
        [super onButtonPressed:sender];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"showGlobalNotificationSettings"])
    {
        MXKNotificationSettingsViewController *notifSettingsViewController = segue.destinationViewController;
        notifSettingsViewController.mxAccount = self.mxAccount;
    }
}

@end
