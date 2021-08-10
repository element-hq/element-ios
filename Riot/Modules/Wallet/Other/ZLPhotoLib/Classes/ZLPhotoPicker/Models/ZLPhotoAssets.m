//
//  ZLAssets.m
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 15-1-3.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "ZLPhotoAssets.h"
#import "ZLPhotoPickerCommon.h"

@interface ZLPhotoAssets ()
@property (nonatomic, assign) BOOL isUIImage;
@end

@implementation ZLPhotoAssets

+ (instancetype)assetWithImage:(UIImage *)image{
    ZLPhotoAssets *asset = [[ZLPhotoAssets alloc] init];
    asset.isUIImage = YES;
    asset.thumbImage = image;
    asset.originImage = image;
    asset.aspectRatioImage = image;
    return asset;
}

- (UIImage *)aspectRatioImage{
    return self.isUIImage ? _aspectRatioImage : [UIImage imageWithCGImage:[self.asset aspectRatioThumbnail]];
}

- (void)thumbImageCallBack:(callBackImage)callBack{
    UIImage *thumbImage = self.isUIImage ? _thumbImage : self.aspectRatioImage;
    if (thumbImage == nil && [[[UIDevice currentDevice] systemVersion] floatValue] >= 9.3) {
        __weak typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            @autoreleasepool {
                UIImage *img = [weakSelf originImage];
                CGFloat WH = [UIScreen mainScreen].bounds.size.width / (CELL_ROW-1);
                img = [self imageCompressForWidth:img targetWidth:WH];
                NSData *data = UIImageJPEGRepresentation(img, 0.5);
                img = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    !callBack ?: callBack(img);
                });
            }
        });
    }else{
        !callBack ?: callBack(thumbImage);
    }
}

//指定宽度按比例缩放
-(UIImage *) imageCompressForWidth:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO){
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor){
            
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            
        }else if(widthFactor < heightFactor){
            
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(size);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil){
        
        NSLog(@"scale image fail");
    }
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)originImage{
    return self.isUIImage ? _originImage : [UIImage imageWithCGImage:[[self.asset defaultRepresentation] fullScreenImage]];
}

- (BOOL)isVideoType{
    NSString *type = [self.asset valueForProperty:ALAssetPropertyType];
    //媒体类型是视频
    return [type isEqualToString:ALAssetTypeVideo];
}

- (NSURL *)assetURL{
    return [[self.asset defaultRepresentation] url];
}

@end
