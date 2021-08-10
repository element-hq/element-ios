//
//  YLPasswordInputView.h
//  FM
//
//  Created by 苏沫离 on 2020/7/20.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YLPasswordInputView;

@protocol  YLPasswordInputViewDelegate<NSObject>

@optional

/**输入改变*/
- (void)passwordInputViewDidChange:(YLPasswordInputView *)passwordInputView;

/**点击删除*/
- (void)passwordInputViewDidDeleteBackward:(YLPasswordInputView *)passwordInputView;

/**输入完成*/
- (void)passwordInputViewCompleteInput:(YLPasswordInputView *)passwordInputView;

/**开始输入*/
- (void)passwordInputViewBeginInput:(YLPasswordInputView *)passwordInputView;

/**结束输入*/
- (void)passwordInputViewEndInput:(YLPasswordInputView *)passwordInputView;

@end

@interface YLPasswordInputViewConfigure : NSObject

/**是否显示密码： 默认显示*/
@property (nonatomic, assign) BOOL isShow;
/**密码的位数*/
@property (nonatomic, assign) NSUInteger passwordNum;
/**边框正方形的大小*/
@property (nonatomic, assign) CGFloat squareWidth;
/**黑点的半径*/
@property (nonatomic, assign) CGFloat pointRadius;
/**边距相对中间间隙倍数*/
@property (nonatomic, assign) CGFloat spaceMultiple;
/**黑点颜色*/
@property (nonatomic, strong) UIColor *pointColor;
/**边框颜色*/
@property (nonatomic, strong) UIColor *rectColor;
/**输入框背景颜色*/
@property (nonatomic, strong) UIColor *rectBackgroundColor;
/**控件背景颜色*/
@property (nonatomic, strong) UIColor *backgroundColor;
/**字体颜色*/
@property (nonatomic, strong) UIColor *textColor;
/**字体*/
@property (nonatomic, strong) UIFont *font;
/**是否允许三方键盘，默认NO*/
@property (nonatomic, assign) BOOL threePartyKeyboard;

@end


@interface YLPasswordInputView : UIView
<UIKeyInput>

///代理
@property (nonatomic, weak) id<YLPasswordInputViewDelegate> delegate;

///输入的文本
@property (nonatomic, strong, readonly) NSMutableString *text;

///更新配置
- (void)updateWithConfigure:(void(^)(YLPasswordInputViewConfigure *configure))configBlock;

///清除文字
- (void)clearText;

@end

NS_ASSUME_NONNULL_END
