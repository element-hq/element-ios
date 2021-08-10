//
//  UIImage+ELY_Effect.m
//  TouchTV
//
//  Created by rhc on 16/10/3.
//  Copyright © 2016年 AceWei. All rights reserved.
//

#import "UIImage+ELY_Effect.h"

@implementation UIImage (ELY_Effect)


/**
 *  压缩之后上传图片使用的
 *
 *  @param image 图片
 *
 *  @return 返回压缩之后图片数据
 */
+ (nonnull NSData *)ttv_imageDataCompressForUploadWithImage:(nonnull UIImage *)image {
    NSData *imageData = nil;
    //    压缩图片

    if (image.size.width > 800) {
        CGFloat scale  = 800 / (CGFloat)image.size.width;
        image = [self ttv_resizeWithImage:image resizeToSize:CGSizeMake(image.size.width * scale, image.size.height * scale)];
    
    }
    
    if (UIImagePNGRepresentation(image) == nil) {
        imageData = UIImageJPEGRepresentation(image, 0.8f);
    } else {
        imageData = UIImagePNGRepresentation(image);
    }
    return imageData;
}



/**
 *  调整图片大小
 *
 *  @param image   图片
 *  @param newSize 目标大小
 *
 *  @return 返回调整之后的图片
 */
+ (nonnull instancetype)ttv_resizeWithImage:(nonnull UIImage*)image resizeToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/// 拉伸图片，默认是拉伸中间点
+ (nonnull instancetype)ttv_resizeImage:(nonnull UIImage *)image {
    // 拉伸就是针对中心点进行拉伸
    CGFloat top = image.size.height * 0.5;
    CGFloat left = image.size.width * 0.5;
    CGFloat bottom = top;
    CGFloat right = left;
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, bottom, right) resizingMode:UIImageResizingModeStretch];
}

/// 拉伸图片，默认拉伸中间点
+ (nonnull instancetype)ttv_stretchImage:(nonnull UIImage *)image {
    return [image stretchableImageWithLeftCapWidth:image.size.width * 0.5 topCapHeight:image.size.height * 0.5];
}


+ (nonnull UIImage*)transformWidth:(CGFloat)width
                    height:(CGFloat)height image:( nonnull NSString *)imageName {
    
    CGFloat destW = width;
    CGFloat destH = height;
    CGFloat sourceW = width;
    CGFloat sourceH = height;
    
    UIImage *image = [UIImage imageNamed:imageName];
    CGImageRef imageRef = image.CGImage;
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                destW,
                                                destH,
                                                CGImageGetBitsPerComponent(imageRef),
                                                4*destW,
                                                CGImageGetColorSpace(imageRef),
                                                (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, sourceW, sourceH), imageRef);
    
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage *resultImage = [UIImage imageWithCGImage:ref];
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return resultImage;
}


- (BOOL)hasAlpha {
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(self.CGImage);
    return (alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst || alphaInfo == kCGImageAlphaPremultipliedLast);
}


- (nonnull UIImage *)croppedImageWithFrame:(CGRect)frame {
    UIImage *croppedImage = nil;
    UIGraphicsBeginImageContextWithOptions(frame.size, ![self hasAlpha], self.scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(context, -frame.origin.x, -frame.origin.y);
        [self drawAtPoint:CGPointZero];
        
        croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:croppedImage.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
}


@end
