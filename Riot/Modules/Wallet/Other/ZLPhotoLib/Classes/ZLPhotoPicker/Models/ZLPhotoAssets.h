//
//  ZLAssets.h
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 15-1-3.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^callBackImage)(UIImage *image);
@interface ZLPhotoAssets : NSObject

+ (instancetype)assetWithImage:(UIImage *)image;
// 获取缩略图
- (void)thumbImageCallBack:(callBackImage)callBack;

@property (strong,nonatomic) ALAsset *asset;
/**
 *  缩略图
 */
@property (nonatomic, strong) UIImage *aspectRatioImage;
/**
 *  缩略图
 */
@property (nonatomic, strong) UIImage *thumbImage;
/**
 *  原图
 */
@property (nonatomic, strong) UIImage *originImage;
/**
 *  获取是否是视频类型, Default = false
 */
@property (assign,nonatomic) BOOL isVideoType;
@property (weak,nonatomic) UIImageView *toView;
/**
 *  获取图片的URL
 */
- (NSURL *)assetURL;

@end
