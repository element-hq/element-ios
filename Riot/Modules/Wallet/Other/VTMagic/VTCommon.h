//
//  VTCommon.h
//  VTMagicView
//
//  Created by tianzhuo on 15/1/6.
//  Copyright (c) 2015年 tianzhuo. All rights reserved.
//

#ifndef VTMagicView_VTCommon_h
#define VTMagicView_VTCommon_h

/** 自定义Log，日志开关 0-关闭 1-开启 */
#define __LOGDEBUG__ (0)

#if defined(__LOGDEBUG__) && __LOGDEBUG__ && DEBUG
#define VTLog(...) NSLog(__VA_ARGS__)
#else
#define VTLog(...)
#endif

// weakSelf
#define __DEFINE_WEAK_SELF__ __weak __typeof(&*self) weakSelf = self;
#define __DEFINE_STRONG_SELF__ __strong __typeof(&*self) strongSelf = self;

// 打印当前方法名
#define VTPRINT_METHOD VTLog(@"==%@:%p running method '%@'==", self.class, self, NSStringFromSelector(_cmd));

// 打印方法运行时间
#define TIME_BEGIN NSDate * startTime = [NSDate date];
#define TIME_END VTLog(@"time interval: %f", -[startTime timeIntervalSinceNow]);

// 设置RGBA颜色值
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(1.f)]
// 十六进制转UIColor
#define kVTColorFromHex(hexValue) [UIColor \
colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0 \
green:((float)((hexValue & 0xFF00) >> 8))/255.0 \
blue:((float)(hexValue & 0xFF))/255.0 alpha:1.0]

// 判断设备是否是iPhone
#define kiPhoneDevice ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)

// 判断系统版本
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define iOS5_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")
#define iOS6_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")
#define iOS7_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")
#define iOS8_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
#define iOS9_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")
#define iOS10_OR_LATER SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")

// tabbar高度
#define VTTABBAR_HEIGHT 49
//// 状态栏高度
//#define VTSTATUSBAR_HEIGHT 20

// 状态栏高度 适配iPhoneX
#define VTSTATUSBAR_HEIGHT StatusSizeH

#endif
