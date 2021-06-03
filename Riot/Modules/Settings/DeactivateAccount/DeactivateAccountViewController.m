/*
 Copyright 2018 New Vector Ltd
 
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

#import "DeactivateAccountViewController.h"

#import "ThemeService.h"
#import "Riot-Swift.h"

#pragma mark - Defines & Constants

static CGFloat const kButtonCornerRadius = 5.0;
static CGFloat const kTextFontSize = 15.0;

#pragma mark - Private Interface

@interface DeactivateAccountViewController ()

#pragma mark - Outlets

@property (weak, nonatomic) IBOutlet UILabel *deactivateAccountInfosLabel;

@property (weak, nonatomic) IBOutlet UILabel *forgetMessagesInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *forgetMessageButton;

@property (weak, nonatomic) IBOutlet UIButton *deactivateAcccountButton;


#pragma mark - Private Properties

@property (strong, nonatomic) NSDictionary *normalStringAttributes;
@property (strong, nonatomic) NSDictionary *emphasizeStringAttributes;

@property (strong, nonatomic) MXKErrorAlertPresentation *errorPresentation;

@property (weak, nonatomic) id <NSObject> themeDidChangeNotificationObserver;

@end

#pragma mark - Implementation

@implementation DeactivateAccountViewController

#pragma mark - Setup & Teardown

+ (DeactivateAccountViewController*)instantiateWithMatrixSession:(MXSession*)matrixSession
{
   DeactivateAccountViewController* viewController = [[UIStoryboard storyboardWithName:NSStringFromClass([DeactivateAccountViewController class]) bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [viewController addMatrixSession:matrixSession];
    return viewController;
}

- (void)destroy
{
    id<NSObject> notificationObserver = self.themeDidChangeNotificationObserver;
    
    if (notificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
    }
    
    [super destroy];
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = NSLocalizedStringFromTable(@"deactivate_account_title", @"Vector", nil);

    [self setupViews];
    
    self.errorPresentation = [[MXKErrorAlertPresentation alloc] init];
    [self registerThemeNotification];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self userInterfaceThemeDidChange];
    
    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"DeactivateAccount"];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.deactivateAcccountButton.layer setCornerRadius:kButtonCornerRadius];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

#pragma mark - Private

- (void)registerThemeNotification
{
    self.themeDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        [self userInterfaceThemeDidChange];
    }];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;

    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    self.forgetMessageButton.tintColor = ThemeService.shared.theme.tintColor;

    [self updateStringAttributes];
    [self updateNavigationBar];
    [self updateDeactivateAcccountButton];
    [self updateDeactivateAccountInfosLabel];
    [self updateForgetMessagesInfoLabel];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)updateStringAttributes
{
    self.normalStringAttributes = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:kTextFontSize],
                                    NSForegroundColorAttributeName: ThemeService.shared.theme.textPrimaryColor
                                    };
    
    
    self.emphasizeStringAttributes = @{
                                       NSFontAttributeName: [UIFont systemFontOfSize:kTextFontSize weight:UIFontWeightBold],
                                       NSForegroundColorAttributeName: ThemeService.shared.theme.textPrimaryColor
                                       };
}

- (void)setupViews
{
    // Cancel bar button
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonAction:)];
    self.navigationItem.rightBarButtonItem = cancelBarButtonItem;

    // Deactivate button
    // Adjust button font size for small devices
    self.deactivateAcccountButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.deactivateAcccountButton.titleLabel.minimumScaleFactor = 0.5;
    self.deactivateAcccountButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.deactivateAcccountButton.layer.masksToBounds = YES;
    [self.deactivateAcccountButton setTitle:NSLocalizedStringFromTable(@"deactivate_account_validate_action", @"Vector", nil) forState:UIControlStateNormal];
}

- (void)updateNavigationBar
{
    self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: ThemeService.shared.theme.warningColor };
}

- (void)updateDeactivateAcccountButton
{
    self.deactivateAcccountButton.backgroundColor = ThemeService.shared.theme.tintColor;
    [self.deactivateAcccountButton setTitleColor:ThemeService.shared.theme.headerTextSecondaryColor forState:UIControlStateDisabled];
}

- (void)updateDeactivateAccountInfosLabel
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_informations_part1", @"Vector", nil) attributes:self.normalStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_informations_part2_emphasize", @"Vector", nil) attributes:self.emphasizeStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_informations_part3", @"Vector", nil) attributes:self.normalStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_informations_part4_emphasize", @"Vector", nil) attributes:self.emphasizeStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_informations_part5", @"Vector", nil) attributes:self.normalStringAttributes]];
    
    [self.deactivateAccountInfosLabel setAttributedText:attributedString];
}

- (void)updateForgetMessagesInfoLabel
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_forget_messages_information_part1", @"Vector", nil) attributes:self.normalStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_forget_messages_information_part2_emphasize", @"Vector", nil) attributes:self.emphasizeStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedStringFromTable(@"deactivate_account_forget_messages_information_part3", @"Vector", nil) attributes:self.normalStringAttributes]];
    
    [self.forgetMessagesInfoLabel setAttributedText:attributedString];
}

- (void)enableUserActions:(BOOL)enableUserActions
{
    self.navigationItem.rightBarButtonItem.enabled = enableUserActions;
    self.forgetMessageButton.userInteractionEnabled = enableUserActions;
    self.deactivateAcccountButton.enabled = enableUserActions;
}

- (void)presentPasswordRequiredAlertWithSubmitHandler:(void (^)(NSString *password))submitHandler
                                        cancelHandler:(dispatch_block_t)cancelHandler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"deactivate_account_password_alert_title", @"Vector", nil)
                                                                   message:NSLocalizedStringFromTable(@"deactivate_account_password_alert_message", @"Vector", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                if (cancelHandler)
                                                {
                                                    cancelHandler();
                                                }
                                            }]];
    
    __weak typeof(self) weakSelf = self;
    
    [alert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"submit"]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                UITextField *textField = alert.textFields.firstObject;
                                                
                                                typeof(weakSelf) strongSelf = weakSelf;
                                                
                                                if (strongSelf)
                                                {
                                                    NSString *password = textField.text;
                                                    
                                                    if (submitHandler)
                                                    {
                                                        submitHandler(password);
                                                    }
                                                }
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deactivateAccountWithUserId:(NSString*)userId
                        andPassword:(NSString*)password
                   eraseAllMessages:(BOOL)eraseAllMessages
{
    if (password && userId)
    {
        [self enableUserActions:NO];
        [self startActivityIndicator];
        
        // This assumes that the homeserver requires password UI auth
        // for this endpoint. In reality it could be any UI auth.
        
        __weak typeof(self) weakSelf = self;
        
        NSDictionary *authParameters = @{@"user":     userId,
                                         @"password": password,
                                         @"type":     kMXLoginFlowTypePassword};
        
        [self.mainSession deactivateAccountWithAuthParameters:authParameters eraseAccount:eraseAllMessages success:^{
            MXLogDebug(@"[SettingsViewController] Deactivate account with success");
            
            typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf)
            {
                [strongSelf stopActivityIndicator];
                [strongSelf enableUserActions:YES];
                [strongSelf.delegate deactivateAccountViewControllerDidDeactivateWithSuccess:strongSelf];
            }
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[SettingsViewController] Failed to deactivate account");
            
            typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf)
            {
                [strongSelf stopActivityIndicator];
                [strongSelf enableUserActions:YES];
                [strongSelf.errorPresentation presentErrorFromViewController:strongSelf forError:error animated:YES handler:nil];
            }
        }];
    }
    else
    {
        MXLogDebug(@"[SettingsViewController] Failed to deactivate account");
        [self.errorPresentation presentGenericErrorFromViewController:self animated:YES handler:nil];
    }
}

#pragma mark - Actions

- (void)cancelButtonAction:(id)sender
{
    [self.delegate deactivateAccountViewControllerDidCancel:self];
}

- (IBAction)forgetMessagesButtonAction:(UIButton*)sender
{
    self.forgetMessageButton.selected = !self.forgetMessageButton.selected;
}

- (IBAction)deactivateAccountButtonAction:(id)sender
{
    __weak typeof(self) weakSelf = self;
    
    [self presentPasswordRequiredAlertWithSubmitHandler:^(NSString *password) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf)
        {
            NSString *userId = strongSelf.mainSession.myUser.userId;
            [strongSelf deactivateAccountWithUserId:userId andPassword:password eraseAllMessages:strongSelf.forgetMessageButton.isEnabled];
        }
        
    } cancelHandler:nil];
}

@end
