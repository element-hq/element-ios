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


@interface ShareViewController ()

@property (weak, nonatomic) IBOutlet UIView *masterContainerView;
@property (weak, nonatomic) IBOutlet UILabel *tittleLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic) SegmentedViewController *segmentedViewController;

@property (nonatomic) id shareExtensionManagerDidUpdateAccountDataObserver;


@end


@implementation ShareViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.shareExtensionManagerDidUpdateAccountDataObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kShareExtensionManagerDidUpdateAccountDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self configureViews];
    
    }];
    
    [self configureViews];
}

- (void)destroy
{
    [super destroy];
    
    if (self.shareExtensionManagerDidUpdateAccountDataObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.shareExtensionManagerDidUpdateAccountDataObserver];
        self.shareExtensionManagerDidUpdateAccountDataObserver = nil;
    }
    
    [self resetContentView];
}

- (void)resetContentView
{
    // Empty the content view
    NSArray *subviews = self.contentView.subviews;
    for (UIView *subview in subviews)
    {
        [subview removeFromSuperview];
    }
    
    // Release the current segmented view controller if any
    if (self.segmentedViewController)
    {
        [self.segmentedViewController removeFromParentViewController];
        
        // Release correctly all the existing data source and view controllers.
        [self.segmentedViewController destroy];
        self.segmentedViewController = nil;
    }
}

#pragma mark - Private

- (void)configureViews
{
    self.masterContainerView.layer.cornerRadius = 7;
    
    [self resetContentView];
    
    if ([ShareExtensionManager sharedManager].userAccount)
    {
        self.tittleLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"send_to", @"Vector", nil), @""];
        [self configureSegmentedViewController];
    }
    else
    {
        NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
        NSString *bundleDisplayName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        self.tittleLabel.text = bundleDisplayName;
        [self configureFallbackViewController];
    }
}

- (void)configureSegmentedViewController
{
    self.segmentedViewController = [SegmentedViewController segmentedViewController];
    
    NSArray *titles = @[NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil) , NSLocalizedStringFromTable(@"title_people", @"Vector", nil)];
    
    void (^failureBlock)() = ^void() {
        [self dismissViewControllerAnimated:YES completion:^{
            [[ShareExtensionManager sharedManager] terminateExtensionCanceled:NO];
        }];
    };
    
    ShareDataSource *roomsDataSource = [[ShareDataSource alloc] initWithMode:DataSourceModeRooms];
    RoomsListViewController *roomsViewController = [RoomsListViewController recentListViewController];
    roomsViewController.failureBlock = failureBlock;
    [roomsViewController displayList:roomsDataSource];
    
    ShareDataSource *peopleDataSource = [[ShareDataSource alloc] initWithMode:DataSourceModePeople];
    RoomsListViewController *peopleViewController = [RoomsListViewController recentListViewController];
    peopleViewController.failureBlock = failureBlock;
    [peopleViewController displayList:peopleDataSource];
    
    [self.segmentedViewController initWithTitles:titles viewControllers:@[roomsViewController, peopleViewController] defaultSelected:0];
    
    [self addChildViewController:self.segmentedViewController];
    [self.contentView addSubview:self.segmentedViewController.view];
    [self.segmentedViewController didMoveToParentViewController:self];
    
    [self autoPinSubviewEdges:self.segmentedViewController.view toSuperviewEdges:self.contentView];
}

- (void)configureFallbackViewController
{
    FallbackViewController *fallbackVC = [FallbackViewController new];
    [self addChildViewController:fallbackVC];
    [self.contentView addSubview:fallbackVC.view];
    [fallbackVC didMoveToParentViewController:self];
    
    [self autoPinSubviewEdges:fallbackVC.view toSuperviewEdges:self.contentView];
}

- (void)autoPinSubviewEdges:(UIView *)subview toSuperviewEdges:(UIView *)superview
{
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    widthConstraint.active = YES;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    heightConstraint.active = YES;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    centerXConstraint.active = YES;
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    centerYConstraint.active = YES;
}

#pragma mark - Actions

- (IBAction)close:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[ShareExtensionManager sharedManager] terminateExtensionCanceled:YES];
    }];
}


@end
