//
//  ImageViewController.h
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 15/11/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageViewController;

/**
 `ImageViewController` delegate.
 */
@protocol ImageViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user select an image.
 
 @param imageViewController the `ImageViewController` instance.
 @param imageData the full-sized image data of the selected image.
 @param mimetype the image MIME type (nil if unknown).
 @param isPhotoLibraryAsset tell whether the image has been selected from the user's photos library or not.
 */
- (void)imageViewController:(ImageViewController *)imageViewController didSelectImage:(NSData*)imageData withMimeType:(NSString *)mimetype isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;


@end

@interface ImageViewController : UIViewController
- (instancetype)initWithImage:(UIImage *)image;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<ImageViewControllerDelegate> delegate;
@property (nonatomic) NSString *mimetype;
@property (nonatomic) Boolean isPhotoLibraryAsset;

@end
