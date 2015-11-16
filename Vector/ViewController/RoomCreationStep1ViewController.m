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

#import "RoomCreationStep1ViewController.h"
#import "RoomCreationStep2ViewController.h"

#import "RageShakeManager.h"

#import "NSBundle+MatrixKit.h"

#import "AppDelegate.h"

@interface RoomCreationStep1ViewController ()
{
    MXKRoomCreationInputs *inputs;
    
    // Account
    NSInteger accountSection;
    id accountUserInfoObserver;
    BOOL      isAccountListShrinked;
    
    // Appearance
    NSInteger appearanceSection;
    UITextField *roomNameTextField;
    
    // Privacy
    NSInteger privacySection;
    UIButton *switchPrivacyButton;
    MXKAlert *privacyAlert;
}

@end

@implementation RoomCreationStep1ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Setup `MXKViewControllerHandling` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    inputs = [[MXKRoomCreationInputs alloc] init];
    
    self.navigationItem.title = NSLocalizedStringFromTable(@"room_creation_title", @"Vector", nil);
    
    self.navigationItem.leftBarButtonItem.target = self;
    self.navigationItem.leftBarButtonItem.action = @selector(onButtonPressed:);
    
    self.navigationItem.rightBarButtonItem.title = NSLocalizedStringFromTable(@"next", @"Vector", nil);
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // Add each matrix session, to update the view controller appearance according to mx sessions state
    NSArray *sessions = [AppDelegate theDelegate].masterTabBarController.mxSessions;
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
    if (accountUserInfoObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:accountUserInfoObserver];
        accountUserInfoObserver = nil;
    }
    
    roomNameTextField = nil;
    switchPrivacyButton = nil;
    [privacyAlert dismiss:NO];
    
    inputs = nil;
    
    [super destroy];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Add observer to handle accounts update
    accountUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountUserInfoDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        if (accountSection != -1)
        {
            // Refresh account section
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (accountSection, 1)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        }
        
    }];
    
    // Refresh display
    isAccountListShrinked = YES;
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (accountUserInfoObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:accountUserInfoObserver];
        accountUserInfoObserver = nil;
    }
}

#pragma mark - Internal methods

