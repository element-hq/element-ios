//
//  PSTabMenuViewLabel.m
//  Picasso
//
//  Created by Richard on 2020/5/9.
//  Copyright © 2020 huangkaizhan. All rights reserved.
//

#import "PSTabMenuViewLabel.h"

@interface PSTabMenuViewLabel()

@property (nonatomic, strong) UILabel *label;

@end

@implementation PSTabMenuViewLabel {
    CGFloat _selectedRed, _selectedGreen, _selectedBlue, _selectedAlpha;
    CGFloat _normalRed, _normalGreen, _normalBlue, _normalAlpha;
}

#pragma mark - Public Methods
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.normalColor   = [UIColor blackColor];
        self.selectedColor = [UIColor blackColor];
        self.normalSize    = 15;
        self.selectedSize  = 18;
        self.label.numberOfLines = 0;
        [self addSubview:self.label];
        [self setupGestureRecognizer];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.label.frame = self.bounds;
}

- (void)setupGestureRecognizer {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchUpInside:)];
    [self addGestureRecognizer:tap];
}

- (void)setSelected:(BOOL)selected withAnimation:(BOOL)animation {
    [super setSelected:selected withAnimation:animation];
}

// 设置rate,并刷新标题状态
- (void)setRate:(CGFloat)rate {
    [super setRate:rate];
    if (rate < 0.0 || rate > 1.0) { return; }
    CGFloat r = _normalRed + (_selectedRed - _normalRed) * rate;
    CGFloat g = _normalGreen + (_selectedGreen - _normalGreen) * rate;
    CGFloat b = _normalBlue + (_selectedBlue - _normalBlue) * rate;
    CGFloat a = _normalAlpha + (_selectedAlpha - _normalAlpha) * rate;
    self.label.textColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
    CGFloat minScale = self.normalSize / self.selectedSize;
    CGFloat trueScale = minScale + (1 - minScale)*rate;
    self.transform = CGAffineTransformMakeScale(trueScale, trueScale);
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    _selectedColor = selectedColor;
    [selectedColor getRed:&_selectedRed green:&_selectedGreen blue:&_selectedBlue alpha:&_selectedAlpha];
}

- (void)setNormalColor:(UIColor *)normalColor {
    _normalColor = normalColor;
    [normalColor getRed:&_normalRed green:&_normalGreen blue:&_normalBlue alpha:&_normalAlpha];
}

- (void)touchUpInside:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didPressedMenuItem:)]) {
        [self.delegate didPressedMenuItem:self];
    }
}

- (void)setText:(NSString *)text{
    _text = text;
    self.label.text = text;
}

- (void)setAttributedText:(NSAttributedString *)attributedText{
    _attributedText = attributedText;
    self.label.attributedText = attributedText;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment{
    _textAlignment = textAlignment;
    self.label.textAlignment = textAlignment;
}

- (void)setFont:(UIFont *)font{
    _font = font;
    self.label.font = font;
}

- (UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc]initWithFrame:CGRectZero];
    }
    return _label;
}
@end
