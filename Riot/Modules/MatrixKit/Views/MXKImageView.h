/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKView.h"

@class MXKAttachment;

/**
 Customize UIView in order to display image defined with remote url. Zooming inside the image (Stretching) is supported.
 */
@interface MXKImageView : MXKView <UIScrollViewDelegate>

typedef void (^blockMXKImageView_onClick)(MXKImageView *imageView, NSString* title);

/**
 Load an image by its Matrix Content URI.
 The image is loaded from the media cache (if any). If the image is not available yet,
 it is downloaded from the Matrix media repository only if a media manager instance is provided.
 
 The image extension is extracted from the provided mime type (if any). By default 'image/jpeg' is considered.
 
 @param mxContentURI the Matrix Content URI
 @param mimeType the media mime type, it is used to define the file extension (may be nil).
 @param orientation the actual orientation of the encoded image (used UIImageOrientationUp by default).
 @param previewImage image displayed until the actual image is available.
 @param mediaManager the media manager instance used to download the image if it is not already in cache.
 */
- (void)setImageURI:(NSString *)mxContentURI
           withType:(NSString *)mimeType
andImageOrientation:(UIImageOrientation)orientation
       previewImage:(UIImage*)previewImage
       mediaManager:(MXMediaManager*)mediaManager;

/**
 Load an image by its Matrix Content URI to fit a specific view size.
 
 CAUTION: this method is available only for the unencrypted content.
 
 The image is loaded from the media cache (if any). If the image is not available yet,
 it is downloaded from the Matrix media repository only if a media manager instance is provided.
 The image extension is extracted from the provided mime type (if any). By default 'image/jpeg' is considered.
 
 @param mxContentURI the Matrix Content URI
 @param mimeType the media mime type, it is used to define the file extension (may be nil).
 @param orientation the actual orientation of the encoded image (used UIImageOrientationUp by default).
 @param previewImage image displayed until the actual image is available.
 @param mediaManager the media manager instance used to download the image if it is not already in cache.
 */
- (void)setImageURI:(NSString *)mxContentURI
           withType:(NSString *)mimeType
andImageOrientation:(UIImageOrientation)orientation
      toFitViewSize:(CGSize)viewSize
         withMethod:(MXThumbnailingMethod)thumbnailingMethod
       previewImage:(UIImage*)previewImage
       mediaManager:(MXMediaManager*)mediaManager;

/**
 * Load an image attachment into the image viewer and display the full res image.
 * This method must be used to display encrypted attachments
 * @param attachment The attachment
 */
- (void)setAttachment:(MXKAttachment *)attachment;

/**
 * Load an attachment into the image viewer and display its thumbnail, if it has one.
 * This method must be used to display encrypted attachments
 * @param attachment The attachment
 */
- (void)setAttachmentThumb:(MXKAttachment *)attachment;

/**
 Toggle display to fullscreen.
 
 No change is applied on the status bar here, the caller has to handle it. 
 */
- (void)showFullScreen;

/**
 The default background color.
 Default is [UIColor blackColor].
 */
@property (nonatomic) UIColor *defaultBackgroundColor;

// Use this boolean to hide activity indicator during image downloading
@property (nonatomic) BOOL hideActivityIndicator;

@property (strong, nonatomic) UIImage *image;
@property (nonatomic, readonly) UIImageView *imageView;

@property (nonatomic) BOOL stretchable;
@property (nonatomic, readonly) BOOL fullScreen;

// the image is cached in memory.
// The medias manager uses a LRU cache.
// to avoid loading from the file system.
@property (nonatomic) BOOL enableInMemoryCache;

// mediaManager folder where the image is stored
@property (nonatomic) NSString* mediaFolder;

// Let the user defines some custom buttons over the tabbar
- (void)setLeftButtonTitle :leftButtonTitle handler:(blockMXKImageView_onClick)handler;
- (void)setRightButtonTitle:rightButtonTitle handler:(blockMXKImageView_onClick)handler;

- (void)dismissSelection;

@end

