//
//  ZLPhotoBrowserViewController+SignlePhotoBrowser.h
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 15/8/21.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "ZLPhotoPickerBrowserViewController.h"

@interface ZLPhotoPickerBrowserViewController (SignlePhotoBrowser)
// Category Functions.
- (UIView *)getParsentView:(UIView *)view;
- (id)getParsentViewController:(UIView *)view;

- (void)showHeadPortrait:(UIImageView *)toImageView;
- (void)showHeadPortrait:(UIImageView *)toImageView originUrl:(NSString *)originUrl;
@end
