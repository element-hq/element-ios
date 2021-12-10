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

#import "MatrixKit.h"

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
 @param videoAsset an `AVAsset` that represents the video to send.
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(AVAsset*)videoAsset;

/**
 Tells the delegate that the user wants to cancel media picking.
 
 @param mediaPickerController the `MediaPickerViewController` instance.
 */
- (void)mediaPickerControllerDidCancel:(MediaPickerViewController *)mediaPickerController;

@optional
/**
 Tells the delegate that the user select multiple media.

 @param mediaPickerController the `MediaPickerViewController` instance.
 @param assets the selected media.
 */
- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectAssets:(NSArray<PHAsset*>*)assets;

@end

/**
 * MediaPickerViewController displays recent camera captures and photo/video albums from user library.
 */
@interface MediaPickerViewController : MXKViewController

/**
 *  Creates and returns a new `MediaPickerViewController` object.
 *
 *  @discussion This is the designated initializer for programmatic instantiation.
 *
 *  @return An initialized `MediaPickerViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)instantiate;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MediaPickerViewControllerDelegate> delegate;

/**
 The array of the media types supported by the picker (default value is an array containing kUTTypeImage).
 */
@property (nonatomic) NSArray *mediaTypes;

/**
 A Boolean value that determines whether users can select more than one item.
 Default is NO.
 */
@property (nonatomic) BOOL allowsMultipleSelection;

@end

