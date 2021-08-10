//
//  SCTextLineSegmentControl.m
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/19.
//

#import "SCTextLineSegmentControl.h"
#import "SCSegmentControl.h"
#import "SCSegmentControlLineIndicator.h"
#import "NSArray+SCSafeArray.h"
#import "SCTextLineSegmentCell.h"

static NSString *const kSCTextLineSegmentCellKey = @"kSCTextLineSegmentCellKey";

@interface SCTextLineSegmentControl () <
SCSegmentControlDataSource,
SCSegmentControlDelegate
>

@property (nonatomic, strong) SCSegmentControl *segmentControl;
@property (nonatomic, strong) UIScrollView *indicatorScrollView;
@property (nonatomic, strong) SCSegmentControlLineIndicator *indicator;
@property (nonatomic, strong) CAGradientLayer *indicatorGradientLayer;

@end

@implementation SCTextLineSegmentControl

@synthesize scrollToCenter = _scrollToCenter;
@synthesize contentInset = _contentInset;
@synthesize currentIndex = _currentIndex;
@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        [self addObserver];
    }
    return self;
}

#pragma mark - Override Functions

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.segmentControl.frame = self.bounds;
    self.indicatorScrollView.frame = CGRectMake(0, self.frame.size.height - self.indicatorHeight - self.indicatorBottomSpace, self.bounds.size.width, self.indicatorHeight);
    self.indicator.frame = CGRectMake(0, 0, self.indicatorStyle == SCTextLineIndicatorStyleRegular ? self.indicatorRegularWidth : [self segmentControl:self.segmentControl widthForItemAtIndex:self.segmentControl.currentIndex], self.indicatorHeight);
    self.indicatorGradientLayer.frame = self.indicator.bounds;
}

#pragma mark - Public Functions

- (void)setupIndicatorGradientWithColors:(NSArray *)indicatorGradientColors startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint locations:(NSArray<NSNumber *> *)locations {
    if (self.indicatorGradientLayer) {
        [self.indicatorGradientLayer removeFromSuperlayer];
    }
    
    self.indicatorGradientLayer = [CAGradientLayer layer];
    self.indicatorGradientLayer.colors = indicatorGradientColors;
    self.indicatorGradientLayer.startPoint = startPoint;
    self.indicatorGradientLayer.endPoint = endPoint;
    self.indicatorGradientLayer.locations = locations;
    [self.indicator.layer insertSublayer:self.indicatorGradientLayer atIndex:0];
    
    [self setNeedsLayout];
}

#pragma mark - SCSegmentControlProtocol

- (void)processDataSource {
    [self.segmentControl processDataSource];
}

- (void)reloadData {
    [self.segmentControl reloadData];
}

- (void)setupSelectedIndex:(NSInteger)selectedIndex {
    [self.segmentControl setupSelectedIndex:selectedIndex];
}

- (void)registerNib:(UINib *)nib forSegmentControlItemWithReuseIdentifier:(NSString *)identifier {
    [self.segmentControl registerNib:nib forSegmentControlItemWithReuseIdentifier:identifier];
}

- (void)registerClass:(Class)cellClass forSegmentControlItemWithReuseIdentifier:(NSString *)identifier {
    [self.segmentControl registerClass:cellClass forSegmentControlItemWithReuseIdentifier:identifier];
}

- (UICollectionViewCell *)dequeueReusableSegmentControlItemWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    return [self.segmentControl dequeueReusableSegmentControlItemWithReuseIdentifier:identifier forIndex:index];
}

#pragma mark - Private Functions

- (void)commonInit {
    _normalItemTitleFont = [UIFont systemFontOfSize:15];
    _normalItemTitleColor = UIColor.blackColor;
    _selectItemTitleFont = [UIFont boldSystemFontOfSize:20];
    _selectItemTitleColor = UIColor.orangeColor;
    _indicatorHeight = 4;
    _indicatorRegularWidth = 50;
    _indicatorBackgroundColor = UIColor.orangeColor;
    
    [self addSubview:self.segmentControl];
    [self addSubview:self.indicatorScrollView];
    [self.indicatorScrollView addSubview:self.indicator];
}

