//
//  CameraViewController.m
//  Riot
//
//  Created by Ian on 1/12/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import "CameraViewController.h"
#import "CaptureViewController.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AppDelegate.h"
#import "MediaAlbumTableCell.h"

@interface CameraViewController () {

    PHFetchResult *recentCaptures;
    
    BOOL isValidationInProgress;
    
    /**
     User's albums
     */
    dispatch_queue_t userAlbumsQueue;
    NSArray *userAlbums;
    
    /**
     Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
     */
    id UIApplicationWillEnterForegroundNotificationObserver;

}

@end

@implementation CameraViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([CameraViewController class])
                          bundle:[NSBundle bundleForClass:[CameraViewController class]]];
}

+ (instancetype)cameraViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([CameraViewController class])
                                          bundle:[NSBundle bundleForClass:[CameraViewController class]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add Camera - CaptureChildViewController
    [self addCaptureChildViewController];
    
    // Register collection view cell class
    [self.recentCapturesCollectionView registerClass:MXKMediaCollectionViewCell.class forCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier]];
    
    // Register album table view cell class
    [self.userAlbumsTableView registerClass:MediaAlbumTableCell.class forCellReuseIdentifier:[MediaAlbumTableCell defaultReuseIdentifier]];
    
    // Force UI refresh according to selected  media types - Set default media type if none.
    self.mediaTypes = _mediaTypes ? _mediaTypes : @[(NSString *)kUTTypeImage];
    
    [self checkDeviceAuthorizationStatus];
    
    [self reloadRecentCapturesCollection];
    
    // Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
    UIApplicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self reloadRecentCapturesCollection];
        [self reloadUserLibraryAlbums];
        
    }];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Screen tracking (via Google Analytics)
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    if (tracker)
    {
        [tracker set:kGAIScreenName value:@"MediaPicker"];
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    }
    
    if (!userAlbumsQueue)
    {
        userAlbumsQueue = dispatch_queue_create("media.picker.user.albums", DISPATCH_QUEUE_SERIAL);
    }
    
    [self reloadRecentCapturesCollection];
    [self reloadUserLibraryAlbums];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [self handleScreenOrientation];

    });
}

- (void)checkDeviceAuthorizationStatus
{
    NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    [MXKTools checkAccessForMediaType:AVMediaTypeVideo
                  manualChangeMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"camera_access_not_granted", @"Vector", nil), appDisplayName]
            showPopUpInViewController:self
                    completionHandler:^(BOOL granted) {
                        
                        if (granted)
                        {
                            // Load recent captures if this is not already done
                            if (!recentCaptures.count)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    [self reloadRecentCapturesCollection];
                                    [self reloadUserLibraryAlbums];
                                    
                                });
                            }
                        }
                    }];
}


- (void)addCaptureChildViewController
{
    
    CaptureViewController *childCameraVC = [[CaptureViewController alloc] init];
    childCameraVC.mediaTypes = self.mediaTypes;
    [childCameraVC willMoveToParentViewController:self];
    [self addChildViewController:childCameraVC];
    [self.cameraPreviewContainerView addSubview:childCameraVC.view];
    [childCameraVC didMoveToParentViewController:self];
    
    NSArray *horzConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:@{@"childView" : childCameraVC.view}];
    
    NSArray *vertConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:@{@"childView" : childCameraVC.view}];
    
    [self.view addConstraints:horzConstraints];
    [self.view addConstraints:vertConstraints];
    
    childCameraVC.view.translatesAutoresizingMaskIntoConstraints = NO;
}


#pragma mark - Navigation

