//
//  UIColor+Hex.h
//  LCCar
//
//  Created by 夏桂峰 on 15/12/22.
//  Copyright (c) 2015年 夏桂峰. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIColor (Hex)

//MARK: - 16进制色值,如：[UIColor colorWithHex:0xd6d6d6];
+ (UIColor *)colorWithHex:(NSUInteger)hex;

+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha;

//MARK: - 16进制色值,如：[UIColor colorWithHex:"0xd6d6d6"];
+ (UIColor *)colorWithHexString:(NSString *)string;

+ (NSString*)colorTo16Hex:(UIColor*)color;

@end



