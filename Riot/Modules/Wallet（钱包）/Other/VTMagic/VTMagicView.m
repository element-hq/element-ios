//
//  VTMagicView.m
//  VTMagicView
//
//  Created by tianzhuo on 14-11-11.
//  Copyright (c) 2014年 tianzhuo. All rights reserved.
//

#import "VTMagicView.h"
#import "VTMenuBar.h"
#import "VTMagicController.h"
#import "UIColor+Magic.h"
#import <objc/runtime.h>

typedef struct {
    unsigned int dataSourceMenuItem : 1;
    unsigned int dataSourceMenuTitles : 1;
    unsigned int dataSourceViewController : 1;
    unsigned int viewControllerDidAppear : 1;
    unsigned int viewControllerDidDisappear : 1;
    unsigned int shouldManualForwardAppearanceMethods : 1;
} MagicFlags;

static const void *kVTMagicView = &kVTMagicView;
@implementation UIViewController (VTMagicPrivate)

- (void)setMagicView:(VTMagicView *)magicView
{
    objc_setAssociatedObject(self, kVTMagicView, magicView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (VTMagicView *)magicView
{
    return objc_getAssociatedObject(self, kVTMagicView);
}

@end


@interface VTMagicView()<UIScrollViewDelegate,VTContentViewDataSource,VTMenuBarDatasource,VTMenuBarDelegate>

@property (nonatomic, strong) VTMenuBar *menuBar; // 顶部导航菜单视图
@property (nonatomic, strong) VTContentView *contentView; // 容器视图
@property (nonatomic, strong) UIView *sliderView; // 顶部导航栏滑块
@property (nonatomic, strong) UIView *separatorLine; // 导航模块底部分割线
@property (nonatomic, strong) NSArray *menuTitles; // 顶部分类名数组
@property (nonatomic, assign) NSInteger nextPageIndex; // 下一个页面的索引
@property (nonatomic, assign) NSInteger currentPage; //当前页面的索引
@property (nonatomic, assign) NSInteger previousIndex; // 上一个页面的索引
@property (nonatomic, assign) BOOL isViewWillAppear;
@property (nonatomic, assign) BOOL needSkipUpdate; // 是否是跳页切换
@property (nonatomic, assign) MagicFlags magicFlags;
@property (nonatomic, assign) VTColor normalVTColor;
@property (nonatomic, assign) VTColor selectedVTColor;
@property (nonatomic, strong) UIColor *normalColor; // 顶部item正常的文本颜色
@property (nonatomic, strong) UIColor *selectedColor; // 顶部item被选中时的文本颜色
@property (nonatomic, assign) BOOL isPanValid;

@property (nonatomic, strong) CADisplayLink* displayLink; // 同步屏幕刷新

@property (nonatomic, strong) CAGradientLayer* normalLayer;
@property (nonatomic, strong) CAGradientLayer* nightLayer;

@end

@implementation VTMagicView
@synthesize navigationView = _navigationView;
@synthesize headerView = _headerView;

#pragma mark - lifecycle
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _itemScale = 1.0;
        _previewItems = 1;
        _sliderHeight = 2;
        _headerHeight = 64;
        _bubbleRadius = 10;
        _separatorHeight = 0.5;
        _navigationHeight = 44;
        _headerHidden = YES;
        _scrollEnabled = YES;
        _switchEnabled = YES;
        _switchAnimated = YES;
        _menuScrollEnabled = YES;
        [self addMagicSubviews];
        [self addNotification];
        
    }
    return self;
}

- (void)addMagicSubviews
{
    [self addSubview:self.headerView];
    [self addSubview:self.navigationView];
    [_navigationView addSubview:self.separatorLine];
    [_navigationView addSubview:self.menuBar];
    [_menuBar addSubview:self.sliderView];
    [self addSubview:self.contentView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - layout subviews
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateFrameForSubviews];
    if (CGRectIsEmpty(_sliderView.frame)) {
        [self updateMenuBarState];
    }

}

- (void)updateBarShadow {
    if (!self.nightLayer || !self.normalLayer) {
        return;
    }
    [_navigationView.layer replaceSublayer:self.nightLayer with:self.normalLayer];
}


#pragma mark - 添加阴影
- (void)nightMenuBarShadow{
    if (self.shieldBarShadow) {
        return;
    }
    [_navigationView.layer addSublayer:self.nightLayer];
}


