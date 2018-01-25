//
//  TestVideoViewController.h
//  Memento
//
//  Created by Ömer Faruk Gül on 22/05/15.
//  Copyright (c) 2015 Ömer Faruk Gül. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoViewController;

/**
 `VideoViewController` delegate.
 */
@protocol VideoViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a video.
 
 @param videoViewController the `VideoViewController` instance.
 @param videoURL the url of the video.
 @param isPhotoLibraryAsset tell whether the video has been selected from the user's photos library or not.
 */
- (void)videoViewController:(VideoViewController *)videoViewController didSelectVideo:(NSURL*)videoURL isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset;


@end


@interface VideoViewController : UIViewController

- (instancetype)initWithVideoUrl:(NSURL *)url;
/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<VideoViewControllerDelegate> delegate;

@property (nonatomic) BOOL isPhotoLibraryAsset;


@end
