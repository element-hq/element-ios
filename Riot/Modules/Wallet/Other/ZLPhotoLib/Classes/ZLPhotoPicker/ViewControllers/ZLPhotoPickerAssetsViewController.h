//
//  ZLPhotoPickerAssetsViewController.h
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-12.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZLPhotoPickerCommon.h"
#import "ZLPhotoPickerGroupViewController.h"

@class ZLPhotoPickerGroup;

@interface ZLPhotoPickerAssetsViewController : UIViewController

@property (weak , nonatomic) ZLPhotoPickerGroupViewController *groupVc;
@property (nonatomic , assign) PickerViewShowStatus status;
@property (nonatomic , strong) ZLPhotoPickerGroup *assetsGroup;
@property (nonatomic , assign) NSInteger maxCount;
// 需要记录选中的值的数据
@property (strong,nonatomic) NSArray *selectPickerAssets;
// 置顶展示图片
@property (assign,nonatomic) BOOL topShowPhotoPicker;
// 是否显示Camera
@property (assign,nonatomic) BOOL isShowCamera;
@end