- (CAGradientLayer *)nightLayer {
    if (!_nightLayer) {
        CGFloat h = CGRectGetHeight(_menuBar.bounds)-0.5;
        CGFloat w = 5;
        CGFloat x = CGRectGetWidth(_menuBar.bounds)-w;
        CGFloat y = _menuBar.frame.origin.y;
        
        //设置阴影渐变色
        _nightLayer = [CAGradientLayer layer];
        _nightLayer.frame = CGRectMake(x, y, w, h);
       // [_navigationView.layer addSublayer:_nightLayer];
        
        //设置渐变颜色方向
        _nightLayer.startPoint = CGPointMake(1, 0);
        _nightLayer.endPoint = CGPointMake(0, 0);
        
        //设定颜色组
        _nightLayer.colors = @[ (__bridge id)[UIColor clearColor].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        _menuBar.contentInset = UIEdgeInsetsMake(0, 0, 0, w);
    }
    return _nightLayer;
}


- (CAGradientLayer *)normalLayer {
    if (!_normalLayer) {
        CGFloat h = CGRectGetHeight(_menuBar.bounds)-0.5;
        CGFloat w = 5;
        CGFloat x = CGRectGetWidth(_menuBar.bounds)-w;
        CGFloat y = _menuBar.frame.origin.y;
        
        //设置阴影渐变色
        _normalLayer = [CAGradientLayer layer];
        _normalLayer.frame = CGRectMake(x, y, w, h);
      
        //设置渐变颜色方向
        _normalLayer.startPoint = CGPointMake(1, 0);
        _normalLayer.endPoint = CGPointMake(0, 0);
        
        //设定颜色组
        _normalLayer.colors = @[ (__bridge id)[UIColor clearColor].CGColor, (__bridge id)[UIColor clearColor].CGColor];
        _menuBar.contentInset = UIEdgeInsetsMake(0, 0, 0, w);
    }
    return _normalLayer;
}


- (void)normalMenuBarShadow{
    if (self.shieldBarShadow) {
        return;
    }
    [_navigationView.layer addSublayer:self.normalLayer];
}


- (void)updateFrameForSubviews
{
    CGSize size = self.frame.size;
    CGFloat topY = _againstStatusBar ? StatusSizeH : 0;
    CGFloat headerY = _headerHidden ? -_headerHeight : topY;
    _headerView.frame = CGRectMake(0, headerY, size.width, _headerHeight);
    
    CGFloat navigationY = _headerHidden ? 0 : CGRectGetMaxY(_headerView.frame);
    CGFloat navigationH = _navigationHeight + (_headerHidden ? topY : 0);
    _navigationView.frame = CGRectMake(0, navigationY, size.width, navigationH);
    
    CGFloat separatorY = CGRectGetHeight(_navigationView.frame) - _separatorHeight;
    _separatorLine.frame = CGRectMake(0, separatorY, size.width, _separatorHeight);
    
    CGRect originalMenuFrame = _menuBar.frame;
    CGFloat menuBarY = _headerHidden ? topY : 0;
    CGFloat leftItemWidth = CGRectGetWidth(_leftNavigatoinItem.frame);
    CGFloat rightItemWidth = CGRectGetWidth(_rightNavigatoinItem.frame);
    CGFloat catWidth = size.width - leftItemWidth - rightItemWidth;
    _menuBar.frame = CGRectMake(leftItemWidth, menuBarY, catWidth, _navigationHeight);
    if (!CGRectEqualToRect(_menuBar.frame, originalMenuFrame)) {
        [_menuBar resetItemFrames];
        [self updateMenuBarState];
    }
    
    CGRect sliderFrame = [_menuBar sliderFrameAtIndex:_currentPage];
    _sliderView.frame = sliderFrame;
    
    self.needSkipUpdate = YES;
    CGRect originalContentFrame = _contentView.frame;
    CGFloat contentY = CGRectGetMaxY(_navigationView.frame);
    CGFloat contentH = size.height - contentY + (_needExtendedBottom ? VTTABBAR_HEIGHT : 0);
    _contentView.frame = CGRectMake(0, contentY, size.width, contentH);
    if (!CGRectEqualToRect(_contentView.frame, originalContentFrame)) {
        [_contentView resetPageFrames];
    }
    self.needSkipUpdate = NO;
    
    [self updateFrameForLeftNavigationItem];
    [self updateFrameForRightNavigationItem];
}

- (void)updateFrameForLeftNavigationItem
{
    CGRect leftFrame = _leftNavigatoinItem.bounds;
    CGFloat offset = CGRectGetHeight(leftFrame)/2;
    leftFrame.origin.y = CGRectGetMidY(_navigationView.bounds) - offset;
//    if (_againstStatusBar && _headerHidden) leftFrame.origin.y += 10;
    if (_againstStatusBar && _headerHidden) leftFrame.origin.y += StatusSizeH/2;//适配iPhoneX
    _leftNavigatoinItem.frame = leftFrame;
}

- (void)updateFrameForRightNavigationItem
{
    CGRect rightFrame = _rightNavigatoinItem.bounds;
    CGFloat offset = CGRectGetHeight(rightFrame)/2;
    rightFrame.origin.x = _navigationView.frame.size.width - rightFrame.size.width;
    rightFrame.origin.y = CGRectGetMidY(_navigationView.bounds) - offset;
    if (_againstStatusBar && _headerHidden) rightFrame.origin.y +=  StatusSizeH/2;
    _rightNavigatoinItem.frame = rightFrame;
}

#pragma mark - NSNotification
- (void)addNotification
{
    [self removeNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarOrientationChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)statusBarOrientationChange:(NSNotification *)notification
{
    self.needSkipUpdate = YES;
    [self updateFrameForSubviews];
    [self updateMenuBarState];
    self.needSkipUpdate = NO;
    [self reviseLayout];
}

- (void)reviseLayout
{
    if ([_magicController isKindOfClass:[VTMagicController class]]) return;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.005 * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        [self setNeedsLayout];
    });
}

#pragma mark - functional methods
- (void)reloadData
{
    UIViewController *viewController = [self viewControllerAtPage:_currentPage];
    if (viewController && _magicFlags.viewControllerDidDisappear) {
        [_delegate magicView:self viewDidDisappear:viewController atPage:_currentPage];
    }
    [self viewControllerWillDisappear:_currentPage];
    [self viewControllerDidDisappear:_currentPage];
    
    if (_magicFlags.dataSourceMenuTitles) {
        _menuTitles = [_dataSource menuTitlesForMagicView:self];
        _menuBar.menuTitles = _menuTitles;
    }
    
    BOOL needReset = _menuTitles.count <= _currentPage;
    if (needReset) {
        _currentPage = 0;
        _nextPageIndex = _currentPage;
        _previousIndex = _currentPage;
        _menuBar.currentIndex = _currentPage;
        _contentView.currentPage = _currentPage;
        [_magicController setCurrentViewController:nil];
        [_magicController setCurrentPage:_currentPage];
    }
    
    _switchEvent = VTSwitchEventLoad;
    _contentView.pageCount = _menuTitles.count;
    [_contentView reloadData];
    [_menuBar reloadData];
    [self updateMenuBarState];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)reloadDataToPage:(NSUInteger)page
{
    _currentPage = page;
    _menuBar.currentIndex = page;
    _contentView.currentPage = page;
    [self reloadData];
}

