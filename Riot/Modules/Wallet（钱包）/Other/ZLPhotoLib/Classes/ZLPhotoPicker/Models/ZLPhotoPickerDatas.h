//
//  PickerDatas.h
//  相册Demo
//
//  Created by 张磊 on 14-11-11.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZLPhotoPickerGroup;

//typedef NS_ENUM(NSUInteger, ZLPhotoPhotosMode) {
//    ZLPhotoPhotosMode
//};

// 回调
typedef void(^callBackPhotoBlock)(id obj);

@interface ZLPhotoPickerDatas : NSObject

/**
 *  获取所有组
 */
+ (instancetype) defaultPicker;

/**
 * 获取所有组对应的图片与视频
 */
- (void) getAllGroupWithPhotosAndVideos : (callBackPhotoBlock ) callBack;

/**
 * 获取所有组对应的图片
 */
- (void) getAllGroupWithPhotos : (callBackPhotoBlock ) callBack;

/**
 * 获取所有组对应的图片
 */
- (void) getAllGroupWithAllPhotos : (callBackPhotoBlock ) callBack;
/**
 * 获取所有组对应的Videos
 */
- (void) getAllGroupWithVideos : (callBackPhotoBlock ) callBack;

/**
 *  传入一个组获取组里面的Asset
 */
- (void) getGroupPhotosWithGroup : (ZLPhotoPickerGroup *) pickerGroup finished : (callBackPhotoBlock ) callBack;

/**
 *  传入一个AssetsURL来获取UIImage
 */
- (void) getAssetsPhotoWithURLs:(NSURL *) url callBack:(callBackPhotoBlock ) callBack;

@end
