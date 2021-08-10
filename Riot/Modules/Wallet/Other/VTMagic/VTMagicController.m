//
//  VTMagicController.m
//  VTMagicView
//
//  Created by tianzhuo on 14-11-11.
//  Copyright (c) 2014年 tianzhuo. All rights reserved.
//

#import "VTMagicController.h"

@interface VTMagicController ()

@end

@implementation VTMagicController

#pragma mark - Lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        } else if ([self respondsToSelector:@selector(setWantsFullScreenLayout:)]) {
            [self setValue:@YES forKey:@"wantsFullScreenLayout"];
        }
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    
    self.view = self.magicView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _appearanceState = VTAppearanceStateWillAppear;
    [_currentViewController beginAppearanceTransition:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _appearanceState = VTAppearanceStateDidAppear;
    [_currentViewController endAppearanceTransition];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _appearanceState = VTAppearanceStateWillDisappear;
    [_currentViewController beginAppearanceTransition:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _appearanceState = VTAppearanceStateDidDisappear;
    [_currentViewController endAppearanceTransition];
}

#pragma mark - 禁止自动触发appearance methods
- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}

#pragma mark - functional methods
- (UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex
{
    return [self.magicView viewControllerAtPage:pageIndex];
}

- (void)switchToPage:(NSUInteger)pageIndex animated:(BOOL)animated
{
    [self.magicView switchToPage:pageIndex animated:animated];
}

#pragma mark - VTMagicViewDataSource
- (NSArray<NSString *> *)menuTitlesForMagicView:(VTMagicView *)magicView
{
    return nil;
}

- (UIButton *)magicView:(VTMagicView *)magicView menuItemAtIndex:(NSUInteger)itemIndex
{
    return nil;
}

- (UIViewController *)magicView:(VTMagicView *)magicView viewControllerAtPage:(NSUInteger)pageInde
{
    return nil;
}

#pragma mark - VTMagicViewDelegate
- (void)magicView:(VTMagicView *)magicView viewWillAppear:(UIViewController *)viewController atPage:(NSUInteger)pageIndex
{
    VTLog(@"index:%ld viewControllerWillAppear:%@", (long)pageIndex, viewController.view);
}

- (void)magicView:(VTMagicView *)magicView viewDidAppear:(UIViewController *)viewController atPage:(NSUInteger)pageIndex
{
    VTLog(@"index:%ld viewControllerDidAppear:%@", (long)pageIndex, viewController.view);
}

- (void)magicView:(VTMagicView *)magicView viewDidDisappear:(UIViewController *)viewController atPage:(NSUInteger)pageIndex
{
    VTLog(@"index:%ld viewControllerDidDisappear:%@", (long)pageIndex, viewController.view);
}

- (void)magicView:(VTMagicView *)magicView didSelectItemAtIndex:(NSUInteger)itemIndex
{
    VTLog(@"didSelectItemAtIndex:%ld", (long)itemIndex);
}

#pragma mark - accessor methods
- (VTMagicView *)magicView
{
    if (!_magicView) {
        _magicView = [[VTMagicView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _magicView.autoresizesSubviews = YES;
        _magicView.magicController = self;
        _magicView.delegate = self;
        _magicView.dataSource = self;
        [self.view setNeedsLayout];
    }
    return _magicView;
}

- (NSArray<UIViewController *> *)viewControllers
{
    return self.magicView.viewControllers;
}

- (void)showPacket {

}


@end
