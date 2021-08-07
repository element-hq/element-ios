//
//  SCSegmentControlLineIndicator.m
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/18.
//

#import "SCSegmentControlLineIndicator.h"

@interface SCSegmentControlLineIndicator ()

@property (nonatomic, strong) UIImageView *indicatorImageView;

@end

@implementation SCSegmentControlLineIndicator

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Override Functions

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.indicatorImageView.frame = self.bounds;
    self.indicatorView.frame = self.bounds;
}

#pragma mark - Private Functions

- (void)commonInit {
    [self addSubview:self.indicatorImageView];
}

#pragma mark - Setter

- (void)setIndicatorLayer:(CALayer *)indicatorLayer {
    if (!indicatorLayer) {
        [self.indicatorLayer removeFromSuperlayer];
    }
    
    if ([self.layer.sublayers containsObject:indicatorLayer]) {
        return;
    }
    
    [self.layer addSublayer:indicatorLayer];
    if (CGRectEqualToRect(CGRectZero, indicatorLayer.frame)) {
        indicatorLayer.frame = self.bounds;
    }
}

- (void)setIndicatorView:(UIView *)indicatorView {
    _indicatorView = indicatorView;
    if (![self.subviews containsObject:indicatorView]) {
        [self addSubview:indicatorView];
    }
}

- (void)setIndicatorImage:(UIImage *)indicatorImage {
    _indicatorImage = indicatorImage;
    self.indicatorImageView.hidden = !indicatorImage;
    self.indicatorImageView.image = indicatorImage;
}

- (void)setIndicatorImageViewMode:(UIViewContentMode)indicatorImageViewMode {
    _indicatorImageViewMode = indicatorImageViewMode;
    
    self.indicatorImageView.contentMode = indicatorImageViewMode;
}

#pragma mark - Lazy Load

- (UIImageView *)indicatorImageView {
    if (!_indicatorImage) {
        _indicatorImageView = [[UIImageView alloc] init];
        _indicatorImageView.hidden = YES;
    }
    return _indicatorImageView;
}


@end