- (UIButton *)dequeueReusableItemWithIdentifier:(NSString *)identifier
{
    UIButton *menuItem = [_menuBar dequeueReusableItemWithIdentifier:identifier];
    [menuItem setTitleColor:_normalColor forState:UIControlStateNormal];
    return menuItem;
}

- (UIViewController *)dequeueReusablePageWithIdentifier:(NSString *)identifier
{
    UIViewController *viewController = [_contentView dequeueReusablePageWithIdentifier:identifier];
    if ([viewController respondsToSelector:@selector(vtm_prepareForReuse)]) {
        [(id<VTMagicReuseProtocol>)viewController vtm_prepareForReuse];
    }
    return viewController;
}

- (UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex
{
    return [_contentView viewControllerAtPage:pageIndex];
}

- (UIButton *)menuItemAtIndex:(NSUInteger)index
{
    return [_menuBar itemAtIndex:index];
}

- (void)updateMenuTitles
{
    if (_magicFlags.dataSourceMenuTitles) {
        _menuTitles = [_dataSource menuTitlesForMagicView:self];
        _menuBar.menuTitles = _menuTitles;
    }
    [_menuBar reloadData];
    if (!_contentView.isDragging) {
        [self updateMenuBarState];
    }
}

- (void)deselectMenuItem
{
    [_menuBar deselectMenuItem];
}

- (void)reselectMenuItem
{
    [_menuBar reselectMenuItem];
}

#pragma mark - switch to specified page
- (void)switchToPage:(NSUInteger)pageIndex animated:(BOOL)animated
{
    if (pageIndex == _currentPage || _menuTitles.count <= pageIndex) return;
    _contentView.currentPage = pageIndex;
    _switchEvent = VTSwitchEventScroll;
    if (animated) {
        [self switchAnimation:pageIndex];
    } else {
        [self switchWithoutAnimation:pageIndex];
    }
}

- (void)switchWithoutAnimation:(NSUInteger)pageIndex
{
    if (_menuTitles.count <= pageIndex) return;
    [_contentView creatViewControllerAtPage:_currentPage];
    [_contentView creatViewControllerAtPage:pageIndex];
    [self subviewWillAppearAtPage:pageIndex];
    CGFloat offset = _contentView.frame.size.width * pageIndex;
    _contentView.contentOffset = CGPointMake(offset, 0);
    _menuBar.currentIndex = pageIndex;
    [self updateMenuBarState];
}

- (void)switchAnimation:(NSUInteger)pageIndex
{
    if (_menuTitles.count <= pageIndex) return;
    NSInteger disIndex = _currentPage;
    CGFloat contentWidth = CGRectGetWidth(_contentView.frame);
    BOOL isNotAdjacent = abs((int)(_currentPage - pageIndex)) > 1;
    if (isNotAdjacent) {// 当前按钮与选中按钮不相邻时
        self.needSkipUpdate = YES;
        _isViewWillAppear = YES;
        [self displayPageHasChanged:pageIndex disIndex:_currentPage];
        [self subviewWillAppearAtPage:pageIndex];
        [self viewControllerDidDisappear:disIndex];
        [_magicController setCurrentViewController:nil];
        NSInteger tempIndex = pageIndex + (_currentPage < pageIndex ? -1 : 1);
        _contentView.contentOffset = CGPointMake(contentWidth * tempIndex, 0);
        _isViewWillAppear = NO;
    } else {
        [self viewControllerWillDisappear:disIndex];
        [self viewControllerWillAppear:pageIndex];
    }
    
    _currentPage = pageIndex;
    _previousIndex = disIndex;
    _menuBar.currentIndex = pageIndex;
    [UIView animateWithDuration:0.25 animations:^{
        [_menuBar updateSelectedItem:YES];
        [self updateMenuBarState];
        _contentView.contentOffset = CGPointMake(contentWidth * pageIndex, 0);
    } completion:^(BOOL finished) {
        [self displayPageHasChanged:_currentPage disIndex:disIndex];
        if (!isNotAdjacent && _currentPage != disIndex) {
            [self viewControllerDidDisappear:disIndex];
        }
        if (pageIndex == _currentPage) {
            [self viewControllerDidAppear:pageIndex];
        }
        self.needSkipUpdate = NO;
    }];
}

- (void)updateMenuBarState
{
    __block CGFloat itemMinX = 0;
    __block CGFloat itemMaxX = 0;
    __block CGRect itemFrame = CGRectZero;
    void (^updateBlock) (NSInteger) = ^(NSInteger itemIndex) {
        if (itemIndex < 0) itemIndex = 0;
        if (_menuTitles.count <= itemIndex) itemIndex = _menuTitles.count - 1;
        itemFrame = [_menuBar itemFrameAtIndex:itemIndex];
        itemMinX = itemFrame.origin.x;
        itemMaxX = CGRectGetMaxX(itemFrame);
    };
    
    // update slider frame
    updateBlock(_currentPage);
    CGRect sliderFrame = [_menuBar sliderFrameAtIndex:_currentPage];
    _sliderView.frame = sliderFrame;
    
    // update contentOffset
    CGFloat menuWidth = _menuBar.frame.size.width;
    CGFloat offsetX = _menuBar.contentOffset.x;
    CGFloat menuOffsetX = offsetX;
    if (itemMaxX < menuOffsetX) {// 位于屏幕左侧
        updateBlock(_currentPage - _previewItems);
        offsetX = itemMinX - menuWidth;
        offsetX = offsetX < 0 ?: 0;
    } else if (menuOffsetX + menuWidth < itemMinX) {// 位于屏幕右侧
        updateBlock(_currentPage + _previewItems);
        offsetX = itemMaxX - menuWidth;
    } else {
        NSInteger itemIndex = _currentPage;
        BOOL needAddition = _previousIndex <= _currentPage;
        if (menuWidth + menuOffsetX <= itemMaxX) needAddition = YES;
        if (itemMinX < menuOffsetX) needAddition = NO;
        itemIndex += needAddition ? _previewItems : -_previewItems;
        updateBlock(itemIndex);
    }
    
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        CGFloat diffX = (CGRectGetMaxX(itemFrame) - menuWidth);
        menuOffsetX = (diffX < 0 || menuOffsetX > diffX) ? menuOffsetX : diffX;
    }
    
    if (menuWidth + menuOffsetX <= itemMaxX) {
        offsetX = itemMaxX - menuWidth;
    } else if (itemMinX < menuOffsetX) {
        offsetX = itemMinX;
    }
    
    if (0 == _currentPage) {
        offsetX = 0;
    } else if (_menuTitles.count - 1 == _currentPage) {
        if (CGRectGetWidth(_menuBar.frame) < _menuBar.contentSize.width) {
            offsetX = _menuBar.contentSize.width - CGRectGetWidth(_menuBar.frame);
        }
    }
    _menuBar.contentOffset = CGPointMake(offsetX, 0);
}

