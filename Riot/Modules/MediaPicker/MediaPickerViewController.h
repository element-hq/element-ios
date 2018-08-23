/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <MatrixKit/MatrixKit.h>

#import "MediaAlbumContentViewController.h"

@class MediaPickerViewController;

/**
 `MediaPickerViewController` delegate.
 */
@protocol MediaPickerViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user select an image.
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 @param imageData the full-sized image data of the selected image.
 @param mimetype the image MIME type (nil if unknown).
 @param isPhotoLibraryAsset tell whether the image has been selected from the user's photos library or not.
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectImage:(NSData*)imageData withMimeType:(NSString *)mimetype isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;

/**
 Tells the delegate that the user select a video.
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 @param videoURL the local url of the video to send.
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL;

@optional
/**
 Tells the delegate that the user select multiple media.

 @param mediaPickerController the `MediaPickerViewController` instance.
 @param assets the selected media.
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectAssets:(NSArray<PHAsset*>*)assets;

@end

/**
 */
@interface MediaPickerViewController : MXKViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AVCaptureFileOutputRecordingDelegate, MediaAlbumContentViewControllerDelegate>

/**
 *  Returns the `UINib` object initialized for a `MediaPickerViewController`.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during initialization
 *  or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 *  Creates and returns a new `MediaPickerViewController` object.
 *
 *  @discussion This is the designated initializer for programmatic instantiation.
 *
 *  @return An initialized `MediaPickerViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)mediaPickerViewController;

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;

@property (weak, nonatomic) IBOutlet UIView *captureViewContainer;
//@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captureViewContainerHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *cameraPreviewContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cameraPreviewContainerAspectRatio;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *cameraActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraCaptureButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cameraCaptureButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet MXKPieChartView *cameraVideoCaptureProgressView;

@property (weak, nonatomic) IBOutlet UIView *recentCapturesCollectionContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *recentCapturesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentCapturesCollectionContainerViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *libraryViewContainer;
@property (weak, nonatomic) IBOutlet UITableView *userAlbumsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *libraryViewContainerViewHeightConstraint;

/**
 The delegate for the view controller.
 */
@property (nonatomic) id<MediaPickerViewControllerDelegate> delegate;

/**
 The array of the media types supported by the picker (default value is an array containing kUTTypeImage).
 */
@property (nonatomic) NSArray *mediaTypes;

@end

