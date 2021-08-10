//
//  UIImage+ELY_Effect.h
//  TouchTV
//
//  Created by rhc on 16/10/3.
//  Copyright © 2016年 AceWei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ELY_Effect)

/**
 *  压缩之后上传图片使用的
 *
 *  @param image 图片
 *
 *  @return 返回压缩之后图片数据
 */
+ (nonnull NSData *)ttv_imageDataCompressForUploadWithImage:(nonnull UIImage *)image;

/**
 *  调整图片大小
 *
 *  @param image   图片
 *  @param newSize 目标大小
 *
 *  @return 返回调整之后的图片
 */
+ (nonnull instancetype)ttv_resizeWithImage:(nonnull UIImage*)image resizeToSize:(CGSize)newSize;


/// 拉伸图片，默认拉伸中间点
+ (nonnull instancetype)ttv_stretchImage:(nonnull UIImage *)image;

/// 拉伸图片，默认是拉伸中间点
+ (nonnull instancetype)ttv_resizeImage:(nonnull UIImage *)image;


+ (nonnull UIImage*)transformWidth:(CGFloat)width
                            height:(CGFloat)height image:(nonnull NSString *)imageName;


- (nonnull UIImage *)croppedImageWithFrame:(CGRect)frame;

@end
