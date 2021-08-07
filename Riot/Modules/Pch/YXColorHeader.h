
//
//  YXColorHeader.h
//  ClouderWork-iOS
//
//  Created by 秋名山滑板少年 on 2019/5/4.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#ifndef YXColorHeader_h
#define YXColorHeader_h

#import "UIColor+Hex.h"

/**
 *  颜色RGB
 */

#define RGB(r,g,b) ([UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1.0f])
/**
 *  颜色RGBA
 */
#define RGBA(r,g,b,a) ([UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)])

/**十六进制色值*/
#define hexColor(hex) [UIColor colorWithHex:hex]
/**
 *  灰色
 */
#define kGrayColor [UIColor grayColor]
/**
 *  浅灰色
 */
#define kLightGrayColor [UIColor lightGrayColor]
/**
 *  深灰色
 */
#define kDarkGrayColor  [UIColor darkGrayColor]
/**
 *  白色
 */
#define kWhiteColor     [UIColor whiteColor]
/**
 *  红色
 */
#define kRedColor       [UIColor redColor]
/**
 *  黑色
 */
#define kBlackColor     [UIColor blackColor]
/**
 *  无色
 */
#define kClearColor     [UIColor clearColor]

/**
 *  底部背景色
 */
#define kBgColor     RGB(246,246,246)
#define WalletColor         RGBA(255,160,0,1)
#define UIColor221  RGBA(221,221,221,1)
#define UIColor102  RGBA(102,102,102,1)
#define UIColor170  RGBA(170,170,170,1)
#define UIColor51   RGBA(51, 51, 51,1)
#define UIColor153  RGBA(153, 153, 153,1)
#endif /* YXColorHeader_h */
