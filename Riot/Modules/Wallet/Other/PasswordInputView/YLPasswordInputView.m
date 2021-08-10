//
//  YLPasswordInputView.m
//  FM
//
//  Created by 苏沫离 on 2020/7/20.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "YLPasswordInputView.h"

@implementation YLPasswordInputViewConfigure

+ (instancetype)defaultConfig {
    YLPasswordInputViewConfigure *configure = [[YLPasswordInputViewConfigure alloc] init];
    configure.isShow = YES;
    configure.squareWidth = 42;
    configure.passwordNum = 6;
    configure.pointRadius = 18 * 0.5;
    configure.spaceMultiple = 5;
    configure.rectColor = [UIColor colorWithRed:221/255.0 green:221/255.0 blue:221/255.0 alpha:1.0];
    configure.pointColor = UIColor.blackColor;
    configure.rectBackgroundColor = UIColor.whiteColor;
    configure.backgroundColor = UIColor.whiteColor;
    configure.textColor = UIColor.blackColor;
    configure.font = [UIFont systemFontOfSize:15];
    configure.threePartyKeyboard = NO;
    return configure;
}

@end

@interface YLPasswordInputView ()
@property (nonatomic, strong) YLPasswordInputViewConfigure *configure;
@property (nonatomic, strong) NSMutableString *text;
@property (nonatomic, assign) BOOL isShow;
@end


@implementation YLPasswordInputView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = self.configure.backgroundColor;
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGFloat height = rect.size.height;
    CGFloat width = rect.size.width;
    CGFloat squareWidth = MIN(MAX(MIN(height, self.configure.squareWidth), (self.configure.pointRadius * 4)), height);
    CGFloat pointRadius = MIN(self.configure.pointRadius, squareWidth * 0.5) * 0.8;
    CGFloat middleSpace = (width - self.configure.passwordNum * squareWidth) / (self.configure.passwordNum - 1 + self.configure.spaceMultiple * 2);
    CGFloat leftSpace = middleSpace * self.configure.spaceMultiple;
    CGFloat y = (height - squareWidth) * 0.5;
    CGContextRef context = UIGraphicsGetCurrentContext();
    //画外框
    for (NSUInteger i = 0; i < self.configure.passwordNum; i++) {
        CGContextAddRect(context, CGRectMake(leftSpace + i * squareWidth + i * middleSpace, y, squareWidth, squareWidth));
        CGContextSetLineWidth(context, 1);
        CGContextSetStrokeColorWithColor(context, self.configure.rectColor.CGColor);
        CGContextSetFillColorWithColor(context, self.configure.rectBackgroundColor.CGColor);
    }
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextSetFillColorWithColor(context, self.configure.pointColor.CGColor);
    
    if (self.configure.isShow) {
        //画数字
        CGFloat textHeight = self.configure.font.lineHeight;
        for (NSUInteger i = 1; i <= self.text.length; i++) {
            NSString *number = [self.text substringWithRange:NSMakeRange(i - 1, 1)];
            [number drawAtPoint:CGPointMake(leftSpace + i * squareWidth + (i - 1) * middleSpace - squareWidth * 0.5 - textHeight / 4.0, y + squareWidth * 0.5 - textHeight / 2.0) withAttributes:@{NSFontAttributeName:self.configure.font,NSForegroundColorAttributeName:self.configure.textColor}];
        }
    }else{
        //画黑点
        for (NSUInteger i = 1; i <= self.text.length; i++) {
            CGContextAddArc(context,  leftSpace + i * squareWidth + (i - 1) * middleSpace - squareWidth * 0.5, y + squareWidth * 0.5, pointRadius, 0, M_PI * 2, YES);
            CGContextDrawPath(context, kCGPathFill);
        }
    }
}

- (UIKeyboardType)keyboardType {
    return UIKeyboardTypeNumberPad;
}

- (BOOL)becomeFirstResponder {
    if (!self.isShow) {
        if ([self.delegate respondsToSelector:@selector(passwordInputViewBeginInput:)]) {
            [self.delegate passwordInputViewBeginInput:self];
        }
    }
    self.isShow = YES;
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    if (self.isShow) {
        if ([self.delegate respondsToSelector:@selector(passwordInputViewEndInput:)]) {
            [self.delegate passwordInputViewEndInput:self];
        }
    }
    self.isShow = NO;
    return [super resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return YES;
}

- (BOOL)isSecureTextEntry {
    return !self.configure.threePartyKeyboard;
}

#pragma mark - response click

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    }
}


#pragma mark - public method

- (void)clearText {
    self.text = [NSMutableString string];
    [self setNeedsLayout];
}

- (void)updateWithConfigure:(void(^)(YLPasswordInputViewConfigure *configure))configBlock {
    if (configBlock) {
        configBlock(self.configure);
    }
    self.backgroundColor = self.configure.backgroundColor;
    [self setNeedsDisplay];
}

#pragma mark - UIKeyInput

- (BOOL)hasText {
    return self.text.length > 0;
}

- (void)insertText:(NSString *)text {
    if (self.text.length < self.configure.passwordNum) {
        //判断是否是数字
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
        NSString*filtered = [[text componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        BOOL basicTest = [text isEqualToString:filtered];
        if(basicTest) {
            [self.text appendString:text];
            if ([self.delegate respondsToSelector:@selector(passwordInputViewDidChange:)]) {
                [self.delegate passwordInputViewDidChange:self];
            }
            if (self.text.length == self.configure.passwordNum) {
                if ([self.delegate respondsToSelector:@selector(passwordInputViewCompleteInput:)]) {
                    [self.delegate passwordInputViewCompleteInput:self];
                }
            }
            [self setNeedsDisplay];
        }
    }
}

- (void)deleteBackward{
    if (self.text.length > 0) {
        [self.text deleteCharactersInRange:NSMakeRange(self.text.length - 1, 1)];
        if ([self.delegate respondsToSelector:@selector(passwordInputViewDidChange:)]) {
            [self.delegate passwordInputViewDidChange:self];
        }
    }
    if ([self.delegate respondsToSelector:@selector(passwordInputViewDidDeleteBackward:)]) {
        [self.delegate passwordInputViewDidDeleteBackward:self];
    }
    [self setNeedsDisplay];
}

#pragma mark - setter and getter

- (YLPasswordInputViewConfigure *)configure{
    if (_configure == nil){
        _configure = [YLPasswordInputViewConfigure defaultConfig];
    }
    return _configure;
}

- (NSMutableString *)text{
    if (_text == nil) {
        _text = [NSMutableString string];
    }
    return _text;
}

@end