#pragma mark - KVO

- (void)addObserver {
    [self.segmentControl addObserver:self forKeyPath:@"scrollContentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.segmentControl addObserver:self forKeyPath:@"scrollContentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isEqual:self.segmentControl] && [keyPath isEqualToString:@"scrollContentSize"]) {
        CGSize segmentControlContentSize = [change[NSKeyValueChangeNewKey] CGSizeValue];
        self.indicatorScrollView.contentSize = CGSizeMake(segmentControlContentSize.width, self.indicatorHeight);
    } else if ([object isEqual:self.segmentControl] && [keyPath isEqualToString:@"scrollContentOffset"]) {
        CGPoint segmentControlContentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        self.indicatorScrollView.contentOffset = CGPointMake(segmentControlContentOffset.x, 0);
    }
}

#pragma mark - SCSegmentControlDataSource

- (NSInteger)numberOfItemsInSegmentControl:(UIView *)segmentControl {
    return [self.dataSource numberOfItemsInSegmentControl:self];
}

- (UICollectionViewCell *)segmentControl:(UIView *)segmentControl cellForItemAtIndex:(NSInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(segmentControl:cellForItemAtIndex:)]) {
        UICollectionViewCell *cell = [self.dataSource segmentControl:self cellForItemAtIndex:index];
        NSAssert(!cell, @"segmentControl:cellForItemAtIndex return cell is nil");
        if (cell) {
            if (self.currentIndex == index) {
                [self indicatorAnimationWithCell:cell];
            }
            return cell;
        }
    }
    
    SCTextLineSegmentCell *textLineCell = (SCTextLineSegmentCell *)[self.segmentControl dequeueReusableSegmentControlItemWithReuseIdentifier:kSCTextLineSegmentCellKey forIndex:index];
    textLineCell.titleLabel.text = [self.titles sc_safeObjectAtIndex:index];
    BOOL isSelectedItem = self.segmentControl.currentIndex == index;
    textLineCell.titleLabel.font = isSelectedItem ? self.selectItemTitleFont : self.normalItemTitleFont;
    textLineCell.titleLabel.textColor = isSelectedItem ? self.selectItemTitleColor : self.normalItemTitleColor;
    
    if (self.currentIndex == index) {
        [self indicatorAnimationWithCell:textLineCell];
    }
    
    return textLineCell;
}

- (void)indicatorAnimationWithCell:(UICollectionViewCell *)cell {
    if (!cell) {
        return;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect rect = self.indicator.frame;
        rect.origin.x = cell.frame.origin.x + (self.indicatorStyle == SCTextLineIndicatorStyleRegular ? ((cell.frame.size.width - self.indicatorRegularWidth) * 0.5) : 0);
        rect.size.width = self.indicatorStyle == SCTextLineIndicatorStyleRegular ? self.indicatorRegularWidth : cell.frame.size.width;
        self.indicator.frame = rect;
    }];
}

- (CGFloat)itemSpacingInSegmentControl:(UIView *)segmentControl {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(itemSpacingInSegmentControl:)]) {
        return [self.dataSource itemSpacingInSegmentControl:self];
    }
    
    return 0;
}

- (CGFloat)segmentControl:(UIView *)segmentControl widthForItemAtIndex:(NSInteger)index {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(segmentControl:widthForItemAtIndex:)]) {
        return [self.dataSource segmentControl:self widthForItemAtIndex:index];
    }
    
    NSString *title = [self.titles sc_safeObjectAtIndex:index];
    if (!title) {
        return 0;
    }
    
    CGFloat width = ceil([title boundingRectWithSize:CGSizeMake(0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : self.segmentControl.currentIndex == index ? self.selectItemTitleFont : self.normalItemTitleFont} context:nil].size.width);
    
    return width;
}

#pragma mark - Delegate

- (void)segmentControl:(UIView *)segmentControl didSelectItemAtIndex:(NSInteger)currentItemIndex {
    
    [self.segmentControl reloadData];
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentControl:didSelectItemAtIndex:)]) {
        [self.delegate segmentControl:self didSelectItemAtIndex:currentItemIndex];
    }
}

