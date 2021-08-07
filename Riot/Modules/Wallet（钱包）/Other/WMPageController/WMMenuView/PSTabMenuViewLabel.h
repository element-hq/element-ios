//
//  PSTabMenuViewLabel.h
//  Picasso
//
//  Created by Richard on 2020/5/9.
//  Copyright © 2020 huangkaizhan. All rights reserved.
//

#import "WMMenuItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PSTabMenuViewLabel : WMMenuItem

@property (nonatomic, assign) CGFloat normalSize;     ///> Normal状态的字体大小，默认大小为15
@property (nonatomic, assign) CGFloat selectedSize;   ///> Selected状态的字体大小，默认大小为18
@property (nonatomic, strong) UIColor *normalColor;   ///> Normal状态的字体颜色，默认为黑色 (可动画)
@property (nonatomic, strong) UIColor *selectedColor; ///> Selected状态的字体颜色，默认为红色 (可动画)

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic, assign) NSTextAlignment textAlignment;
@property (nonatomic, strong) UIFont *font;

@end

NS_ASSUME_NONNULL_END
