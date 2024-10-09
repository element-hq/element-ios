/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ManageSessionViewController.h"

#import "AvatarGenerator.h"

#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@import DesignKit;

enum
{
    SECTION_SESSION_INFO,
    SECTION_ACTION,
    SECTION_COUNT
};

enum {
    SESSION_INFO_SESSION_NAME,
    SESSION_INFO_TRUST,
    SESSION_INFO_COUNT
};

enum {
    ACTION_REMOVE_SESSION,
    ACTION_COUNT
};


@interface ManageSessionViewController () <UserVerificationCoordinatorBridgePresenterDelegate, SSOAuthenticationPresenterDelegate>
{
    // The device to display
    MXDevice *device;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;

    // The current pushed view controller
    UIViewController *pushedViewController;
}

@property (nonatomic, strong) UserVerificationCoordinatorBridgePresenter *userVerificationCoordinatorBridgePresenter;

@property (nonatomic, strong) ReauthenticationCoordinatorBridgePresenter *reauthenticationCoordinatorBridgePresenter;

@property (nonatomic, strong) SSOAuthenticationPresenter *ssoAuthenticationPresenter;

@end

@implementation ManageSessionViewController

#pragma mark - Setup & Teardown

+ (ManageSessionViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession andDevice:(MXDevice*)device;
{
    ManageSessionViewController* viewController = [[UIStoryboard storyboardWithName:@"ManageSession" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [viewController addMatrixSession:matrixSession];
    viewController->device = device;
    return viewController;
}


#pragma mark - View life cycle

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = [VectorL10n manageSessionTitle];
    [self vc_removeBackTitle];
    
    [self.tableView registerClass:MXKTableViewCellWithLabelAndTextField.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier]];
    [self.tableView registerClass:MXKTableViewCellWithLabelAndSwitch.class forCellReuseIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
    [self.tableView registerNib:MXKTableViewCellWithTextView.nib forCellReuseIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
    
    // Enable self sizing cells
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;

    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
    
    [self registerDeviceChangesNotification];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    // Check the table view style to select its bg color.
    self.tableView.backgroundColor = ((self.tableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    self.view.backgroundColor = self.tableView.backgroundColor;
    self.tableView.separatorColor = ThemeService.shared.theme.lineBreakColor;
    
    [self reloadData];

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)destroy
{
    // Release the potential pushed view controller
    [self releasePushedViewController];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Release the potential pushed view controller
    [self releasePushedViewController];

    // Refresh display
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
}

#pragma mark - Internal methods

- (void)pushViewController:(UIViewController*)viewController
{
    // Keep ref on pushed view controller
    pushedViewController = viewController;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)releasePushedViewController
{
    if (pushedViewController)
    {
        if ([pushedViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navigationController = (UINavigationController*)pushedViewController;
            for (id subViewController in navigationController.viewControllers)
            {
                if ([subViewController respondsToSelector:@selector(destroy)])
                {
                    [subViewController destroy];
                }
            }
        }
        else if ([pushedViewController respondsToSelector:@selector(destroy)])
        {
            [(id)pushedViewController destroy];
        }

        pushedViewController = nil;
    }
}

- (void)reset
{
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData
{
    // Trigger a full table reloadData
    [self.tableView reloadData];
}

- (void)reloadDeviceWithCompletion:(void (^)(void))completion
{
    MXWeakify(self);
    [self.mainSession.matrixRestClient deviceByDeviceId:device.deviceId success:^(MXDevice *device) {
        MXStrongifyAndReturnIfNil(self);
        
        self->device = device;
        [self reloadData];
        completion();
        
    } failure:^(NSError *error) {
        MXLogDebug(@"[ManageSessionVC] reloadDeviceWithCompletion failed. Error: %@", error);
        [self reloadData];
        completion();
    }];
}


#pragma mark - Data update

- (void)registerDeviceChangesNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceInfoTrustLevelDidChangeNotification:)
                                                 name:MXDeviceInfoTrustLevelDidChangeNotification
                                               object:nil];
}

- (void)onDeviceInfoTrustLevelDidChangeNotification:(NSNotification*)notification
{
    MXDeviceInfo *deviceInfo = notification.object;
    
    NSString *deviceId = deviceInfo.deviceId;
    if ([deviceId isEqualToString:device.deviceId])
    {
        [self reloadDeviceWithCompletion:^{
        }];
    }
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
    return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;

    switch (section)
    {
        case SECTION_SESSION_INFO:
            count = SESSION_INFO_COUNT;
            break;
        case SECTION_ACTION:
            count = ACTION_COUNT;
            break;
    }

    return count;
}

- (MXKTableViewCellWithLabelAndTextField*)getLabelAndTextFieldCell:(UITableView*)tableView forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndTextField *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndTextField defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
    cell.mxkTextFieldLeadingConstraint.constant = 16;
    cell.mxkTextFieldTrailingConstraint.constant = 15;
    
    cell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    
    cell.mxkTextField.userInteractionEnabled = YES;
    cell.mxkTextField.borderStyle = UITextBorderStyleNone;
    cell.mxkTextField.textAlignment = NSTextAlignmentRight;
    cell.mxkTextField.textColor = ThemeService.shared.theme.textSecondaryColor;
    cell.mxkTextField.font = [UIFont systemFontOfSize:16];
    cell.mxkTextField.placeholder = nil;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    cell.alpha = 1.0f;
    cell.userInteractionEnabled = YES;
    
    [cell layoutIfNeeded];
    
    return cell;
}

- (MXKTableViewCellWithLabelAndSwitch*)getLabelAndSwitchCell:(UITableView*)tableView forIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithLabelAndSwitch *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier] forIndexPath:indexPath];

    cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left;
    cell.mxkSwitchTrailingConstraint.constant = 15;

    cell.mxkLabel.textColor = ThemeService.shared.theme.textPrimaryColor;

    [cell.mxkSwitch removeTarget:self action:nil forControlEvents:UIControlEventValueChanged];

    // Force layout before reusing a cell (fix switch displayed outside the screen)
    [cell layoutIfNeeded];

    return cell;
}

