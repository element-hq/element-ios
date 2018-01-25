//
//  CameraViewController.h
//  Riot
//
//  Created by Ian on 1/12/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MatrixKit/MatrixKit.h>
#import "MediaAlbumContentViewController.h"
#import "ImageViewController.h"
#import "VideoViewController.h"

@class CameraViewController;

/**
 `CameraViewControllerDelegate` delegate.
 */
@protocol CameraViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user select an image.
 
 @param cameraViewController the `CameraViewController` instance.
 @param imageData the full-sized image data of the selected image.
 @param mimetype the image MIME type (nil if unknown).
 @param isPhotoLibraryAsset tell whether the image has been selected from the user's photos library or not.
 */
- (void)cameraViewController:(CameraViewController *)cameraViewController didSelectImage:(NSData*)imageData withMimeType:(NSString *)mimetype isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;

/**
 Tells the delegate that the user selected a video.
 
 @param cameraViewController the `CameraViewController` instance.
 @param videoURL the url of the video.
 @param isPhotoLibraryAsset tell whether the video has been selected from the user's photos library or not.
 */

- (void)cameraViewController:(CameraViewController *)cameraViewController didSelectVideo:(NSURL*)videoURL isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;

@end


@interface CameraViewController : MXKViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ImageViewControllerDelegate, VideoViewControllerDelegate>

/**
 *  Returns the `UINib` object initialized for a `CameraViewController`.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during initialization
 *  or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 *  Creates and returns a new `CameraViewController` object.
 *
 *  @discussion This is the designated initializer for programmatic instantiation.
 *
 *  @return An initialized `CameraViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)cameraViewController;



@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (weak, nonatomic) IBOutlet UIView *cameraPreviewContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cameraPreviewContainerAspectRatio;

@property (weak, nonatomic) IBOutlet UIView *recentCapturesCollectionContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *recentCapturesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentCapturesCollectionContainerViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UITableView *userAlbumsTableView;

@property (weak, nonatomic) IBOutlet UIView *libraryViewContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *libraryViewContainerViewHeightConstraint;


/**
 The delegate for the view controller.
 */
@property (nonatomic) id<CameraViewControllerDelegate> delegate;


/**
 The array of the media types supported by the camera (default value is an array containing kUTTypeImage).
 */
@property (nonatomic) NSArray *mediaTypes;

- (void)reloadRecentCapturesCollection;

@end