-(void)backButtonPressed:(UIButton *)button{
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UI Refresh/Update

- (void)handleScreenOrientation
{
    UIInterfaceOrientation screenOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // Check whether the preview ratio must be inverted
    CGFloat ratio = 0.0;
    switch (screenOrientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            if (self.cameraPreviewContainerAspectRatio.multiplier > 1)
            {
                ratio = 15.0 / 22.0;
            }
            break;
        }
        case UIInterfaceOrientationLandscapeRight:
        case UIInterfaceOrientationLandscapeLeft:
        {
            if (self.cameraPreviewContainerAspectRatio.multiplier < 1)
            {
                CGSize screenSize = [[UIScreen mainScreen] bounds].size;
                ratio = screenSize.width / screenSize.height;
            }
            break;
        }
        default:
            break;
    }
    
    if (ratio)
    {
        // Replace the current ratio constraint by a new one
        [NSLayoutConstraint deactivateConstraints:@[self.cameraPreviewContainerAspectRatio]];
        
        self.cameraPreviewContainerAspectRatio = [NSLayoutConstraint constraintWithItem:self.cameraPreviewContainerView
                                                                              attribute:NSLayoutAttributeWidth
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.cameraPreviewContainerView
                                                                              attribute:NSLayoutAttributeHeight
                                                                             multiplier:ratio
                                                                               constant:0.0f];
        self.cameraPreviewContainerAspectRatio.priority = 750;
        
        [NSLayoutConstraint activateConstraints:@[self.cameraPreviewContainerAspectRatio]];
        
        // Force layout refresh
        [self.view layoutIfNeeded];
        
        if (self.navigationController.navigationBarHidden)
        {
            // Force the main scroller at the top
            self.mainScrollView.contentOffset = CGPointMake(0, 0);
        }
    }
    
    // Update Captures collection display
    if (recentCaptures.count)
    {
        // recents Collection is limited to the first 12 assets
        NSInteger recentsCount = ((recentCaptures.count > 12) ? 12 : recentCaptures.count);
        
        self.recentCapturesCollectionContainerViewHeightConstraint.constant = (ceil(recentsCount / 4.0) * ((self.view.frame.size.width - 6) / 4)) + 10;
        [self.recentCapturesCollectionContainerView needsUpdateConstraints];
        
        [self.recentCapturesCollectionView reloadData];
        //ADD this later
    }
}

