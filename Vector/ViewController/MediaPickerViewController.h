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

@class MediaPickerViewController;

/**
 `MediaPickerViewController` delegate.
 */
@protocol MediaPickerViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user select an image.
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 @param image the UIImage hosting the image data to send.
 @param imageURL the url that references the image in the file system or in the AssetsLibrary framework (nil if the image is not stored in Photos library).
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectImage:(UIImage*)image withURL:(NSURL*)imageURL;

/**
 Tells the delegate that the user select a video.
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 @param videoURL the local url of the video to send.
 @param isCameraRecording tells whether the provided video has just been recorded.
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL isCameraRecording:(BOOL)isCameraRecording;

@optional
/**
 Tells the delegate that the user select a set of assets.
 This callback is used only when multiple selections is allowed (see 'multipleSelections' property)
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 @param assets the array of selected assets (PHAsset instances).
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectAssets:(NSArray*)assets;

@end

/**
 */
@interface MediaPickerViewController : MXKViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AVCaptureFileOutputRecordingDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captureViewContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *captureLabel;
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewContainerView;
@property (weak, nonatomic) IBOutlet UIView *cameraCaptureContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *cameraCaptureImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cameraPreviewContainerAspectRatio;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *cameraActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cameraModeButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraCaptureButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraRetakeButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraChooseButton;

@property (weak, nonatomic) IBOutlet UIView *libraryViewContainer;
@property (weak, nonatomic) IBOutlet UILabel *libraryLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *recentPicturesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentPictureCollectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *libraryOpenButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryChooseButton;

/**
 The delegate for the view controller.
 */
@property (nonatomic) id<MediaPickerViewControllerDelegate> delegate;

/**
 The array of the media types supported by the picker (default value is an array containing kUTTypeImage).
 */
@property (nonatomic) NSArray *mediaTypes;

/**
 Tell whether multiple media can be selected at once in recents collection (default is NO).
 */
@property (nonatomic, getter=isMultipleSelections) BOOL multipleSelections;

/**
 The label of the selection button (default value is "Choose").
 */
@property (nonatomic) NSString *selectionButtonCustomLabel;

@end

