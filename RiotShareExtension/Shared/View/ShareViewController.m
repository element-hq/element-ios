/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ShareViewController.h"
#import "ShareDataSource.h"
#import "RoomsListViewController.h"
#import "FallbackViewController.h"

#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface ShareViewController () <ShareDataSourceDelegate>

@property (nonatomic, assign, readonly) ShareViewControllerType type;

@property (nonatomic, assign) ShareViewControllerAccountState state;

@property (nonatomic, strong) RoomsListViewController *roomListViewController;
@property (nonatomic, strong) ShareDataSource *roomDataSource;

@property (nonatomic, strong) FallbackViewController *fallbackViewController;

@property (nonatomic, weak) IBOutlet UIView *masterContainerView;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UIView *contentView;

@property (nonatomic, strong) MXKPieChartHUD *hudView;

@end


@implementation ShareViewController

- (instancetype)initWithType:(ShareViewControllerType)type
                currentState:(ShareViewControllerAccountState)state
{
    if (self = [super init])
    {
        _type = type;
        _state = state;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.masterContainerView setBackgroundColor:ThemeService.shared.theme.baseColor];
    [self.masterContainerView.layer setCornerRadius:7.0];
    [self.contentView setBackgroundColor:ThemeService.shared.theme.backgroundColor];
    
    [self.titleLabel setTextColor:ThemeService.shared.theme.textPrimaryColor];
    
    [self.cancelButton setTintColor:ThemeService.shared.theme.tintColor];
    [self.cancelButton setTitle:[VectorL10n cancel] forState:UIControlStateNormal];
    
    [self.shareButton setTintColor:ThemeService.shared.theme.tintColor];
    [self.shareButton setEnabled:NO];
    
    [self configureWithState:self.state roomDataSource:self.roomDataSource];
}

- (void)configureWithState:(ShareViewControllerAccountState)state
            roomDataSource:(ShareDataSource *)roomDataSource
{
    self.state = state;
    self.roomDataSource = roomDataSource;
    self.roomDataSource.shareDelegate = self;
    
    if (!self.isViewLoaded) {
        return;
    }
    
    [self configureViews];
}

- (void)showProgressIndicator
{
    if (!self.hudView)
    {
        self.parentViewController.view.userInteractionEnabled = NO;
        self.hudView = [MXKPieChartHUD showLoadingHudOnView:self.view WithMessage:[VectorL10n sending]];
        [self.hudView setProgress:0.0];
    }
}

- (void)setProgress:(CGFloat)progress
{
    [self.hudView setProgress:progress];
}

#pragma mark - ShareDataSourceDelegate

- (void)shareDataSourceDidChangeSelectedRoomIdentifiers:(ShareDataSource *)shareDataSource
{
    self.shareButton.enabled = (shareDataSource.selectedRoomIdentifiers.count > 0);
}

#pragma mark - Private

- (void)configureViews
{
    [self resetContentView];
    
    if (self.state == ShareViewControllerAccountStateConfigured)
    {
        [self configureSegmentedViewController];
        [self.shareButton setHidden:NO];
        
        if (self.type == ShareViewControllerTypeSend) {
            [self.titleLabel setText:[VectorL10n sendTo:@""]];
            [self.shareButton setTitle:[VectorL10n sendTo:@""] forState:UIControlStateNormal];
        } else {
            [self.titleLabel setText:[VectorL10n roomEventActionForward]];
            [self.shareButton setTitle:[VectorL10n roomEventActionForward] forState:UIControlStateNormal];
        }
    }
    else
    {
        [self configureFallbackViewController];
        [self.shareButton setHidden:NO];
        
        self.titleLabel.text = [AppInfo.current displayName];
    }
}

- (void)configureSegmentedViewController
{
    self.roomListViewController = [RoomsListViewController recentListViewController];
    [self.roomListViewController displayList:self.roomDataSource];
        
    [self addChildViewController:self.roomListViewController];
    [self.contentView vc_addSubViewMatchingParent:self.roomListViewController.view];
    [self.roomListViewController didMoveToParentViewController:self];
}

- (void)configureFallbackViewController
{
    self.fallbackViewController = [FallbackViewController new];
    [self addChildViewController:self.fallbackViewController];
    [self.contentView vc_addSubViewMatchingParent:self.fallbackViewController.view];
    [self.fallbackViewController didMoveToParentViewController:self];
}

- (void)resetContentView
{
    [self.roomListViewController willMoveToParentViewController:nil];
    [self.roomListViewController.view removeFromSuperview];
    [self.roomListViewController removeFromParentViewController];
    
    [self.fallbackViewController willMoveToParentViewController:nil];
    [self.fallbackViewController.view removeFromSuperview];
    [self.fallbackViewController removeFromParentViewController];
}

#pragma mark - Actions

- (IBAction)onCancelButtonTap:(UIButton *)sender
{
    [self.delegate shareViewControllerDidRequestDismissal:self];
}

- (IBAction)onShareButtonTap:(UIButton *)sender
{
    if (self.roomDataSource.selectedRoomIdentifiers.count == 0) {
        return;
    }
    
    [self.delegate shareViewController:self didRequestShareForRoomIdentifiers:self.roomDataSource.selectedRoomIdentifiers];
}

@end