- (void)dismissKeyboard
{
    [roomNameTextField resignFirstResponder];
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    [self dismissKeyboard];
    
    if (sender == switchPrivacyButton)
    {
        if (inputs.roomVisibility == kMXRoomVisibilityPrivate)
        {
            __weak typeof(self) weakSelf = self;
            
            privacyAlert = [[MXKAlert alloc] initWithTitle:NSLocalizedStringFromTable(@"room_creation_make_public_prompt_title", @"Vector", nil) message:NSLocalizedStringFromTable(@"room_creation_make_public_prompt_msg", @"Vector", nil) style:MXKAlertStyleAlert];
            
            privacyAlert.cancelButtonIndex = [privacyAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_creation_keep_private", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->privacyAlert = nil;
            }];
            
            [privacyAlert addActionWithTitle:NSLocalizedStringFromTable(@"room_creation_make_public", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                strongSelf->privacyAlert = nil;
                
                strongSelf->inputs.roomVisibility = kMXRoomVisibilityPublic;
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (strongSelf->privacySection, 1)];
                [strongSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
            }];
            
            [privacyAlert showInViewController:self];
        }
        else
        {
            inputs.roomVisibility = kMXRoomVisibilityPrivate;
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (privacySection, 1)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    else if (sender == self.navigationItem.leftBarButtonItem)
    {
        // Cancel has been pressed
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)textFieldEditingChanged:(id)sender
{
    if (sender == roomNameTextField)
    {
        self.navigationItem.rightBarButtonItem.enabled = (inputs.mxSession && roomNameTextField.text.length);
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    if ([[segue identifier] isEqualToString:@"showRoomCreationStep2"])
    {
        RoomCreationStep2ViewController *viewController = segue.destinationViewController;
        viewController.roomCreationInputs = inputs;
        
        // Force back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"back", @"Vector", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
//    accountSection = appearanceSection = privacySection = -1;
    
    accountSection = count++;
    appearanceSection = count++;
    privacySection = count++;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == accountSection)
    {
        NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
        MXKAccount *account;
        if (mxAccounts.count == 1)
        {
            account = [mxAccounts firstObject];
            inputs.mxSession = account.mxSession;
            self.navigationItem.rightBarButtonItem.enabled = (inputs.roomName.length || roomNameTextField.text.length);
            
            count = 1;
        }
        else
        {
            if (isAccountListShrinked)
            {
                count = 1;
            }
            else
            {
                count = mxAccounts.count + 1;
            }
        }
    }
    else if (section == appearanceSection)
    {
        count = 2;
    }
    else if (section == privacySection)
    {
        count = 1;
    }
    
    return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == accountSection)
    {
        return NSLocalizedStringFromTable(@"room_creation_account", @"Vector", nil);
    }
    else if (section == appearanceSection)
    {
        return NSLocalizedStringFromTable(@"room_creation_appearance", @"Vector", nil);
    }
    else if (section == privacySection)
    {
        return NSLocalizedStringFromTable(@"room_creation_privacy", @"Vector", nil);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == accountSection)
    {
        NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
        
        if (indexPath.row == 0)
        {
            MXKTableViewCellWithLabelAndTextField *selectedAccountCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            if (!selectedAccountCell)
            {
                selectedAccountCell = [[MXKTableViewCellWithLabelAndTextField alloc] init];
            }
            
            selectedAccountCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_creation_account", @"Vector", nil);
            selectedAccountCell.mxkTextField.userInteractionEnabled = NO;
            if (inputs.mxSession)
            {
                selectedAccountCell.mxkTextField.text = [NSString stringWithFormat:@"%@ (%@)", inputs.mxSession.myUser.displayname, inputs.mxSession.myUser.userId];
            }
            else
            {
                selectedAccountCell.mxkTextField.text = nil;
            }
            
            if (mxAccounts.count > 1)
            {
                selectedAccountCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//                UIImageView *chevronView = [[UIImageView alloc] initWithImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"shrink"]];
//                chevronView.contentMode = UIViewContentModeScaleAspectFit;
//                chevronView.backgroundColor = [UIColor grayColor];
//                CGRect frame = chevronView.frame;
//                frame.size.width = frame.size.height = selectedAccountCell.mxkTextField.frame.size.height - 5;
//                chevronView.frame = frame;
//                selectedAccountCell.accessoryView = chevronView;
            }
            else
            {
                selectedAccountCell.accessoryType = UITableViewCellAccessoryNone;
            }
            
            
            cell = selectedAccountCell;
        }
        else if (!isAccountListShrinked)
        {
            NSInteger index = indexPath.row - 1;
            if (index < mxAccounts.count)
            {
                MXKAccount *account = mxAccounts[index];
                cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                if (!cell)
                {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"accountCell"];
                }
                
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", account.mxSession.myUser.displayname, account.mxSession.myUser.userId];
                cell.textLabel.textAlignment = NSTextAlignmentRight;
            }
        }
    }
    else if (indexPath.section == appearanceSection)
    {
        if (indexPath.row == 0)
        {
            MXKTableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            if (!roomNameCell)
            {
                roomNameCell = [[MXKTableViewCellWithLabelAndTextField alloc] init];
            }
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_creation_appearance_name", @"Vector", nil);
            
            roomNameCell.mxkTextField.text = roomNameTextField ? roomNameTextField.text : inputs.roomName;
            
            roomNameTextField = roomNameCell.mxkTextField;
            roomNameTextField.delegate = self;
            [roomNameTextField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            
            cell = roomNameCell;
        }
        else if (indexPath.row == 1)
        {
            MXKTableViewCellWithLabelAndImageView *roomPictureCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndImageView defaultReuseIdentifier]];
            if (!roomPictureCell)
            {
                roomPictureCell = [[MXKTableViewCellWithLabelAndImageView alloc] init];
            }
            
            roomPictureCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_creation_appearance_picture", @"Vector", nil);
            roomPictureCell.mxkImageView.image = [UIImage imageNamed:@"placeholder"];
            
            cell = roomPictureCell;
        }
    }
    else if (indexPath.section == privacySection)
    {
        MXKTableViewCellWithLabelAndButton *privacyCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndButton defaultReuseIdentifier]];
        if (!privacyCell)
        {
            privacyCell = [[MXKTableViewCellWithLabelAndButton alloc] init];
        }
        
        switchPrivacyButton = privacyCell.mxkButton;
        [switchPrivacyButton removeTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
        [switchPrivacyButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if (inputs.roomVisibility == kMXRoomVisibilityPrivate)
        {
            privacyCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_creation_private_room", @"Vector", nil);
            [switchPrivacyButton setTitle:NSLocalizedStringFromTable(@"room_creation_make_public", @"Vector", nil) forState:UIControlStateNormal];
            [switchPrivacyButton setTitle:NSLocalizedStringFromTable(@"room_creation_make_public", @"Vector", nil) forState:UIControlStateHighlighted];
        }
        else
        {
            privacyCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_creation_public_room", @"Vector", nil);
            [switchPrivacyButton setTitle:NSLocalizedStringFromTable(@"room_creation_make_private", @"Vector", nil) forState:UIControlStateNormal];
            [switchPrivacyButton setTitle:NSLocalizedStringFromTable(@"room_creation_make_private", @"Vector", nil) forState:UIControlStateHighlighted];
        }
        
        cell = privacyCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == accountSection && indexPath.row > 0)
    {
        return 44;
    }
    
    return 60;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]])
    {
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        tableViewHeaderFooterView.textLabel.font = [UIFont boldSystemFontOfSize:17];
        tableViewHeaderFooterView.textLabel.textColor = [UIColor blackColor];
    }
}

//- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 1;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == accountSection)
    {
        [self dismissKeyboard];
        
        UITableViewRowAnimation rowAnimation = UITableViewRowAnimationNone;
        NSArray *mxAccounts = [MXKAccountManager sharedManager].activeAccounts;
        
        if (indexPath.row == 0)
        {
            if (mxAccounts.count > 1)
            {
                isAccountListShrinked = !isAccountListShrinked;
            }
        }
        else if (!isAccountListShrinked)
        {
            
            NSInteger index = indexPath.row - 1;
            if (index < mxAccounts.count)
            {
                MXKAccount *account = mxAccounts[index];
                inputs.mxSession = account.mxSession;
                self.navigationItem.rightBarButtonItem.enabled = (roomNameTextField.text.length);
            }
            isAccountListShrinked = YES;
        }
        
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange (accountSection, 1)];
        [tableView reloadSections:indexSet withRowAnimation:rowAnimation];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == roomNameTextField)
    {
        inputs.roomName = roomNameTextField.text;
        if (! inputs.roomName.length)
        {
            inputs.roomName = nil;
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        else
        {
            self.navigationItem.rightBarButtonItem.enabled = (inputs.mxSession != nil);
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    // "Done" key has been pressed
    [textField resignFirstResponder];
    return YES;
}

@end
