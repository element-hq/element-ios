//
//  TTVCameraLogic.m
//  TouchTV
//
//  Created by rhc on 16/10/4.
//  Copyright © 2016年 AceWei. All rights reserved.
//

#import "TTVCameraLogic.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "ZLPhotoPickerViewController.h"
#import "ZLPhotoAssets.h"
#import "TTVAlertView.h"
#import "UIImage+ELY_Effect.h"
@interface TTVCameraLogic ()<ZLPhotoPickerViewControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>
@property (nonatomic,strong,readwrite) NSMutableArray          *imagesArray;
@property (strong, nonatomic) UIActionSheet                    *actionSheet;
@end

@implementation TTVCameraLogic

singleton_implementation(TTVCameraLogic);


- (void)setWithController:(id)withController{
    _withController = withController;
    _imagesArray   = [[NSMutableArray alloc]init];
}

/**
 *  清空数据
 */
- (void)clearMemery{
    
    [_imagesArray removeAllObjects];
}

/**
 *  选择相册
 */
- (void)didSelectPhotos {
    [self clearMemery];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"拍照", @"从相册选择", nil];
        [self.actionSheet showInView:((UIViewController *)_withController).view];
    });
}


#pragma mark -- UIActionSheetDelegate --
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self openCamera];
    }else if (buttonIndex == 1){
        [self openLocalPhoto];
    }
}

// 打开本地相册
- (void)openLocalPhoto {
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusRestricted || author ==ALAuthorizationStatusDenied){
        //无权限
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            
            NSString *alertBody = [NSString stringWithFormat:@"请在设置-隐私-照片中允许“LianChat“访问您的照片开启"];
            [TTVAlertView initWithTitle:nil message:alertBody cancleButtonTitle:nil OtherButtonsArray:@[@"确定",@"去设置"]
                           clickAtIndex:^(NSInteger buttonAtIndex) {
                               if (buttonAtIndex == 1) {
                                   [self setupButtonClick];
                               }
                           }];
            
        } else {
            NSString *alertBody = [NSString stringWithFormat:@"请在设置-隐私-照片中允许“LianChat“访问您的照片开启"];
            [TTVAlertView initWithTitle:nil message:alertBody cancleButtonTitle:nil OtherButtonsArray:@[@"确定"]
                           clickAtIndex:^(NSInteger buttonAtIndex) {}];
        }
        return;
    }
    
    ZLPhotoPickerViewController *pickerVc = [[ZLPhotoPickerViewController alloc] init];
    // 默认显示相册里面的内容SavePhotos
    pickerVc.maxCount   = 1;
    pickerVc.status     = PickerViewShowStatusCameraRoll;
    pickerVc.delegate   = self ;
    [pickerVc showPickerVc:_withController];
}

//打开照相机拍照
- (void)openCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        // 0）实例化控制器
        UIImagePickerController *picker = [[UIImagePickerController alloc]init];
        // 1) 设置允许修改
        // [picker setAllowsEditing:YES];
        // 2) 设置代理
        [picker setDelegate:self];
        // 3) 判断相机是否可用
        if ((authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)) {
            //无权限
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                
                NSString *alertBody = [NSString stringWithFormat:@"请在设置-隐私-照片中允许“LianChat“访问您的照片开启"];
                [TTVAlertView initWithTitle:nil message:alertBody cancleButtonTitle:nil OtherButtonsArray:@[@"确定",@"去设置"]
                               clickAtIndex:^(NSInteger buttonAtIndex) {
                                   if (buttonAtIndex == 1) {
                                       [self setupButtonClick];
                                   }
                               }];
                
            } else {
                NSString *alertBody = [NSString stringWithFormat:@"请在设置-隐私-照片中允许“LianChat“访问您的照片开启"];
                [TTVAlertView initWithTitle:nil message:alertBody cancleButtonTitle:nil OtherButtonsArray:@[@"确定"]
                               clickAtIndex:^(NSInteger buttonAtIndex) {}];
            }
        }else {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            // 4) 显示控制器
            if (self.isVerified) {
                picker.allowsEditing = NO;
            }else{
                picker.allowsEditing = YES;
            }
            
            [_withController presentViewController:picker animated:YES completion:nil];
        }
    }
}

////////////////  选择照片 Begin   ///////////////////////////////////////////////

#pragma mark -- ZLPhotoPickerViewControllerDelegate --返回所有选中的图

- (void)pickerViewControllerDoneAsstes:(NSArray *)assets {

    
    if (!assets || !assets.count) {
        return ;
    }
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self didUploadMultiAsstes:assets];

    // });
}



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // 获取到图片
    UIImage* originImage = nil;
    if (picker.allowsEditing) {
        originImage = info[@"UIImagePickerControllerEditedImage"];
    }else {
       originImage = info[@"UIImagePickerControllerOriginalImage"];
    }
    if(!originImage) return;

    // originImage = [self scaleFromImage:originImage toSize:CGSizeMake(70, 70)];
    NSData *imageData = UIImageJPEGRepresentation(originImage, 1);
    if ((imageData.length/(1024.0*1024.0))>1.99) {
        //  压缩图片
        imageData = [UIImage ttv_imageDataCompressForUploadWithImage:originImage];
    }
    
    [self.imagesArray addObject:imageData];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if ([self.delegate respondsToSelector:@selector(uploadCommunityImages:)]) {
        [self.delegate uploadCommunityImages:self.imagesArray];
    }
    
}



#pragma mark - private methods

- (void)didUploadMultiAsstes:(NSArray *)assets {
    NSInteger idx = 0;
    // 遍历获取到图片
    for (ZLPhotoAssets *photo in assets) {
        if ([photo isKindOfClass:[ZLPhotoAssets class]]) {
            // 获取原图
            UIImage *originImage = [photo aspectRatioImage];
        
        //  originImage = [self scaleFromImage:originImage toSize:CGSizeMake(120, 120)];
            NSData *imageData = UIImageJPEGRepresentation(originImage, 1);
            if ((imageData.length/(1024.0*1024.0))>1.99) {
                //  压缩图片
                imageData = [UIImage ttv_imageDataCompressForUploadWithImage:originImage];
            }
            
            if (imageData != nil) {
                [self.imagesArray addObject:imageData];
       
                idx++;
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(uploadCommunityImages:)]) {
        [self.delegate uploadCommunityImages:self.imagesArray];
    }
}

/**
 *  跳转到设置界面
 *
 *  @param alertView
 *  @param buttonIndex
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self setupButtonClick];
    }
}

- (void)setupButtonClick {
    //   跳转到设置界面
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (UIImage *)thumbnailWithImageWithoutScale:(UIImage *)image size:(CGSize)asize {
    UIImage *newimage;
    if (nil == image) {
        newimage = nil;
    }
    else{
        CGSize oldsize = image.size;
        CGRect rect;
        if (asize.width/asize.height > oldsize.width/oldsize.height) {
            rect.size.width = asize.height*oldsize.width/oldsize.height;
            rect.size.height = asize.height;
            rect.origin.x = (asize.width - rect.size.width)/2;
            rect.origin.y = 0;
        }
        else{
            rect.size.width = asize.width;
            rect.size.height = asize.width*oldsize.height/oldsize.width;
            rect.origin.x = 0;
            rect.origin.y = (asize.height - rect.size.height)/2;
        }
        UIGraphicsBeginImageContext(asize);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        UIRectFill(CGRectMake(0, 0, asize.width, asize.height));//clear background
        [image drawInRect:rect];
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return newimage;
}

- (UIImage *)scaleFromImage: (UIImage *) image toSize: (CGSize) size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}



@end