- (MXKTableViewCell*)getDefaultTableViewCell:(UITableView*)tableView
{
    MXKTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCell defaultReuseIdentifier]];
    if (!cell)
    {
        cell = [[MXKTableViewCell alloc] init];
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.imageView.image = nil;
    }
    cell.textLabel.accessibilityIdentifier = nil;
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    cell.contentView.backgroundColor = UIColor.clearColor;

    return cell;
}

- (MXKTableViewCell*)trustCellWithDevice:(MXDevice*)device forTableView:(UITableView*)tableView
{
    MXKTableViewCell *cell = [self getDefaultTableViewCell:tableView];
    
    NSString *deviceId = device.deviceId;
    MXDeviceInfo *deviceInfo = [self.mainSession.crypto deviceWithDeviceId:deviceId ofUser:self.mainSession.myUser.userId];
    
    cell.textLabel.numberOfLines = 0;
    [cell vc_setAccessoryDisclosureIndicatorWithCurrentTheme];

    if (deviceInfo.trustLevel.isVerified)
    {
        cell.textLabel.text = [VectorL10n manageSessionTrusted];
        cell.imageView.image = AssetImages.encryptionTrusted.image;
    }
    else
    {
        cell.textLabel.text = [VectorL10n manageSessionNotTrusted];
        cell.imageView.image = AssetImages.encryptionWarning.image;
    }

    return cell;
}

