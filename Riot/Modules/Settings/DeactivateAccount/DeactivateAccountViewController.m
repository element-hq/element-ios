/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "DeactivateAccountViewController.h"

#import <SafariServices/SafariServices.h>
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#pragma mark - Defines & Constants

static CGFloat const kButtonCornerRadius = 5.0;
static CGFloat const kTextFontSize = 15.0;

#pragma mark - Private Interface

@interface DeactivateAccountViewController () <DeactivateAccountServiceDelegate, SFSafariViewControllerDelegate>

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

@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@property (nonatomic) DeactivateAccountService *deactivateAccountService;

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

- (void)finalizeInit
{
    [super finalizeInit];
    self.screenTracker = [[AnalyticsScreenTracker alloc] initWithScreen:AnalyticsScreenDeactivateAccount];
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
    
    self.title = [VectorL10n deactivateAccountTitle];

    [self setupViews];
    
    self.errorPresentation = [[MXKErrorAlertPresentation alloc] init];
    [self registerThemeNotification];
    
    self.deactivateAccountService = [[DeactivateAccountService alloc] initWithSession:self.mainSession];
    self.deactivateAccountService.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self userInterfaceThemeDidChange];
    [self.screenTracker trackScreen];
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
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VectorL10n cancel] style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonAction:)];
    self.navigationItem.rightBarButtonItem = cancelBarButtonItem;

    // Deactivate button
    // Adjust button font size for small devices
    self.deactivateAcccountButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.deactivateAcccountButton.titleLabel.minimumScaleFactor = 0.5;
    self.deactivateAcccountButton.titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.deactivateAcccountButton.layer.masksToBounds = YES;
    [self.deactivateAcccountButton setTitle:[VectorL10n deactivateAccountValidateAction] forState:UIControlStateNormal];
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
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountInformationsPart1] attributes:self.normalStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountInformationsPart2Emphasize] attributes:self.emphasizeStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountInformationsPart3] attributes:self.normalStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountInformationsPart4Emphasize] attributes:self.emphasizeStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountInformationsPart5] attributes:self.normalStringAttributes]];
    
    [self.deactivateAccountInfosLabel setAttributedText:attributedString];
}

- (void)updateForgetMessagesInfoLabel
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountForgetMessagesInformationPart1] attributes:self.normalStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountForgetMessagesInformationPart2Emphasize] attributes:self.emphasizeStringAttributes]];
    
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[VectorL10n deactivateAccountForgetMessagesInformationPart3] attributes:self.normalStringAttributes]];
    
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n deactivateAccountPasswordAlertTitle]
                                                                   message:[VectorL10n deactivateAccountPasswordAlertMessage] preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                if (cancelHandler)
                                                {
                                                    cancelHandler();
                                                }
                                            }]];
    
    __weak typeof(self) weakSelf = self;
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n submit]
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

- (void)startLoading
{
    [self enableUserActions:NO];
    [self startActivityIndicator];
}

- (void)stopLoading
{
    [self stopActivityIndicator];
    [self enableUserActions:YES];
}

- (void)handleError:(NSError *)error
{
    [self stopLoading];
    [self.errorPresentation presentErrorFromViewController:self forError:error animated:YES handler:nil];
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
    [self startLoading];
    
    MXWeakify(self);
    [self.deactivateAccountService checkAuthenticationWithSuccess:^(enum DeactivateAccountAuthentication authentication, NSURL * _Nullable fallbackURL) {
        MXStrongifyAndReturnIfNil(self);
        
        switch (authentication) {
            case DeactivateAccountAuthenticationAuthenticated:
                MXLogDebug(@"[DeactivateAccountViewController] Deactivation endpoint has already been authenticated. Continuing deactivation.")
                [self.deactivateAccountService deactivateWithEraseAccount:self.forgetMessageButton.isSelected];
                break;
            case DeactivateAccountAuthenticationRequiresPassword:
                [self presentPasswordPrompt];
                break;
            case DeactivateAccountAuthenticationRequiresFallback:
                if (fallbackURL) [self presentFallbackForURL:fallbackURL];
                break;
        }
    } failure:^(NSError * _Nonnull error) {
        MXStrongifyAndReturnIfNil(self);
        [self handleError:error];
    }];
}

#pragma mark - Password

- (void)presentPasswordPrompt
{
    MXLogDebug(@"[DeactivateAccountViewController] Show password prompt.")
    
    MXWeakify(self);
    [self presentPasswordRequiredAlertWithSubmitHandler:^(NSString *password) {
        MXStrongifyAndReturnIfNil(self);
        [self.deactivateAccountService deactivateWith:password eraseAccount:self.forgetMessageButton.isSelected];
    } cancelHandler:^() {
        MXStrongifyAndReturnIfNil(self);
        [self stopLoading];
    }];
}

#pragma mark - Fallback

- (void)presentFallbackForURL:(NSURL *)url
{
    MXLogDebug(@"[DeactivateAccountViewController] Show fallback for url: %@", url)
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
    safariViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    safariViewController.delegate = self;
    
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    // There is no indication from the fallback page or the UIAService whether this was successful so attempt to deactivate.
    // It will fail (and display an error to the user) if the fallback page was dismissed.
    MXLogDebug(@"[DeactivateAccountViewController] safariViewControllerDidFinish: Completing deactivation after fallback.")
    [self.deactivateAccountService deactivateWithEraseAccount:self.forgetMessageButton.isSelected];
}

#pragma mark - DeactivateAccountServiceDelegate

- (void)deactivateAccountServiceDidEncounterError:(NSError *)error
{
    MXLogDebug(@"[DeactivateAccountViewController] Failed to deactivate account");
    [self handleError:error];
}

- (void)deactivateAccountServiceDidCompleteDeactivation
{
    MXLogDebug(@"[DeactivateAccountViewController] Deactivate account with success");
    [self.delegate deactivateAccountViewControllerDidDeactivateWithSuccess:self];
}

@end
