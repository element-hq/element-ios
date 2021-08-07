//
//  PickerGroupTableViewCell.h
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-13.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZLPhotoPickerGroup;

@interface ZLPhotoPickerGroupTableViewCell : UITableViewCell

/**
 *  赋值xib
 */
@property (nonatomic , strong) ZLPhotoPickerGroup *group;

@end