#pragma mark - UIPanGestureRecognizer for webView
static VTPanRecognizerDirection direction = VTPanRecognizerDirectionUndefined;
- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    __unused BOOL isPanGesture = [recognizer isKindOfClass:[UIPanGestureRecognizer class]];
    NSAssert(isPanGesture, @"The Class of recognizer:%@ must be UIPanGestureRecognizer", recognizer);
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            [self handlePanGestureBegin:recognizer];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (VTPanRecognizerDirectionHorizontal == direction) {
                [self handlePanGestureMove:recognizer];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            if (VTPanRecognizerDirectionHorizontal == direction) {
                [self handlePanGestureEnd:recognizer];
            }
            direction = VTPanRecognizerDirectionUndefined;
            break;
        }
        default:
            break;
    }
}

- (void)handlePanGestureBegin:(UIPanGestureRecognizer *)recognizer
{
    if (direction != VTPanRecognizerDirectionUndefined) return;
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    BOOL isHorizontalGesture = fabs(velocity.y) < fabs(velocity.x);
    if (isHorizontalGesture) {
        direction = VTPanRecognizerDirectionHorizontal;
        [self handlePanGestureMove:recognizer];
    } else {
        direction = VTPanRecognizerDirectionVertical;
    }
}

- (void)handlePanGestureMove:(UIPanGestureRecognizer *)recognizer
{
    _isPanValid = YES;
    CGPoint offset = _contentView.contentOffset;
    CGFloat contentWidth = CGRectGetWidth(_contentView.frame);
    CGFloat maxOffset = _contentView.contentSize.width - contentWidth;
    CGPoint translation = [recognizer translationInView:_contentView];
    [recognizer setTranslation:CGPointZero inView:_contentView];
    offset.x -= translation.x;
    if (maxOffset < offset.x) offset.x = maxOffset;
    if (offset.x < 0) offset.x = 0;
    _contentView.contentOffset = offset;
}

- (void)handlePanGestureEnd:(UIPanGestureRecognizer *)recognizer
{
    _isPanValid = NO;
    CGFloat contentWidth = CGRectGetWidth(_contentView.frame);
    CGPoint velocity = [recognizer velocityInView:_contentView];
    if (contentWidth < fabs(velocity.x)) {
        [self autoSwitchToNextPage:velocity.x < 0];
    } else {
        [self reviseAnimation];
    }
}

- (void)autoSwitchToNextPage:(BOOL)isNextPage
{
    CGFloat offsetX = _contentView.contentOffset.x;
    CGFloat contentWidth = CGRectGetWidth(_contentView.frame);
    NSInteger index = (NSInteger)(offsetX/contentWidth);
    if (!isNextPage) index = ceil(offsetX/contentWidth);
    index += isNextPage ? 1 : -1;
    NSInteger totalCount = _menuTitles.count;
    if (totalCount <= index) index = totalCount - 1;
    if (index < 0) index = 0;
    CGPoint offset = CGPointMake(contentWidth*index, 0);
    [UIView animateWithDuration:0.35 animations:^{
        [_contentView setContentOffset:offset animated:NO];
    }];
}

- (void)reviseAnimation
{
    CGFloat offsetX = _contentView.contentOffset.x;
    CGFloat scrollWidth = CGRectGetWidth(_contentView.frame);
    NSInteger index = nearbyint(offsetX/scrollWidth);
    NSInteger totalCount = _menuTitles.count;
    if (totalCount <= index) index = totalCount - 1;
    CGFloat contentWidth = CGRectGetWidth(_contentView.frame);
    [_contentView setContentOffset:CGPointMake(contentWidth * index, 0) animated:YES];
}

#pragma mark - 当前页面控制器改变时触发，传递disappearViewController & appearViewController
- (void)displayPageHasChanged:(NSInteger)pageIndex disIndex:(NSInteger)disIndex
{
    _menuBar.currentIndex = pageIndex;
    UIViewController *appearViewController = [self autoCreateViewControllAtPage:pageIndex];
    UIViewController *disappearViewController = [self autoCreateViewControllAtPage:disIndex];
    
    if (appearViewController) {
        [_magicController setCurrentPage:pageIndex];
        [_magicController setCurrentViewController:appearViewController];
    }
    
    if (disappearViewController && _magicFlags.viewControllerDidDisappear) {
        [_delegate magicView:self viewDidDisappear:disappearViewController atPage:disIndex];
    }
    
    if (appearViewController && _magicFlags.viewControllerDidAppear) {
        [_delegate magicView:self viewDidAppear:appearViewController atPage:pageIndex];
    }
}

