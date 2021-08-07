//
//  JXAppConfig.h
//  For4
//
//  Created by tang_xy_quiz_4 on 2018/1/3.
//  Copyright © 2018年 tang_xy_quiz_4. All rights reserved.
//

#ifndef JXAppConfig_h
#define JXAppConfig_h


#define NetWorkManager [YXNetWorkManager sharedInstance]

#define ccp(x,y) CGPointMake(x, y)
#define ccsize(x,y) CGSizeMake(x, y)

#define IOS11_OR_LATER_SPACE(par)\
({\
float space = 0.0;\
if (@available(iOS 11.0, *))\
space = par;\
(space);\
})
#define StatusSizeH [[UIApplication sharedApplication] statusBarFrame].size.height
#define JF_KEY_WINDOW [UIApplication sharedApplication].keyWindow
#define JF_TOP_SPACE IOS11_OR_LATER_SPACE(JF_KEY_WINDOW.safeAreaInsets.top)
#define JF_TOP_ACTIVE_SPACE IOS11_OR_LATER_SPACE(MAX(0, JF_KEY_WINDOW.safeAreaInsets.top-20))
#define JF_BOTTOM_SPACE IOS11_OR_LATER_SPACE(JF_KEY_WINDOW.safeAreaInsets.bottom)
#define IMG(name) [UIImage imageNamed:name]
#define URL(name) [NSURL URLWithString:name]
#define SharedAppDelegate ((AppDelegate*)[[UIApplication sharedApplication] delegate])
#define mainSizeW [UIScreen mainScreen].bounds.size.width
#define mainSizeH [UIScreen mainScreen].bounds.size.height
#define UIColorFromRGBA(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]
#define UIColorFromRGB(rgbValue)  UIColorFromRGBA(rgbValue,1.0f)
#define DataDefault [NSUserDefaults standardUserDefaults]
//NavBar高度
#define NAVIGATION_BAR_HEIGHT self.navigationController.navigationBar.frame.size.height
//状态栏 ＋ 导航栏 高度
#define STATUS_AND_NAVIGATION_HEIGHT ((StatusSizeH) + (NAVIGATION_BAR_HEIGHT))

#define mainQueueTask(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_async(dispatch_get_main_queue(), block);\
}

// 全灰
#define FullGray_PLACEDHOLDER_IMG [UIImage imageNamed:@"growPlanBg"]

#define MB (1024ll * 1024ll)

// 弱引用
#define YXWeakSelf __weak typeof(self) weakSelf = self;
#define GET_A_NOT_NIL_STRING(string) (string ? string : @"")
#define SCREEN_HEIGHT       [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH        [[UIScreen mainScreen] bounds].size.width

#define TestLineURL              @"http://139.186.205.178:8080"
#define OnLineURL                @"https://im.server.vpubchain.net/api"
#define ImageOnLineURL           @"https://im.server.vpubchain.net/api/config/download?imageId="

#define kURLTest(...) [TestLineURL stringByAppendingFormat:[__VA_ARGS__ stringByAppendingFormat:@""],nil]

#define kURL(...) [OnLineURL stringByAppendingFormat:[__VA_ARGS__ stringByAppendingFormat:@""],nil]

#define kImageURL(...) [ImageOnLineURL stringByAppendingFormat:[__VA_ARGS__ stringByAppendingFormat:@""],nil]

//判断是否iOS8
#define IS_IOS8 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8)
//判断当前版本
#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

#define IS_IOS11_OR_LATER (IOS_VERSION >= 11)

// 设备类型判断

#define ScreenW    ([[UIScreen mainScreen] bounds].size.width)
#define ScreenH    ([[UIScreen mainScreen] bounds].size.height)
#define ScreenMaxL (MAX(ScreenW, ScreenH))
#define ScreenMinL (MIN(ScreenW, ScreenH))
#define ScreenB    [[UIScreen mainScreen] bounds]
#define ScreenStateH  kStatusBarHeight
#define ScreenNavBarH  kNavBarAndStatusBarHeight//64
#define ScreenTabBarH  (IsiPhoneX ? 83 : 44)
#define kAppWindow [[[UIApplication sharedApplication] delegate] window]

#define TTVScreenStateH CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)
#define TTVHomeIndicatorH  34.0

#define BuoyBtnW  55

#define IsiPhone4   (IsiPhone && ScreenMaxL < 568.0)
#define IsiPhone5   (IsiPhone && ScreenMaxL == 568.0)
#define IsiPhone6   (IsiPhone && ScreenMaxL == 667.0)
#define IsiPhone6P  (IsiPhone && ScreenMaxL == 736.0)
#define IsiPhoneXR     (IsiPhone && ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) : NO))
#define IsiPhoneXS     (IsiPhone && ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO))
#define IsiPhoneXS_Max (IsiPhone && ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO))
#define IsiPhoneX    IsFaceId//([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