#pragma mark - Getter

- (NSInteger)currentIndex {
    return self.segmentControl.currentIndex;
}

#pragma mark - Setter

- (void)setScrollToCenter:(BOOL)scrollToCenter {
    _scrollToCenter = scrollToCenter;
    self.segmentControl.scrollToCenter = scrollToCenter;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    
    self.segmentControl.contentInset = contentInset;
    self.indicatorScrollView.contentInset = contentInset;
}

- (void)setHideIndicator:(BOOL)hideIndicator {
    _hideIndicator = hideIndicator;
    
    self.indicator.hidden = hideIndicator;
}

- (void)setIndicatorHeight:(CGFloat)indicatorHeight {
    _indicatorHeight = indicatorHeight;
    
    [self setNeedsLayout];
}

- (void)setIndicatorBottomSpace:(CGFloat)indicatorBottomSpace {
    _indicatorBottomSpace = indicatorBottomSpace;
    
    [self setNeedsLayout];
}

- (void)setIndicatorRegularWidth:(CGFloat)indicatorRegularWidth {
    if (self.indicatorStyle != SCTextLineIndicatorStyleRegular) {
        return;
    }
    
    _indicatorRegularWidth = indicatorRegularWidth;
    
    [self setNeedsLayout];
}

- (void)setIndicatorStyle:(SCTextLineIndicatorStyle)indicatorStyle {
    _indicatorStyle = indicatorStyle;
    
    [self setNeedsLayout];
}

- (void)setIndicatorCorner:(CGFloat)indicatorCorner {
    _indicatorCorner = indicatorCorner;
    
    self.indicator.layer.cornerRadius = indicatorCorner;
    self.indicator.clipsToBounds = YES;
}

- (void)setIndicatorBackgroundColor:(UIColor *)indicatorBackgroundColor {
    _indicatorBackgroundColor = indicatorBackgroundColor;
    
    self.indicator.backgroundColor = indicatorBackgroundColor;
}

- (void)setIndicatorLayer:(CALayer *)indicatorLayer {
    _indicatorLayer = indicatorLayer;
    self.indicator.indicatorLayer = indicatorLayer;
}

- (void)setIndicatorView:(UIView *)indicatorView {
    _indicatorView = indicatorView;
    self.indicator.indicatorView = indicatorView;
}

- (void)setIndicatorImage:(UIImage *)indicatorImage {
    _indicatorImage = indicatorImage;
    self.indicator.indicatorImage = indicatorImage;
}

- (void)setIndicatorImageViewMode:(UIViewContentMode)indicatorImageViewMode {
    _indicatorImageViewMode = indicatorImageViewMode;
    self.indicator.indicatorImageViewMode = indicatorImageViewMode;
}

#pragma mark - Lazy Load

- (SCSegmentControl *)segmentControl {
    if (!_segmentControl) {
        _segmentControl = [[SCSegmentControl alloc] init];
        _segmentControl.dataSource = self;
        _segmentControl.delegate = self;
        [_segmentControl registerClass:[SCTextLineSegmentCell class] forSegmentControlItemWithReuseIdentifier:kSCTextLineSegmentCellKey];
    }
    return _segmentControl;
}

- (UIScrollView *)indicatorScrollView {
    if (!_indicatorScrollView) {
        _indicatorScrollView = [[UIScrollView alloc] init];
        _indicatorScrollView.backgroundColor = [UIColor redColor];
        _indicatorScrollView.showsHorizontalScrollIndicator = NO;
        _indicatorScrollView.bounces = NO;
        _indicatorScrollView.userInteractionEnabled = NO;
    }
    return _indicatorScrollView;
}

- (SCSegmentControlLineIndicator *)indicator {
    if (!_indicator) {
        _indicator = [[SCSegmentControlLineIndicator alloc] init];
    }
    return _indicator;
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.segmentControl removeObserver:self forKeyPath:@"scrollContentSize"];
    [self.segmentControl removeObserver:self forKeyPath:@"scrollContentOffset"];
}

@end
