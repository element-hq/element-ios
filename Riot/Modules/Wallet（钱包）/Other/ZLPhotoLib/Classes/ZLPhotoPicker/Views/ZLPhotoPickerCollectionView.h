//
//  PickerCollectionView.h
//  相机
//
//  Created by 张磊 on 14-11-11.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZLPhotoAssets.h"

// 展示状态
typedef NS_ENUM(NSUInteger, ZLPickerCollectionViewShowOrderStatus){
    ZLPickerCollectionViewShowOrderStatusTimeDesc = 0, // 升序
    ZLPickerCollectionViewShowOrderStatusTimeAsc // 降序
};

@class ZLPhotoPickerCollectionView;
@protocol ZLPhotoPickerCollectionViewDelegate <NSObject>
// 选择相片就会调用
- (void) pickerCollectionViewDidSelected:(ZLPhotoPickerCollectionView *) pickerCollectionView deleteAsset:(ZLPhotoAssets *)deleteAssets;

// 点击拍照就会调用
- (void)pickerCollectionViewDidCameraSelect:(ZLPhotoPickerCollectionView *) pickerCollectionView;
@end

@interface ZLPhotoPickerCollectionView : UICollectionView<UICollectionViewDelegate>

// scrollView滚动的升序降序
@property (nonatomic , assign) ZLPickerCollectionViewShowOrderStatus status;
// 保存所有的数据
@property (nonatomic , strong) NSArray *dataArray;
// 保存选中的图片
@property (nonatomic , strong) NSMutableArray *selectAssets;
// 最后保存的一次图片
@property (strong,nonatomic) NSMutableArray *lastDataArray;
// delegate
@property (nonatomic , weak) id <ZLPhotoPickerCollectionViewDelegate> collectionViewDelegate;
// 限制最大数
@property (nonatomic , assign) NSInteger maxCount;
// 置顶展示图片
@property (assign,nonatomic) BOOL topShowPhotoPicker;
// 显示拍照
@property (assign,nonatomic) BOOL isShowCamera;
// 选中的索引值，为了防止重用
@property (nonatomic , strong) NSMutableArray *selectsIndexPath;
// 记录选中的值
@property (assign,nonatomic) BOOL isRecoderSelectPicker;

@end
