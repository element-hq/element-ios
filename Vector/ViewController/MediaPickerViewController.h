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
 Tells the delegate.
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 @param .
 */
- (void)todo:(MediaPickerViewController *)mediaPickerController;

@end

/**
 */
@interface MediaPickerViewController : MXKViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

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
@property (weak, nonatomic) IBOutlet UILabel *captureLabel;
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewContainerView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *cameraActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *cameraSwitchButton;

@property (weak, nonatomic) IBOutlet UIView *libraryViewContainer;
@property (weak, nonatomic) IBOutlet UILabel *libraryLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *recentPicturesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentPictureCollectionViewHeightConstraint;

/**
 The delegate for the view controller.
 */
@property (nonatomic) id<MediaPickerViewControllerDelegate> delegate;


@end

