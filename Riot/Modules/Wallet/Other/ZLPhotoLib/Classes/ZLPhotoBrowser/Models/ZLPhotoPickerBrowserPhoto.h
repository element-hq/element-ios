//
//  PickerPhoto.h
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-15.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ZLPhotoAssets.h"

@interface ZLPhotoPickerBrowserPhoto : NSObject

@property (assign,nonatomic) BOOL isVideo;
/**
 *  自动适配是不是以下几种数据
 */
@property (nonatomic , strong) id photoObj;
/**
 *  传入对应的UIImageView,记录坐标
 */
@property (strong,nonatomic) UIImageView *toView;
/**
 *  保存相册模型
 */
@property (nonatomic , strong) ZLPhotoAssets *asset;
/**
 *  URL地址
 */
@property (nonatomic , strong) NSURL *photoURL;
/**
 *  原图
 */
@property (nonatomic , strong) UIImage *photoImage;
@property (strong,nonatomic)   UIImage *aspectRatioImage;
/**
 *  缩略图
 */
@property (nonatomic , strong) UIImage *thumbImage;
/**
 *  传入一个图片对象，可以是URL/UIImage/NSString，返回一个实例
 */
+ (instancetype)photoAnyImageObjWith:(id)imageObj;

@end
