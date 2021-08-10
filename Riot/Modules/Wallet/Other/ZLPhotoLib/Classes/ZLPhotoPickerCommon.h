//
//  ZLPhotoPickerCommon.h
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-19.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#ifndef ZLAssetsPickerDemo_PickerCommon_h
#define ZLAssetsPickerDemo_PickerCommon_h

// 点击销毁的block
typedef void(^ZLPickerBrowserViewControllerTapDisMissBlock)(NSInteger);

// 点击View执行的动画
typedef NS_ENUM(NSUInteger, UIViewAnimationAnimationStatus) {
    UIViewAnimationAnimationStatusZoom = 0, // 放大缩小
    UIViewAnimationAnimationStatusFade , // 淡入淡出
};

// 图片最多显示9张，超过9张取消单击事件
static NSInteger const KPhotoShowMaxCount = 9;

#define iOS7gt ([[UIDevice currentDevice].systemVersion doubleValue] >= 7.0)

// ScrollView 滑动的间距
static CGFloat const ZLPickerColletionViewPadding = 10;

// ScrollView拉伸的比例
static CGFloat const ZLPickerScrollViewMaxZoomScale = 3.0;
static CGFloat const ZLPickerScrollViewMinZoomScale = 1.0;

// 进度条的宽度/高度
static NSInteger const ZLPickerProgressViewW = 50;
static NSInteger const ZLPickerProgressViewH = 50;

// 分页控制器的高度
static NSInteger const ZLPickerPageCtrlH = 25;

// NSNotification
static NSString *PICKER_TAKE_DONE = @"PICKER_TAKE_DONE";
static NSString *PICKER_TAKE_PHOTO = @"PICKER_TAKE_PHOTO";

static NSString *PICKER_PowerBrowserPhotoLibirayText = @"您屏蔽了选择相册的权限，开启请去系统设置->隐私->我的App来打开权限";

static CGFloat const CELL_ROW = 3;
static CGFloat const CELL_MARGIN = 2;
static CGFloat const CELL_LINE_MARGIN = 2;
static CGFloat const TOOLBAR_HEIGHT = 44;

#endif