- (MXKTableViewCellWithTextView*)textViewCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    MXKTableViewCellWithTextView *textViewCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier] forIndexPath:indexPath];

    textViewCell.mxkTextView.textColor = ThemeService.shared.theme.textPrimaryColor;
    textViewCell.mxkTextView.font = [UIFont systemFontOfSize:17];
    textViewCell.mxkTextView.backgroundColor = [UIColor clearColor];
    textViewCell.mxkTextViewLeadingConstraint.constant = tableView.vc_separatorInset.left;
    textViewCell.mxkTextViewTrailingConstraint.constant = tableView.vc_separatorInset.right;
    textViewCell.mxkTextView.accessibilityIdentifier = nil;

    return textViewCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;

    // set the cell to a default value to avoid application crashes
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor redColor];

    switch (section)
    {
        case SECTION_SESSION_INFO:
            switch (row)
        {
            case SESSION_INFO_SESSION_NAME:
            {
                MXKTableViewCellWithLabelAndTextField *displaynameCell = [self getLabelAndTextFieldCell:tableView forIndexPath:indexPath];
                
                displaynameCell.mxkLabel.text = [VectorL10n manageSessionName];
                displaynameCell.mxkTextField.text = device.displayName;
                displaynameCell.mxkTextField.userInteractionEnabled = NO;
                displaynameCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                
                cell = displaynameCell;
                break;
            }
            case SESSION_INFO_TRUST:
            {
                cell = [self trustCellWithDevice:device forTableView:tableView];
            }
                
        }
            break;
            
        case SECTION_ACTION:
            switch (row)
        {
            case ACTION_REMOVE_SESSION:
            {
                MXKTableViewCellWithButton *removeSessionBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
                
                if (!removeSessionBtnCell)
                {
                    removeSessionBtnCell = [[MXKTableViewCellWithButton alloc] init];
                }
                else
                {
                    // Fix https://github.com/vector-im/riot-ios/issues/1354
                    removeSessionBtnCell.mxkButton.titleLabel.text = nil;
                }
                
                NSString *btnTitle = [VectorL10n manageSessionSignOut];
                [removeSessionBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateNormal];
                [removeSessionBtnCell.mxkButton setTitle:btnTitle forState:UIControlStateHighlighted];
                [removeSessionBtnCell.mxkButton setTintColor:ThemeService.shared.theme.warningColor];
                removeSessionBtnCell.mxkButton.titleLabel.font = [UIFont systemFontOfSize:17];
                removeSessionBtnCell.mxkButton.userInteractionEnabled = NO;
                removeSessionBtnCell.selectionStyle = UITableViewCellSelectionStyleDefault;
                
                cell = removeSessionBtnCell;
                break;
            }
        }
            break;
            
    }

    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case SECTION_SESSION_INFO:
            return [VectorL10n manageSessionInfo];
        case SECTION_ACTION:
            return @"";

    }

    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:UITableViewHeaderFooterView.class])
    {
        // Customize label style
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView*)view;
        tableViewHeaderFooterView.textLabel.textColor = ThemeService.shared.theme.colors.secondaryContent;
        tableViewHeaderFooterView.textLabel.font = ThemeService.shared.theme.fonts.footnote;
    }
}