- (UIViewController *)autoCreateViewControllAtPage:(NSInteger)pageIndex
{
    return [_contentView viewControllerAtPage:pageIndex autoCreate:!_needSkipUpdate];
}

#pragma mark - change color
- (void)graduallyChangeColor
{
    
    if (self.isDeselected) return;
    if (VTColorIsZero(_normalVTColor) && VTColorIsZero(_selectedVTColor)) return;
    CGFloat scale = _contentView.contentOffset.x/_contentView.frame.size.width - _currentPage;
    CGFloat absScale = ABS(scale);
    UIColor *nextColor = [UIColor vtm_compositeColor:_normalVTColor anoColor:_selectedVTColor scale:absScale];
    UIColor *selectedColor = [UIColor vtm_compositeColor:_selectedVTColor anoColor:_normalVTColor scale:absScale];
    UIButton *currentItem = [_menuBar itemAtIndex:_currentPage];
    [currentItem setTitleColor:selectedColor forState:UIControlStateSelected];
    UIButton *nextItem = [_menuBar itemAtIndex:_nextPageIndex];
    [nextItem setTitleColor:nextColor forState:UIControlStateNormal];
    
    CGRect nextFrame  = [_menuBar sliderFrameAtIndex:_nextPageIndex];
    CGRect currentFrame = [_menuBar sliderFrameAtIndex:_currentPage];
    CGRect sliderFrame = _sliderView.frame;
    CGFloat nextWidth = nextFrame.size.width;
    CGFloat currentWidth = currentFrame.size.width;
    sliderFrame.size.width = currentWidth - (currentWidth - nextWidth) * absScale;
    CGFloat offset = ABS(currentFrame.origin.x - nextFrame.origin.x) * scale;
    sliderFrame.origin.x = currentFrame.origin.x + offset;
    _sliderView.frame = sliderFrame;
    
    if (1.0 == _itemScale || 0 == absScale) return;
    CGFloat nextScale = 1.0 + absScale * (_itemScale - 1);
    CGFloat currentScale = 1.0 + (1 - absScale) * (_itemScale - 1);
    currentItem.titleLabel.layer.transform = CATransform3DMakeScale(currentScale, currentScale, currentScale);
    nextItem.titleLabel.layer.transform = CATransform3DMakeScale(nextScale, nextScale, nextScale);
}

- (void)resetMenuItemColor
{
    UIButton *currentItem = [_menuBar itemAtIndex:_currentPage];
    [currentItem setTitleColor:_selectedColor forState:UIControlStateSelected];
    UIButton *nextItem = [_menuBar itemAtIndex:_nextPageIndex];
    [nextItem setTitleColor:_normalColor forState:UIControlStateNormal];
}

#pragma mark - VTMenuBarDatasource & VTMenuBarDelegate
- (UIButton *)menuBar:(VTMenuBar *)menuBar menuItemAtIndex:(NSUInteger)index
{
    if (!_magicFlags.dataSourceMenuItem) return nil;
    UIButton *menuItem = [_dataSource magicView:self menuItemAtIndex:index];
    [menuItem setTitle:_menuTitles[index] forState:UIControlStateNormal];
    if (VTColorIsZero(_normalVTColor)) {
        _normalColor = [menuItem titleColorForState:UIControlStateNormal];
        _normalVTColor = [_normalColor vtm_changeToVTColor];
    }
    if (VTColorIsZero(_selectedVTColor)) {
        _selectedColor = [menuItem titleColorForState:UIControlStateSelected];
        _selectedVTColor = [_selectedColor vtm_changeToVTColor];
    }
    return menuItem;
}

- (void)menuBar:(VTMenuBar *)menuBar didSelectItemAtIndex:(NSUInteger)itemIndex
{
    if (!_switchEnabled) return;
    if ([_delegate respondsToSelector:@selector(magicView:didSelectItemAtIndex:)]) {
        [_delegate magicView:self didSelectItemAtIndex:itemIndex];
    }
    
    if (itemIndex == _menuBar.currentIndex) return;
    [self resetMenuItemColor];
    _switchEvent = VTSwitchEventClick;
    if (_switchAnimated) {
        [self switchAnimation:itemIndex];
    } else {
        [self switchWithoutAnimation:itemIndex];
    }
}

- (CGFloat)menuBar:(VTMenuBar *)menuBar itemWidthAtIndex:(NSUInteger)itemIndex {
    if ([_delegate respondsToSelector:@selector(magicView:itemWidthAtIndex:)]) {
        return [_delegate magicView:self itemWidthAtIndex:itemIndex];
    }
    return 0;
}