- (void)reloadRecentCapturesCollection
{
    // Retrieve recents snapshot for the selected media types
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    // Only one album is expected
    if (smartAlbums.count)
    {
        // Set up fetch options.
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        if ([_mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
        {
            if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
            {
                options.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            }
            else
            {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeImage];
            }
        }
        else if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeVideo];
        }
        
        // fetchLimit is available for iOS 9.0 and later
        if ([options respondsToSelector:@selector(fetchLimit)])
        {
            options.fetchLimit = 12;
        }
        
        PHAssetCollection *assetCollection = smartAlbums[0];
        recentCaptures = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
        
        NSLog(@"[MediaPickerVC] lists %tu assets that were recently added to the photo library", recentCaptures.count);
    }
    else
    {
        recentCaptures = nil;
    }
    
    if (recentCaptures.count)
    {
        self.recentCapturesCollectionView.hidden = NO;
        
        // recents Collection is limited to the first 12 assets
        NSInteger recentsCount = ((recentCaptures.count > 12) ? 12 : recentCaptures.count);
        self.recentCapturesCollectionContainerViewHeightConstraint.constant = (ceil(recentsCount / 4.0) * ((self.view.frame.size.width - 6) / 4)) + 10;
        [self.recentCapturesCollectionContainerView needsUpdateConstraints];
        
        [self.recentCapturesCollectionView reloadData];
    }
    else
    {
        self.recentCapturesCollectionView.hidden = YES;
        self.recentCapturesCollectionContainerViewHeightConstraint.constant = 0;
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Collection is limited to the first 12 assets
    return ((recentCaptures.count > 12) ? 12 : recentCaptures.count);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MXKMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier] forIndexPath:indexPath];
    cell.mxkImageView.image = nil;
    
    // Sanity check: cancel pending asynchronous request (if any)
    if (cell.tag)
    {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
        cell.tag = 0;
    }
    
    if (indexPath.item < recentCaptures.count)
    {
        PHAsset *asset = recentCaptures[indexPath.item];
        
        CGFloat collectionViewSquareSize = ((collectionView.frame.size.width - 6) / 4); // Here 6 = 3 * cell margin (= 2).
        CGSize cellSize = CGSizeMake(collectionViewSquareSize, collectionViewSquareSize);
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = NO;
        cell.tag = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:cellSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
            
            cell.mxkImageView.imageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.mxkImageView.image = result;
            cell.tag = 0;
            
        }];
        
        cell.bottomLeftIcon.image = [UIImage imageNamed:@"video_icon"];
        cell.bottomLeftIcon.hidden = (asset.mediaType == PHAssetMediaTypeImage);
        
        // Disable user interaction in mxkImageView, in order to let collection handle user selection
        cell.mxkImageView.userInteractionEnabled = NO;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item < recentCaptures.count)
    {
        [self didSelectAsset: recentCaptures[indexPath.item]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // Check whether a asynchronous request is pending
    if (cell.tag)
    {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
        cell.tag = 0;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item < recentCaptures.count)
    {
        CGFloat collectionViewSquareSize = ((collectionView.frame.size.width - 6) / 4); // Here 6 = 3 * cell margin (= 2).
        CGSize cellSize = CGSizeMake(collectionViewSquareSize, collectionViewSquareSize);
        
        return cellSize;
    }
    return CGSizeZero;
}


#pragma mark - Validation step

- (void)didSelectAsset:(PHAsset *)asset
{
    
    if (asset.mediaType == PHAssetMediaTypeImage)
    {
        isValidationInProgress = YES;
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        id topVC = self.navigationController.topViewController;
        if ([topVC respondsToSelector:@selector(startActivityIndicator)])
        {
            [topVC startActivityIndicator];
        }
        
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:self.view.frame.size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
            
            if ([topVC respondsToSelector:@selector(stopActivityIndicator)])
            {
                [topVC stopActivityIndicator];
            }
                        
            if (result)
            {
                
                if ([topVC respondsToSelector:@selector(startActivityIndicator)])
                {
                    [topVC startActivityIndicator];
                }
                
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    
                    if ([topVC respondsToSelector:@selector(stopActivityIndicator)])
                    {
                        [topVC stopActivityIndicator];
                    }
                    
                    if (imageData)
                    {
                        NSLog(@"[MediaPickerVC] didSelectAsset: Got image data");
                        
                        CFStringRef uti = (__bridge CFStringRef)dataUTI;
                        NSString *mimeType = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
                        
                        __weak typeof(self) weakSelf = self;
                        
                        ImageViewController *imageVC = [[ImageViewController alloc] initWithImage:result];
                        imageVC.mimetype = mimeType;
                        imageVC.isPhotoLibraryAsset = YES;
                        imageVC.delegate = self;
                        [weakSelf presentViewController:imageVC animated:NO completion:nil];
                    }
                    else
                    {
                        NSLog(@"[MediaPickerVC] didSelectAsset: Failed to get image data for asset");
                        
                        //Alert user
                        NSError *error = info[@"PHImageErrorKey"];
                        if (error.userInfo[NSUnderlyingErrorKey])
                        {
                            error = error.userInfo[NSUnderlyingErrorKey];
                        }
                        [[AppDelegate theDelegate] showErrorAsAlert:error];
                    }
                    
                }];
            }
            else
            {
                NSLog(@"[MediaPickerVC] didSelectAsset: Failed to get image for asset");
                isValidationInProgress = NO;
                
                // Alert user
                NSError *error = info[@"PHImageErrorKey"];
                if (error.userInfo[NSUnderlyingErrorKey])
                {
                    error = error.userInfo[NSUnderlyingErrorKey];
                }
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }
            
        }];
    }
    else if (asset.mediaType == PHAssetMediaTypeVideo)
    {
        isValidationInProgress = YES;
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        
        id topVC = self.navigationController.topViewController;
        if ([topVC respondsToSelector:@selector(startActivityIndicator)])
        {
            [topVC startActivityIndicator];
        }
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([topVC respondsToSelector:@selector(stopActivityIndicator)])
                {
                    [topVC stopActivityIndicator];
                }
                
                if (asset)
                {
                    if ([asset isKindOfClass:[AVURLAsset class]])
                    {
                        NSLog(@"[MediaPickerVC] didSelectAsset: Got AVAsset for video");
                        AVURLAsset *avURLAsset = (AVURLAsset*)asset;
                        
                        VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:[avURLAsset URL]];
                        vc.delegate = self;
                        vc.isPhotoLibraryAsset = YES;
                        [self.navigationController presentViewController:vc animated:YES completion:nil];
                        
                    }
                    else
                    {
                        NSLog(@"[MediaPickerVC] Selected video asset is not initialized from an URL!");
                        isValidationInProgress = NO;
                    }
                }
                else
                {
                    NSLog(@"[MediaPickerVC] didSelectAsset: Failed to get image for asset");
                    isValidationInProgress = NO;
                    
                    // Alert user
                    NSError *error = info[@"PHImageErrorKey"];
                    if (error.userInfo[NSUnderlyingErrorKey])
                    {
                        error = error.userInfo[NSUnderlyingErrorKey];
                    }
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                }
                
            });
        }];
    }
    else
    {
        NSLog(@"[MediaPickerVC] didSelectAsset: Unexpected media type");
    }
}