#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;

    if (cell.selectionStyle != UITableViewCellSelectionStyleNone)
    {
        // Update the selected background view
        if (ThemeService.shared.theme.selectedBackgroundColor)
        {
            cell.selectedBackgroundView = [[UIView alloc] init];
            cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
        }
        else
        {
            if (tableView.style == UITableViewStylePlain)
            {
                cell.selectedBackgroundView = nil;
            }
            else
            {
                cell.selectedBackgroundView.backgroundColor = nil;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_SESSION_INFO)
    {
        return 44;
    }
    return 24;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == SECTION_SESSION_INFO)
    {
        return 0;
    }
    return 24;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView)
    {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        switch (section)
        {
            case SECTION_SESSION_INFO:
                switch (row)
            {
                case SESSION_INFO_SESSION_NAME:
                    [self renameDevice];
                    break;
                case SESSION_INFO_TRUST:
                    [self showTrustForDevice:device];
                    break;
            }
                break;
                
            case SECTION_ACTION:
            {
                switch (row)
                {
                    case ACTION_REMOVE_SESSION:
                        [self removeDevice];
                        break;
                }
            }
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - actions

- (void)renameDevice
{
    // Prompt the user to enter a device name.
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    
    MXWeakify(self);
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n deviceDetailsRenamePromptTitle]
                                                       message:[VectorL10n deviceDetailsRenamePromptMessage]
                                                preferredStyle:UIAlertControllerStyleAlert];
    
    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        MXStrongifyAndReturnIfNil(self);
        textField.secureTextEntry = NO;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.text = self->device.displayName;
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 MXStrongifyAndReturnIfNil(self);
                                 self->currentAlert = nil;
                             }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 MXStrongifyAndReturnIfNil(self);
                                 
                                 NSString *text = [self->currentAlert textFields].firstObject.text;
                                 self->currentAlert = nil;
                                 
                                 
                                 // Hot change
                                 self->device.displayName = text;
                                 [self reloadData];
                                 [self.activityIndicator startAnimating];

                                 [self.mainSession.matrixRestClient setDeviceName:text forDeviceId:self->device.deviceId success:^{
                                     [self reloadDeviceWithCompletion:^{
                                         [self.activityIndicator stopAnimating];
                                     }];
                                 } failure:^(NSError *error) {
                                     
                                     MXLogDebug(@"[ManageSessionVC] Rename device (%@) failed", self->device.deviceId);
                                     [self reloadDeviceWithCompletion:^{
                                         [self.activityIndicator stopAnimating];
                                         [[AppDelegate theDelegate] showErrorAsAlert:error];
                                     }];
                                 }];
                                 
                             }]];
    
    [self presentViewController:currentAlert animated:YES completion:nil];
}

- (void)showTrustForDevice:(MXDevice *)device
{
    UserVerificationCoordinatorBridgePresenter *userVerificationCoordinatorBridgePresenter = [[UserVerificationCoordinatorBridgePresenter alloc] initWithPresenter:self
                                                                                                                                                           session:self.mainSession
                                                                                                                                                            userId:self.mainSession.myUser.userId
                                                                                                                                                   userDisplayName:nil
                                                                                                                                                          deviceId:device.deviceId];
    userVerificationCoordinatorBridgePresenter.delegate = self;
    [userVerificationCoordinatorBridgePresenter start];
    self.userVerificationCoordinatorBridgePresenter = userVerificationCoordinatorBridgePresenter;
}

- (void)removeDevice
{
    MXWellKnownAuthentication *authentication = self.mainSession.homeserverWellknown.authentication;
    if (authentication)
    {
        NSURL *logoutURL = [authentication getLogoutDeviceURLFromID:device.deviceId];
        if (logoutURL)
        {
            [self removeDeviceRedirectWithURL:logoutURL];
        }
        else
        {
            [self showRemoveDeviceRedirectError];
        }
    }
    else
    {
        [self removeDeviceThroughAPI];
    }
}