- (CGFloat)menuBar:(VTMenuBar *)menuBar sliderWidthAtIndex:(NSUInteger)itemIndex {
    if ([_delegate respondsToSelector:@selector(magicView:sliderWidthAtIndex:)]) {
        return [_delegate magicView:self sliderWidthAtIndex:itemIndex];
    }
    return 0;
}
#pragma mark - VTContentViewDataSource
- (UIViewController *)contentView:(VTContentView *)contentView viewControllerAtPage:(NSUInteger)pageIndex
{
    if (!_magicFlags.dataSourceViewController) return nil;
    UIViewController *viewController = [_dataSource magicView:self viewControllerAtPage:pageIndex];
    if (viewController && ![viewController.parentViewController isEqual:_magicController]) {
        [_magicController addChildViewController:viewController];
        [contentView addSubview:viewController.view];
        [viewController didMoveToParentViewController:_magicController];
        // 设置默认的currentViewController，并触发viewDidAppear
        if (pageIndex == _currentPage && VTSwitchEventLoad == _switchEvent) {
            [_magicController setCurrentViewController:viewController];
            if (_magicFlags.viewControllerDidAppear) {
                [_delegate magicView:self viewDidAppear:viewController atPage:_currentPage];
            }
            if ([self shouldForwardAppearanceMethods]) {
                [viewController beginAppearanceTransition:YES animated:YES];
                [viewController endAppearanceTransition];
            }
        }
    }
    return viewController;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (_menuBar.isTracking) {
        _contentView.scrollEnabled = NO;
    } else if (_contentView.isTracking) {
        _menuBar.needSkipLayout = 1.0 != _itemScale;
        _switchEvent = VTSwitchEventScroll;
        _menuBar.scrollEnabled = NO;
        _isViewWillAppear = NO;
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger newIndex;
    NSInteger tempIndex;
    if (![scrollView isEqual:_contentView]) return;
    if (_needSkipUpdate || CGRectIsEmpty(self.frame)) return;
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat scrollWidth = scrollView.frame.size.width;
    BOOL isSwipeToLeft = scrollWidth * _currentPage < offsetX;
    if (isSwipeToLeft) { // 向左滑动
        newIndex = floorf(offsetX/scrollWidth);
        tempIndex = (int)((offsetX + scrollWidth - 0.1)/scrollWidth);
    } else {
        newIndex = ceilf(offsetX/scrollWidth);
        tempIndex = (int)(offsetX/scrollWidth);
    }
    
    //DLog(@"scrollViewDidScroll newIndex:%ld,tempIndex:%ld",(long)newIndex,(long)tempIndex);
    
    if (!_needSkipUpdate && newIndex != _currentPage) {
        self.currentPage = newIndex;
        switch (_switchStyle) {
            case VTSwitchStyleStiff:
                [self updateMenuBarWhenUserScrolled];
                break;
            default:
                [self updateItemStateForDefaultStyle];
                break;
        }
    }
    
    if (_nextPageIndex != tempIndex) _isViewWillAppear = NO;
    if (!_isViewWillAppear && newIndex != tempIndex) {
        _isViewWillAppear = YES;
        NSInteger nextPageIndex = newIndex + (isSwipeToLeft ? 1 : -1);
        [self subviewWillAppearAtPage:nextPageIndex];
    }
    
    if (tempIndex == _currentPage) { // 重置_nextPageIndex
        if (_nextPageIndex != _currentPage && VTSwitchEventScroll == _switchEvent) {
            [self viewControllerWillDisappear:_nextPageIndex];
            [self viewControllerWillAppear:_currentPage];
            [self viewControllerDidDisappear:_nextPageIndex];
            [self viewControllerDidAppear:_currentPage];
        }
        _nextPageIndex = _currentPage;
    }
    
    if (!_needSkipUpdate && VTSwitchStyleDefault == _switchStyle) {
        [self graduallyChangeColor];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    _menuBar.scrollEnabled = _menuScrollEnabled;
    _contentView.scrollEnabled = _scrollEnabled;
    
    if (!decelerate) {
//        VTLog(@"scrollViewDidEndDragging");
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (![scrollView isEqual:_contentView]) return;
    if (VTSwitchEventClick == _switchEvent) {
        CGFloat contentWidth = CGRectGetWidth(_contentView.frame);
        CGPoint offset = CGPointMake(contentWidth * _currentPage, 0);
        [_contentView setContentOffset:offset animated:YES];
    }
    if (VTSwitchStyleDefault == _switchStyle) {
        if (_isPanValid) return;
        [self updateMenuBarWhenUserScrolled];
    }
}

- (void)updateMenuBarWhenUserScrolled
{
    

    if (_displayLink != nil) {
        return;
    }

    //创建同步刷新器
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateViewWithDisp)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    
    _menuBar.needSkipLayout = NO;
    [UIView animateWithDuration:0.1 animations:^{
        [_menuBar updateSelectedItem:YES];
        [self updateMenuBarState];
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //停止同步刷新器
            [_displayLink invalidate];
            _displayLink = nil;
            [self.menuBar setNeedsLayout];
        });
    }];
    
    
}

- (void)updateItemStateForDefaultStyle
{
    UIButton *seletedItem = [_menuBar selectedItem];
    UIButton *menuItem = [_menuBar itemAtIndex:_currentPage];
    [menuItem setTitleColor:_normalColor forState:UIControlStateNormal];
    [seletedItem setTitleColor:_selectedColor forState:UIControlStateSelected];
    [_menuBar updateSelectedItem:NO];
}

/**
 屏幕同步刷新回调
 */
- (void)updateViewWithDisp{
    
    [self.menuBar setNeedsLayout];
    
}
#pragma mark - 视图即将显示
- (void)subviewWillAppearAtPage:(NSInteger)pageIndex
{
    if (_nextPageIndex == pageIndex) return;
    if (_contentView.isDragging && 1 < ABS(_nextPageIndex - pageIndex)) {
        [self viewControllerWillDisappear:_nextPageIndex];
        [self viewControllerDidDisappear:_nextPageIndex];
    }
    [self viewControllerWillDisappear:_currentPage];
    [self viewControllerWillAppear:pageIndex];
    _nextPageIndex = pageIndex;
}

#pragma mark - the life cycle of view controller
- (void)viewControllerWillAppear:(NSUInteger)pageIndex
{
    if (![self shouldForwardAppearanceMethods]) return;
    UIViewController *viewController = [_contentView viewControllerAtPage:pageIndex autoCreate:YES];
    if ([_delegate respondsToSelector:@selector(magicView:viewWillAppear:atPage:)]) {
        [_delegate magicView:self viewWillAppear:viewController atPage:pageIndex];
    }
    [viewController beginAppearanceTransition:YES animated:YES];
}

