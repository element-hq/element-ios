/*
 Copyright 2017 Aram Sargsyan
 
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

#import "ShareViewController.h"
#import "SegmentedViewController.h"
#import "RoomsListViewController.h"
#import "FallbackViewController.h"
#import "ShareDataSource.h"
#import "ShareExtensionManager.h"

#import "ThemeService.h"

#ifdef IS_SHARE_EXTENSION
#import "RiotShareExtension-Swift.h"
#else
#import "Riot-Swift.h"
#endif

@interface ShareViewController () <MXKRecentListViewControllerDelegate>

@property (nonatomic, assign, readonly) ShareViewControllerType type;

@property (nonatomic, assign) ShareViewControllerAccountState state;
@property (nonatomic, strong) ShareDataSource *roomDataSource;
@property (nonatomic, strong) ShareDataSource *peopleDataSource;

@property (nonatomic, weak) IBOutlet UIView *masterContainerView;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (nonatomic, weak) IBOutlet UIView *contentView;

@property (nonatomic, strong) SegmentedViewController *segmentedViewController;

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
    
    [self.titleLabel setTextColor:ThemeService.shared.theme.textPrimaryColor];
    
    [self.cancelButton setTintColor:ThemeService.shared.theme.tintColor];
    [self.cancelButton setTitle:[VectorL10n cancel] forState:UIControlStateNormal];
    
    [self.shareButton setTintColor:ThemeService.shared.theme.tintColor];
    
    [self configureWithState:self.state roomDataSource:self.roomDataSource peopleDataSource:self.peopleDataSource];
}

- (void)configureWithState:(ShareViewControllerAccountState)state
            roomDataSource:(ShareDataSource *)roomDataSource
          peopleDataSource:(ShareDataSource *)peopleDataSource
{
    self.state = state;
    self.roomDataSource = roomDataSource;
    self.peopleDataSource = peopleDataSource;
    
    if (!self.isViewLoaded) {
        return;
    }
    
    [self configureViews];
}

#pragma mark - MXKRecentListViewControllerDelegate

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController
                   didSelectRoom:(NSString *)roomId
                 inMatrixSession:(MXSession *)mxSession
{
    [self.delegate shareViewControllerDidRequestShare:self forRoomIdentifier:roomId];
}

- (void)recentListViewController:(MXKRecentListViewController *)recentListViewController
          didSelectSuggestedRoom:(MXSpaceChildInfo *)childInfo
{
    [self.delegate shareViewControllerDidRequestShare:self forRoomIdentifier:childInfo.childRoomId];
}

#pragma mark - ShareExtensionManagerDelegate

- (void)showProgressIndicator
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.hudView)
        {
            self.parentViewController.view.userInteractionEnabled = NO;
            self.hudView = [MXKPieChartHUD showLoadingHudOnView:self.view WithMessage:[VectorL10n sending]];
            [self.hudView setProgress:0.0];
        }
    });
}

- (void)setProgress:(CGFloat)progress
{
    [self.hudView setProgress:progress];
}

#pragma mark - Private

- (void)configureViews
{
    [self resetContentView];
    
    if (self.state == ShareViewControllerAccountStateConfigured)
    {
        self.titleLabel.text = [VectorL10n sendTo:@""];
        [self.shareButton setTitle:[VectorL10n roomEventActionForward] forState:UIControlStateNormal];
        
        [self configureSegmentedViewController];
    }
    else
    {
        self.titleLabel.text = [AppInfo.current displayName];
        [self configureFallbackViewController];
    }
}

- (void)configureSegmentedViewController
{
    RoomsListViewController *roomsViewController = [RoomsListViewController recentListViewController];
    [roomsViewController displayList:self.roomDataSource];
    [roomsViewController setDelegate:self];
    
    RoomsListViewController *peopleViewController = [RoomsListViewController recentListViewController];
    [peopleViewController setDelegate:self];
    [peopleViewController displayList:self.peopleDataSource];
    
    self.segmentedViewController = [SegmentedViewController segmentedViewController];
    [self.segmentedViewController initWithTitles:@[[VectorL10n titleRooms], [VectorL10n titlePeople]]
                                 viewControllers:@[roomsViewController, peopleViewController] defaultSelected:0];
    
    [self addChildViewController:self.segmentedViewController];
    [self.contentView vc_addSubViewMatchingParent:self.segmentedViewController.view];
    [self.segmentedViewController didMoveToParentViewController:self];
}

- (void)configureFallbackViewController
{
    FallbackViewController *fallbackVC = [FallbackViewController new];
    [self addChildViewController:fallbackVC];
    [self.contentView vc_addSubViewMatchingParent:fallbackVC.view];
    [fallbackVC didMoveToParentViewController:self];
}

- (void)resetContentView
{
    NSArray *subviews = self.contentView.subviews;
    for (UIView *subview in subviews)
    {
        [subview removeFromSuperview];
    }
    
    if (self.segmentedViewController)
    {
        [self.segmentedViewController removeFromParentViewController];
        
        [self.segmentedViewController destroy];
        self.segmentedViewController = nil;
    }
}

#pragma mark - Actions

- (IBAction)onCancelButtonTap:(UIButton *)sender
{
    [self.delegate shareViewControllerDidRequestDismissal:self];
}

- (IBAction)onShareButtonTap:(UIButton *)sender
{
    
}

@end