-(void) removeDeviceRedirectWithURL: (NSURL * _Nonnull) url
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: [VectorL10n manageSessionRedirect] message: nil preferredStyle:UIAlertControllerStyleAlert];
    
    MXWeakify(self);
    UIAlertAction *action = [UIAlertAction actionWithTitle:[VectorL10n ok]
                                                     style:UIAlertActionStyleDefault
                                                   handler: ^(UIAlertAction * action) {
        MXStrongifyAndReturnIfNil(self);
        SSOAccountService *service = [[SSOAccountService alloc] initWithAccountURL:url];
        SSOAuthenticationPresenter *presenter = [[SSOAuthenticationPresenter alloc] initWithSsoAuthenticationService:service];
        presenter.delegate = self;
        self.ssoAuthenticationPresenter = presenter;
        
        [presenter presentForIdentityProvider:nil with:@"" from:self animated:YES];
    }];
    
    [alert addAction: action];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) showRemoveDeviceRedirectError
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: [VectorL10n manageSessionRedirectError] message: nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) removeDeviceThroughAPI
{
    [self startActivityIndicator];
    self.view.userInteractionEnabled = NO;
    
    MXWeakify(self);
    
    void (^animationCompletion)(void) = ^void () {
        MXStrongifyAndReturnIfNil(self);
        
        [self stopActivityIndicator];
        self.view.userInteractionEnabled = YES;
        [self.reauthenticationCoordinatorBridgePresenter dismissWithAnimated:YES completion:^{}];
        self.reauthenticationCoordinatorBridgePresenter = nil;
    };
    
    NSString *title = [VectorL10n deviceDetailsDeletePromptTitle];
    NSString *message = [VectorL10n deviceDetailsDeletePromptMessage];
    
    AuthenticatedEndpointRequest *deleteDeviceRequest = [[AuthenticatedEndpointRequest alloc] initWithPath:[NSString stringWithFormat:@"%@/devices/%@", kMXAPIPrefixPathR0, [MXTools encodeURIComponent:device.deviceId]] httpMethod:@"DELETE" params:[[NSDictionary alloc] init]];
    
    ReauthenticationCoordinatorParameters *coordinatorParameters = [[ReauthenticationCoordinatorParameters alloc] initWithSession:self.mainSession presenter:self title:title message:message authenticatedEndpointRequest:deleteDeviceRequest];
    
    ReauthenticationCoordinatorBridgePresenter *reauthenticationPresenter = [ReauthenticationCoordinatorBridgePresenter new];
    
    [reauthenticationPresenter presentWith:coordinatorParameters animated:YES success:^(NSDictionary<NSString *,id> *_Nullable authParams) {
        MXStrongifyAndReturnIfNil(self);
                        
        [self.mainSession.matrixRestClient deleteDeviceByDeviceId:self->device.deviceId authParams:authParams success:^{
            animationCompletion();
            
            // We cannot stay in this screen anymore
            [self withdrawViewControllerAnimated:YES completion:nil];
        } failure:^(NSError *error) {
            MXLogDebug(@"[ManageSessionVC] Delete device (%@) failed", self->device.deviceId);
            animationCompletion();
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }];
    } cancel:^{
        animationCompletion();
    } failure:^(NSError * _Nonnull error) {
        animationCompletion();
        [[AppDelegate theDelegate] showErrorAsAlert:error];
    }];
    
    self.reauthenticationCoordinatorBridgePresenter = reauthenticationPresenter;
}

#pragma mark - UserVerificationCoordinatorBridgePresenterDelegate

- (void)userVerificationCoordinatorBridgePresenterDelegateDidComplete:(UserVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter
{
    [self reloadDeviceWithCompletion:^{}];
}

#pragma mark - SSOAuthenticationPresenterDelegate

- (void)ssoAuthenticationPresenterDidCancel:(SSOAuthenticationPresenter *)presenter
{
    self.ssoAuthenticationPresenter = nil;
    MXLogDebug(@"OIDC account management complete.")
    [self withdrawViewControllerAnimated:YES completion:nil];
}

- (void)ssoAuthenticationPresenter:(SSOAuthenticationPresenter *)presenter authenticationDidFailWithError:(NSError *)error
{
    self.ssoAuthenticationPresenter = nil;
    MXLogError(@"OIDC account management failed.")
}

- (void)ssoAuthenticationPresenter:(SSOAuthenticationPresenter *)presenter
  authenticationSucceededWithToken:(NSString *)token
             usingIdentityProvider:(SSOIdentityProvider *)identityProvider
{
    self.ssoAuthenticationPresenter = nil;
    MXLogWarning(@"Unexpected callback after OIDC account management.")
}

@end