- (void)viewControllerDidAppear:(NSUInteger)pageIndex
{
    if (![self shouldForwardAppearanceMethods]) return;
    UIViewController *viewController = [self viewControllerAtPage:pageIndex];
    [viewController endAppearanceTransition];
}

- (void)viewControllerWillDisappear:(NSUInteger)pageIndex
{
    if (![self shouldForwardAppearanceMethods]) return;
    UIViewController *viewController = [self viewControllerAtPage:pageIndex];
    [viewController beginAppearanceTransition:NO animated:YES];
}

- (void)viewControllerDidDisappear:(NSUInteger)pageIndex
{
    if (![self shouldForwardAppearanceMethods]) return;
    UIViewController *viewController = [self viewControllerAtPage:pageIndex];
    [viewController endAppearanceTransition];
}

- (BOOL)shouldForwardAppearanceMethods
{
    return _magicFlags.shouldManualForwardAppearanceMethods &&
      VTAppearanceStateDidAppear == _magicController.appearanceState;
}

#pragma mark - accessor methods
#pragma mark subviews
- (UIView *)headerView
{
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.backgroundColor = [UIColor clearColor];
        _headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _headerView.hidden = _headerHidden;
    }
    return _headerView;
}

- (UIView *)navigationView
{
    if (!_navigationView) {
        _navigationView = [[UIView alloc] init];
        _navigationView.backgroundColor = [UIColor clearColor];
        _navigationView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _navigationView.clipsToBounds = YES;
    }
    return _navigationView;
}

- (UIView *)separatorLine
{
    if (!_separatorLine) {
        _separatorLine = [[UIView alloc] init];
        _separatorLine.backgroundColor = RGBCOLOR(188, 188, 188);
        _separatorLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return _separatorLine;
}

- (UIView *)sliderView
{
    if (!_sliderView) {
        _sliderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, _sliderHeight)];
        _sliderView.backgroundColor = RGBCOLOR(194, 39, 39);
    }
    return _sliderView;
}

- (VTMenuBar *)menuBar
{
    if (!_menuBar) {
        _menuBar = [[VTMenuBar alloc] init];
        _menuBar.backgroundColor = [UIColor clearColor];
        _menuBar.showsHorizontalScrollIndicator = NO;
        _menuBar.showsVerticalScrollIndicator = NO;
        _menuBar.clipsToBounds = YES;
        _menuBar.scrollsToTop = NO;
        _menuBar.datasource = self;
        _menuBar.delegate = self;
    }
    return _menuBar;
}

- (VTContentView *)contentView
{
    if (!_contentView) {
        _contentView = [[VTContentView alloc] init];
        _contentView.showsVerticalScrollIndicator = NO;
        _contentView.showsHorizontalScrollIndicator = NO;
        _contentView.pagingEnabled = YES;
        _contentView.delegate = self;
        _contentView.dataSource = self;
        _contentView.scrollsToTop = NO;
        _contentView.bounces = NO;
    }
    return _contentView;
}

- (void)setLeftNavigatoinItem:(UIView *)leftNavigatoinItem
{
    _leftNavigatoinItem = leftNavigatoinItem;
    [_navigationView addSubview:leftNavigatoinItem];
    [_navigationView bringSubviewToFront:_separatorLine];
    [_navigationView bringSubviewToFront:_menuBar];
    [_navigationView bringSubviewToFront:_leftNavigatoinItem];
    leftNavigatoinItem.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [self updateFrameForLeftNavigationItem];
}

- (void)setRightNavigatoinItem:(UIView *)rightNavigatoinItem
{
    _rightNavigatoinItem = rightNavigatoinItem;
    [_navigationView addSubview:rightNavigatoinItem];
    [_navigationView bringSubviewToFront:_separatorLine];
    [_navigationView bringSubviewToFront:_menuBar];
    
    [_navigationView bringSubviewToFront:_rightNavigatoinItem];
    
    rightNavigatoinItem.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self updateFrameForRightNavigationItem];
}

- (NSArray<UIViewController *> *)viewControllers
{
    return [_contentView visibleList];
}

#pragma mark basic configurations
- (void)setDataSource:(id<VTMagicViewDataSource>)dataSource
{
    _dataSource = dataSource;
    _magicFlags.dataSourceMenuTitles = [dataSource respondsToSelector:@selector(menuTitlesForMagicView:)];
    _magicFlags.dataSourceMenuItem = [dataSource respondsToSelector:@selector(magicView:menuItemAtIndex:)];
    _magicFlags.dataSourceViewController = [dataSource respondsToSelector:@selector(magicView:viewControllerAtPage:)];
}

- (void)setDelegate:(id<VTMagicViewDelegate>)delegate
{
    _delegate = delegate;
    _magicFlags.viewControllerDidAppear = [delegate respondsToSelector:@selector(magicView:viewDidAppear:atPage:)];
    _magicFlags.viewControllerDidDisappear = [delegate respondsToSelector:@selector(magicView:viewDidDisappear:atPage:)];
    if (!_magicController && [_delegate isKindOfClass:[UIViewController class]] && [delegate conformsToProtocol:@protocol(VTMagicProtocol)]) {
        self.magicController = (UIViewController<VTMagicProtocol> *)delegate;
    }
}

- (void)setMagicController:(UIViewController<VTMagicProtocol> *)magicController
{
    _magicController = magicController;
    if (!_magicController.magicView) [_magicController setMagicView:self];
    if ([magicController respondsToSelector:@selector(shouldAutomaticallyForwardAppearanceMethods)]) {
        _magicFlags.shouldManualForwardAppearanceMethods = ![magicController shouldAutomaticallyForwardAppearanceMethods];
    }
}