- (void)reloadUserLibraryAlbums
{
    // Sanity check
    if (!userAlbumsQueue)
    {
        return;
    }
    
    dispatch_async(userAlbumsQueue, ^{
        
        // List user albums which are not empty
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        
        NSMutableArray *updatedUserAlbums = [NSMutableArray array];
        __block PHAssetCollection *cameraRollAlbum, *videoAlbum;
        
        // Set up fetch options.
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        if ([_mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
        {
            if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
            {
                options.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            }
            else
            {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeImage];
            }
        }
        else if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeVideo];
        }
        
        [albums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
            
            PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            NSLog(@"album title %@, estimatedAssetCount %tu", collection.localizedTitle, assets.count);
            
            if (assets.count)
            {
                if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary)
                {
                    cameraRollAlbum = collection;
                }
                else if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumVideos)
                {
                    videoAlbum = collection;
                }
                else
                {
                    [updatedUserAlbums addObject:collection];
                }
            }
            
        }];
        
        // Move the camera roll at the top, followed by video and the rest by default
        if (videoAlbum)
        {
            [updatedUserAlbums insertObject:videoAlbum atIndex:0];
        }
        if (cameraRollAlbum)
        {
            [updatedUserAlbums insertObject:cameraRollAlbum atIndex:0];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            userAlbums = updatedUserAlbums;
            if (userAlbums.count)
            {
                self.userAlbumsTableView.hidden = NO;
                self.libraryViewContainerViewHeightConstraint.constant = (userAlbums.count * 74);
                [self.libraryViewContainer needsUpdateConstraints];
                
                [self.userAlbumsTableView reloadData];
            }
            else
            {
                self.userAlbumsTableView.hidden = YES;
                self.libraryViewContainerViewHeightConstraint.constant = 0;
            }
            
        });
        
    });
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return userAlbums.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    MediaAlbumTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[MediaAlbumTableCell defaultReuseIdentifier] forIndexPath:indexPath];
    
    // Sanity check: cancel pending asynchronous request (if any)
    if (cell.tag)
    {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
        cell.tag = 0;
    }
    
    if (indexPath.row < userAlbums.count)
    {
        PHAssetCollection *collection = userAlbums[indexPath.row];
        
        // Report album title
        cell.albumDisplayNameLabel.text = collection.localizedTitle;
        
        // Report album count
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        if ([_mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
        {
            if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
            {
                options.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            }
            else
            {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeImage];
            }
        }
        else if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeVideo];
        }
        
        PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
        cell.albumCountLabel.text = [NSString stringWithFormat:@"%tu", assets.count];
        
        // Report first asset thumbnail (except for 'Recently Deleted' album)
        if (assets.count && collection.assetCollectionSubtype != 1000000201)
        {
            PHAsset *asset = assets[0];
            
            CGSize cellSize = CGSizeMake(73, 73);
            
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.synchronous = NO;
            cell.tag = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:cellSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
                
                cell.albumThumbnail.contentMode = UIViewContentModeScaleAspectFill;
                cell.albumThumbnail.image = result;
                cell.tag = 0;
                
                if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumVideos)
                {
                    cell.bottomLeftIcon.image = [UIImage imageNamed:@"video_icon"];
                    cell.bottomLeftIcon.hidden = NO;
                }
                else
                {
                    cell.bottomLeftIcon.hidden = YES;
                }
            }];
        }
        else
        {
            cell.albumThumbnail.image = nil;
            cell.albumThumbnail.backgroundColor = [UIColor lightGrayColor];
            cell.bottomLeftIcon.hidden = YES;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = kRiotPrimaryBgColor;
    
    // Update the selected background view
    if (kRiotSelectedBgColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = kRiotSelectedBgColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.row < userAlbums.count)
    {
        MediaAlbumContentViewController *albumContentViewController = [MediaAlbumContentViewController mediaAlbumContentViewController];
        albumContentViewController.mediaTypes = self.mediaTypes;
        albumContentViewController.assetsCollection = userAlbums[indexPath.item];
        albumContentViewController.delegate = self;
        albumContentViewController.camVC = self;
        
        // Hide back button title
        self.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        
        [self.navigationController pushViewController:albumContentViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Check whether a asynchronous request is pending
    if (cell.tag)
    {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
        cell.tag = 0;
    }
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)imageViewController:(ImageViewController *)imageViewController didSelectImage:(NSData*)imageData withMimeType:(NSString *)mimetype isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset{
    [self.delegate cameraViewController:self didSelectImage:imageData withMimeType:mimetype isPhotoLibraryAsset:isPhotoLibraryAsset];
}

- (void)videoViewController:(VideoViewController *)videoViewController didSelectVideo:(NSURL*)videoURL isPhotoLibraryAsset:(BOOL)isPhotoLibraryAsset{
    [self.delegate cameraViewController:self didSelectVideo:videoURL isPhotoLibraryAsset:isPhotoLibraryAsset];
}

@end
