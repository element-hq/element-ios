//
//  SCTextLineSegmentCell.m
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/24.
//

#import "SCTextLineSegmentCell.h"

@implementation SCTextLineSegmentCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = self.bounds;
}

#pragma mark - Private Functions

- (void)commonInit {
    self.backgroundColor = UIColor.purpleColor;
    [self.contentView addSubview:self.titleLabel];
}

#pragma mark - Lazy Load

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

@end
