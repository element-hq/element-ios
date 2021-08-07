//
//  PickerPhoto.m
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-15.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import "ZLPhotoPickerBrowserPhoto.h"

@implementation ZLPhotoPickerBrowserPhoto

- (void)setPhotoObj:(id)photoObj{
    _photoObj = photoObj;
    
    if ([photoObj isKindOfClass:[ZLPhotoAssets class]]) {
        ZLPhotoAssets *asset = (ZLPhotoAssets *)photoObj;
        self.asset = asset;
    }else if ([photoObj isKindOfClass:[NSURL class]]){
        self.photoURL = photoObj;
    }else if ([photoObj isKindOfClass:[UIImage class]]){
        self.photoImage = photoObj;
    }else if ([photoObj isKindOfClass:[NSString class]]){
        self.photoURL = [NSURL URLWithString:photoObj];
    }else{
        NSAssert(true == true, @"您传入的类型有问题");
    }
}

- (UIImage *)photoImage{
    if (!_photoImage && self.asset) {
        if ([self.asset isKindOfClass:[UIImage class]]) {
            _photoImage = (UIImage *)self.asset;
        }else if([self.asset isKindOfClass:[ZLPhotoAssets class]]){
            _photoImage = [self.asset originImage];
        }
    }
    return _photoImage;
}

- (UIImage *)aspectRatioImage{
    if (!_aspectRatioImage) {
        return [self.asset aspectRatioImage];
    }
    return _aspectRatioImage;
}

- (UIImage *)thumbImage{
    if (!_thumbImage) {
        if (self.asset) {
            _thumbImage = [self.asset thumbImage];
        }else if (_photoImage){
            _thumbImage = _photoImage;
        }else if ([_toView isKindOfClass:[UIImageView class]]){
            _thumbImage = ((UIImageView *)_toView).image;
        }
    }
    return _thumbImage;
}

#pragma mark - 传入一个图片对象，可以是URL/UIImage/NSString，返回一个实例
+ (instancetype)photoAnyImageObjWith:(id)imageObj{
    ZLPhotoPickerBrowserPhoto *photo = [[self alloc] init];
    [photo setPhotoObj:imageObj];
    return photo;
}

@end
