/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import <Photos/Photos.h>

@class MediaAlbumContentViewController;

/**
 `MediaAlbumContentViewController` delegate.
 */
@protocol MediaAlbumContentViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user has selected an asset.
 
 @param mediaAlbumContentViewController the `MediaAlbumContentViewController` instance.
 @param asset the selected asset.
 */
- (void)mediaAlbumContentViewController:(MediaAlbumContentViewController *)mediaAlbumContentViewController didSelectAsset:(PHAsset*)asset;

/**
 Tells the delegate that the user has selected multiple assets.

 @param mediaAlbumContentViewController the `MediaAlbumContentViewController` instance.
 @param assets the selected assets.
 */
- (void)mediaAlbumContentViewController:(MediaAlbumContentViewController *)mediaAlbumContentViewController didSelectAssets:(NSArray<PHAsset*>*)assets;

@end

/**
 */
@interface MediaAlbumContentViewController : MXKViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

/**
 *  Returns the `UINib` object initialized for a `MediaAlbumContentViewController`.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during initialization
 *  or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 *  Creates and returns a new `MediaAlbumContentViewController` object.
 *
 *  @discussion This is the designated initializer for programmatic instantiation.
 *
 *  @return An initialized `MediaAlbumContentViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)mediaAlbumContentViewController;

@property (weak, nonatomic) IBOutlet UICollectionView *assetsCollectionView;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MediaAlbumContentViewControllerDelegate> delegate;

/**
 The array of the media types listed by the view controller (default value is an array containing kUTTypeImage).
 */
@property (nonatomic) NSArray *mediaTypes;

/**
 The collection of photo and video assests.
 */
@property (nonatomic) PHAssetCollection *assetsCollection;

/**
 A Boolean value that determines whether users can select more than one item.
 Default is NO.
 */
@property (nonatomic) BOOL allowsMultipleSelection;

@end