- (void)setLayoutStyle:(VTLayoutStyle)layoutStyle
{
    _layoutStyle = layoutStyle;
    _menuBar.layoutStyle = layoutStyle;
}

- (void)setSliderStyle:(VTSliderStyle)sliderStyle
{
    _sliderStyle = sliderStyle;
    _menuBar.sliderStyle = sliderStyle;
    self.sliderView.backgroundColor = _sliderColor ?: RGBCOLOR(229, 229, 229);
    self.bubbleRadius = _bubbleRadius;
}

- (void)setCurrentPage:(NSInteger)currentPage
{

    if (currentPage < 0) return;
    NSInteger disIndex = _currentPage;
    _currentPage = currentPage;
    _previousIndex = disIndex;
    
    if (VTSwitchEventScroll != _switchEvent) return;
    [self displayPageHasChanged:currentPage disIndex:disIndex];
    [self viewControllerDidDisappear:disIndex];
    [self viewControllerDidAppear:currentPage];
}

#pragma mark bool configurations
- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    _contentView.scrollEnabled = scrollEnabled;
}

- (void)setMenuScrollEnabled:(BOOL)menuScrollEnabled
{
    _menuScrollEnabled = menuScrollEnabled;
    _menuBar.scrollEnabled = menuScrollEnabled;
}

- (void)setSwitchEnabled:(BOOL)switchEnabled
{
    _switchEnabled = switchEnabled;
    _menuBar.scrollEnabled = switchEnabled;
    self.scrollEnabled = switchEnabled;
}

- (void)setSliderHidden:(BOOL)sliderHidden
{
    _sliderHidden = sliderHidden;
    _sliderView.hidden = sliderHidden;
}

- (void)setSeparatorHidden:(BOOL)separatorHidden
{
    _separatorHidden = separatorHidden;
    _separatorLine.hidden = separatorHidden;
}

- (void)setBounces:(BOOL)bounces
{
    _bounces = bounces;
    _contentView.bounces = bounces;
}

- (void)setNeedExtendedBottom:(BOOL)needExtendedBottom
{
    _needExtendedBottom = needExtendedBottom;
    [self updateFrameForSubviews];
}

- (BOOL)isDeselected
{
    return [_menuBar isDeselected];
}

- (void)setAgainstStatusBar:(BOOL)againstStatusBar
{
    _againstStatusBar = againstStatusBar;
    [self setNeedsLayout];
}

- (void)setHeaderHidden:(BOOL)headerHidden
{
    _headerHidden = headerHidden;
    _headerView.hidden = headerHidden;
    [self updateFrameForSubviews];
}

- (void)setHeaderHidden:(BOOL)headerHidden duration:(CGFloat)duration
{
    _headerView.hidden = NO;
    _headerHidden = headerHidden;
    [UIView animateWithDuration:duration animations:^{
        [self updateFrameForSubviews];
    } completion:^(BOOL finished) {
        _headerView.hidden = _headerHidden;
    }];
}

#pragma mark color & size configurations
- (void)setNavigationInset:(UIEdgeInsets)navigationInset
{
    _navigationInset = navigationInset;
    _menuBar.menuInset = navigationInset;
}

- (void)setNavigationColor:(UIColor *)navigationColor
{
    _navigationColor = navigationColor;
    _navigationView.backgroundColor = navigationColor;
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    _separatorLine.backgroundColor = separatorColor;
}

- (void)setSliderColor:(UIColor *)sliderColor
{
    _sliderColor = sliderColor;
    _sliderView.backgroundColor = sliderColor;
}

- (void)setSliderWidth:(CGFloat)sliderWidth
{
    _sliderWidth = sliderWidth;
    _menuBar.sliderWidth = sliderWidth;
}

- (void)setSliderHeight:(CGFloat)sliderHeight
{
    _sliderHeight = sliderHeight;
    _menuBar.sliderHeight = sliderHeight;
}

- (CGFloat)sliderExtension
{
    return [_menuBar sliderExtension];
}

- (void)setSliderExtension:(CGFloat)sliderExtension
{
    _menuBar.sliderExtension = sliderExtension;
}

- (void)setSliderOffset:(CGFloat)sliderOffset
{
    _sliderOffset = sliderOffset;
    _menuBar.sliderOffset = sliderOffset;
}

- (void)setBubbleInset:(UIEdgeInsets)bubbleInset
{
    [_menuBar setBubbleInset:bubbleInset];
}

- (UIEdgeInsets)bubbleInset
{
    return [_menuBar bubbleInset];
}

- (void)setBubbleRadius:(CGFloat)bubbleRadius
{
    _bubbleRadius = bubbleRadius;
    self.sliderView.layer.cornerRadius = bubbleRadius;
    self.sliderView.layer.masksToBounds = YES;
}

- (void)setItemSpacing:(CGFloat)itemSpacing
{
    _itemSpacing = itemSpacing;
    _menuBar.itemSpacing = itemSpacing;
}

- (void)setItemScale:(CGFloat)itemScale
{
    _itemScale = itemScale;
    _menuBar.itemScale = itemScale;
}

- (void)setItemWidth:(CGFloat)itemWidth
{
    _itemWidth = itemWidth;
    _menuBar.itemWidth = itemWidth;
}

- (UIButton *)cacheBar {
    UIButton *menuBar = [self.menuBar viewWithTag:1000+2];
    return menuBar;
}

//- (CADisplayLink*)displayLink{
//    if (!_displayLink) {
//        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateViewWithDisp)];
//        _displayLink.paused = YES;
//        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//    }
//    return _displayLink;
//}
@end
