//
//  SCSegmentControl.m
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/18.
//

#import "SCSegmentControl.h"
#import "SCSegmentControlFlowLayout.h"

@interface SCSegmentControl () <
UICollectionViewDelegateFlowLayout,
UICollectionViewDataSource,
UICollisionBehaviorDelegate
>

@property (nonatomic, strong) SCSegmentControlFlowLayout *flowLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger totalItemCount;
@property (nonatomic, assign) BOOL performedProcessDataSource;
@property (nonatomic, assign) NSInteger initialSelectedIndex;
@property (nonatomic, assign) CGSize scrollContentSize;
@property (nonatomic, assign) CGPoint scrollContentOffset;
@property (nonatomic, assign) CGFloat totalWidth;

@end

@implementation SCSegmentControl

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

#pragma mark - Public Functions

- (void)processDataSource {
    if (!self.dataSource) {
        NSAssert(NO, @"SCSegmentControl must confirm SCSegmentControlDataSource and implement required functions!");
        return;
    }
    
    if (![self.dataSource respondsToSelector:@selector(numberOfItemsInSegmentControl:)]) {
        NSAssert(NO, @"SCSegmentControl must confirm SCSegmentControlDataSource and implement required functions!");
        return;
    }
    
    if (![self.dataSource respondsToSelector:@selector(segmentControl:cellForItemAtIndex:)]) {
        NSAssert(NO, @"SCSegmentControl must confirm SCSegmentControlDataSource and implement required functions!");
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(itemSpacingInSegmentControl:)]) {
        self.flowLayout.itemSpacing = [self.dataSource itemSpacingInSegmentControl:self];
    }
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadData];
    } completion:^(BOOL finished) {
        if (!self.performedProcessDataSource && finished) {
            self.performedProcessDataSource = YES;
            [self setupSelectedIndex:self.initialSelectedIndex];
        }
    }];
}

- (void)reloadData {
    [self.collectionView reloadData];
}

- (void)setupSelectedIndex:(NSInteger)selectedIndex {
    if (!self.performedProcessDataSource) {
        self.initialSelectedIndex = selectedIndex;
        return;
    }
    
    if (selectedIndex >= self.totalItemCount || selectedIndex < 0) {
        return;
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectedIndex inSection:0];
    
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)registerNib:(UINib *)nib forSegmentControlItemWithReuseIdentifier:(NSString *)identifier {
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (void)registerClass:(Class)cellClass forSegmentControlItemWithReuseIdentifier:(NSString *)identifier {
    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (UICollectionViewCell *)dequeueReusableSegmentControlItemWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

#pragma mark - Override Functions

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.collectionView.frame = self.bounds;
}

#pragma mark - Private Functions

- (void)commonInit {
    _scrollToCenter = YES;
    
    [self addSubview:self.collectionView];
}

#pragma mark - KVO

- (void)addObserver {
    [self.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.collectionView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isEqual:self.collectionView] && [keyPath isEqualToString:@"contentSize"]) {
        self.scrollContentSize = [change[NSKeyValueChangeNewKey] CGSizeValue];
    } else if ([object isEqual:self.collectionView] && [keyPath isEqualToString:@"contentOffset"]) {
        self.scrollContentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    self.totalItemCount = [self.dataSource numberOfItemsInSegmentControl:self];
    if (self.totalItemCount <= 0) {
        NSAssert(NO, @"Number of items in SegmentControl must be greater than zero!");
        return 0;
    }
    return self.totalItemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self.dataSource segmentControl:self cellForItemAtIndex:indexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.scrollToCenter) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
    
    self->_currentIndex = indexPath.item;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentControl:didSelectItemAtIndex:)]) {
        [self.delegate segmentControl:self didSelectItemAtIndex:self.currentIndex];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = 0;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(segmentControl:widthForItemAtIndex:)]) {
        itemWidth = [self.dataSource segmentControl:self widthForItemAtIndex:indexPath.item];
    }
    
    if (indexPath.item == 0) {
        self.totalWidth = 0;
    }
    
    self.totalWidth += itemWidth;
    return CGSizeMake(itemWidth ?: 50, collectionView.frame.size.height - self.contentInset.top - self.contentInset.bottom);
}

#pragma mark - Setter

- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    self.collectionView.contentInset = contentInset;
}

#pragma mark - Lazy Load

- (SCSegmentControlFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[SCSegmentControlFlowLayout alloc] init];
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.collectionView removeObserver:self forKeyPath:@"contentSize"];
    [self.collectionView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