//iphoneX/Xs iphoneXS_Max iphoneXR
#define IsFaceId ([UIScreen instancesRespondToSelector:@selector(currentMode)] == NO ? NO : \
                     CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) ||\
                     CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) ||\
                     CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size))

//通用iphoneX判断 faceId通用判断
#define IOS_VERSION_11_OR_LATER (([[[UIDevice currentDevice] systemVersion] floatValue] >=11.0)? (YES):(NO))
#define IsCommonFaceId  (IOS_VERSION_11_OR_LATER ? [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom > 0.0 :NO)

#define IsiPhoneXNav 49
#define IsiPad      (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IsiPhone    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IsRetain    ([[UIScreen mainScreen] scale] >= 2.0)

#define kPtBy1xScale(x) (roundf(ScreenMinL*(x)/750))
#define kPtBy2xScale(x) (roundf(ScreenMinL*(x)/375))
#define kPtBy3xScale(x) (roundf(ScreenMinL*(x)/250))

#define kPtBy1xScaleF(x) (ScreenMinL*(x)/750)
#define kPtBy2xScaleF(x) (ScreenMinL*(x)/375)
#define kPtBy3xScaleF(x) (ScreenMinL*(x)/250)

//-----------------------定位服务-----------------------//
//模拟是都开启
#define SimulationLocationOn  0 //0关系 1开启

//-----------------------GCD_多线程-----------------------//
//后台调用
#define TTVGCDBack                       dispatch_async(dispatch_get_global_queue\
(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^//block)
#define TTVGCDBackAfter(PER_SEC)         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, \
(int64_t)(PER_SEC *NSEC_PER_SEC)), \
dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^//block
#
//主线程调用
#define TTVGCDMain                       dispatch_async(dispatch_get_main_queue(),^//block)
#define TTVGCDMainAfter(PER_SEC)         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)\
(PER_SEC * NSEC_PER_SEC)), dispatch_get_main_queue(), ^//block

//----------------------KeyWindow---------------------------
#define KeyWindow  [UIViewController ttv_keyWindow] //[UIApplication sharedApplication].keyWindow
#define RootTabBarController [KeyWindow.rootViewController isKindOfClass:TabBarController.class] ? KeyWindow.rootViewController : nil
//--------------------------颜色---------------------------
#define TTVTitleColor UIColorFromRGB(0x0)
#define TTVTitleColorAlreadyRead UIColorFromRGB(0x888888)
#define TTVDescribeColor UIColorFromRGB(0x666666)
#define TTVLineColor UIColorFromRGB(0x666666)


//--------------------------专题转唯一sid(本地使用)---------------------------
#define newsTopicSid(a) [NSString stringWithFormat:@"%@-topicId",a]

//--------------------------小于等于 多小不显示阅读数---------------------------
#define limitShowReadCount 0

//--------------------------数据切换------------------------------------------------------
#define kCacheSwitch(a,b) TTVWorkNetWorkEnvironmentOnline?a:b //正式环境:测试环境

//--------------------------常量---------------------------
#define kNavBarHeight                44.f
#define kStatusBarHeight             (IsiPhoneX ? 44 : 20)
#define kNavBarAndStatusBarHeight    (kNavBarHeight+kStatusBarHeight)
#define kFullScreenOryY              (IsiPhoneX ? 0 : 20)

//-----------------------防止多次调用-----------------------/
#define kPreventRepeatClickTime(_seconds_) \
static BOOL shouldPrevent; \
if (shouldPrevent) return; \
shouldPrevent = YES; \
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_seconds_) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ \
shouldPrevent = NO; \
}); \

#define kPreventRepeatClickCheck kPreventRepeatClickTime(0.1)
#define kPreventRepeatClickCheckMid kPreventRepeatClickTime(0.5)
#define kPreventRepeatClickCheckLong kPreventRepeatClickTime(1)

#define kGlobalFolder @"ttv_keep" //需要持久保存文件
#define kGlobalCacheFolder @"ttv_cache" //需要临时文件
#define IsCommonFaceIdSafeBottom  ([UIView commonFaceIdSafeBottom])
//允许编辑时长
#define kEditVideoAllowDuration (24 * 60.0 * 60.0)
//最大导出时长
#define kEditVideoMaxDuration (10 * 60.0 * 60.0)
//每帧代表时长
#define kEditVideoPerFrameDuration (1 * 60.0)
//最短时长
#define kEditVideoMinDuration  (15.0)//(1 * 60.0)
//最大文件长度限制
#define kVideoUploadMaxSize       (1024 * 1024 * 1024) //1g
#endif /* JXAppConfig_h */
