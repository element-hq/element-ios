/*
 Copyright 2017 Aram Sargsyan
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

#import "ReadReceiptsViewController.h"

#import "RageShakeManager.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@interface ReadReceiptsViewController () <UITableViewDataSource, UITableViewDelegate>
{
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@property (nonatomic) MXSession *session;

@property (nonatomic) NSArray <MXRoomMember *> *roomMembers;
@property (nonatomic) NSArray <UIImage *> *placeholders;
@property (nonatomic) NSArray <MXReceiptData *> *receipts;

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITableView *receiptsTableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation ReadReceiptsViewController

#pragma mark - Public

+ (void)openInViewController:(UIViewController *)viewController fromContainer:(MXKReceiptSendersContainer *)receiptSendersContainer withSession:(MXSession *)session
{
    ReadReceiptsViewController *receiptsController = [[[self class] alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
    receiptsController.session = session;
    
    receiptsController.roomMembers = receiptSendersContainer.roomMembers;
    receiptsController.placeholders = receiptSendersContainer.placeholders;
    receiptsController.receipts = receiptSendersContainer.readReceipts;
    
    receiptsController.providesPresentationContextTransitionStyle = YES;
    receiptsController.definesPresentationContext = YES;
    receiptsController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    receiptsController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [viewController presentViewController:receiptsController animated:YES completion:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    [self configureViews];
    [self configureReceiptsTableView];
    [self addOverlayViewGesture];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.overlayView.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    self.overlayView.alpha = 1.0;
    
    self.titleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.containerView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Check the table view style to select its bg color.
    self.receiptsTableView.backgroundColor = ((self.receiptsTableView.style == UITableViewStylePlain) ? ThemeService.shared.theme.backgroundColor : ThemeService.shared.theme.headerBackgroundColor);
    
    self.closeButton.tintColor = ThemeService.shared.theme.tintColor;
    
    if (self.receiptsTableView.dataSource)
    {
        // Force table refresh
        [self.receiptsTableView reloadData];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)destroy
{
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    [super destroy];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    
    [self destroy];
}

#pragma mark - Views

- (void)configureViews
{
    self.containerView.layer.cornerRadius = 20;
    self.titleLabel.text = [VectorL10n readReceiptsList];
    
    [_closeButton setTitle:[VectorL10n close] forState:UIControlStateNormal];
    [_closeButton setTitle:[VectorL10n close] forState:UIControlStateHighlighted];
}

- (void)configureReceiptsTableView
{
    self.receiptsTableView.dataSource = self;
    self.receiptsTableView.delegate = self;
    self.receiptsTableView.showsVerticalScrollIndicator = NO;
    self.receiptsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.receiptsTableView registerNib:[MXKReadReceiptTableViewCell nib] forCellReuseIdentifier:[MXKReadReceiptTableViewCell defaultReuseIdentifier]];
}

- (void)addOverlayViewGesture
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTap)];
    [tapRecognizer setNumberOfTapsRequired:1];
    [tapRecognizer setNumberOfTouchesRequired:1];
    [self.overlayView addGestureRecognizer:tapRecognizer];
}

#pragma mark - Actions

- (void)overlayTap
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCloseButtonPress:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.roomMembers.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKReadReceiptTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[MXKReadReceiptTableViewCell defaultReuseIdentifier] forIndexPath:indexPath];
    
    cell.displayNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    cell.receiptDescriptionLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    if (indexPath.row < self.roomMembers.count)
    {
        NSString *name = self.roomMembers[indexPath.row].displayname;
        if (name.length == 0) {
            name = self.roomMembers[indexPath.row].userId;
        }
        cell.displayNameLabel.text = name;
    }
    if (indexPath.row < self.placeholders.count)
    {
        NSString *avatarUrl = self.roomMembers[indexPath.row].avatarUrl;
        CGFloat side = CGRectGetWidth(cell.avatarImageView.frame);
        [cell.avatarImageView setImageURI:avatarUrl
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                            toFitViewSize:CGSizeMake(side, side)
                               withMethod:MXThumbnailingMethodCrop
                             previewImage:self.placeholders[indexPath.row]
                             mediaManager:self.session.mediaManager];
    }
    if (indexPath.row < self.receipts.count)
    {
        NSString *receiptReadText = [VectorL10n receiptStatusRead];
        NSString *receiptTimeText = [(MXKEventFormatter*)self.session.roomSummaryUpdateDelegate dateStringFromTimestamp:self.receipts[indexPath.row].ts withTime:YES];
        
        NSMutableAttributedString *receiptDescription = [[NSMutableAttributedString alloc] initWithString:receiptReadText attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textSecondaryColor, NSFontAttributeName : [UIFont  boldSystemFontOfSize:15]}];
        
        [receiptDescription appendAttributedString:[[NSAttributedString alloc] initWithString:receiptTimeText attributes:@{NSForegroundColorAttributeName : ThemeService.shared.theme.textSecondaryColor, NSFontAttributeName : [UIFont  systemFontOfSize:15]}]];
        
        cell.receiptDescriptionLabel.attributedText = receiptDescription;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


@end
