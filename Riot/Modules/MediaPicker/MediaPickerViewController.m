/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "MediaPickerViewController.h"

#import "GeneratedInterface-Swift.h"

#import <Photos/Photos.h>

#import <AVKit/AVKit.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "MediaAlbumContentViewController.h"

#import "MediaAlbumTableCell.h"

@interface MediaPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MediaAlbumContentViewControllerDelegate>

{
    /**
     Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
     */
    id UIApplicationWillEnterForegroundNotificationObserver;
    
    PHFetchResult *recentCaptures;
    
    /**
     User's albums
     */
    dispatch_queue_t userAlbumsQueue;
    NSArray *userAlbums;
    
    MXKImageView* validationView;
    
    AVPlayerViewController *videoPlayer;
    UIButton *videoPlayerControl;
    
    BOOL isValidationInProgress;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
}

@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;

@property (weak, nonatomic) IBOutlet UIView *recentCapturesCollectionContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *recentCapturesCollectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recentCapturesCollectionContainerViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *libraryViewContainer;
@property (weak, nonatomic) IBOutlet UITableView *userAlbumsTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *libraryViewContainerViewHeightConstraint;

@end

@implementation MediaPickerViewController

#pragma mark - Class methods

+ (instancetype)instantiate
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MediaPickerViewController class])
                                          bundle:[NSBundle bundleForClass:[MediaPickerViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
}

- (void)dealloc
{
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    if (UIApplicationWillEnterForegroundNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillEnterForegroundNotificationObserver];
        UIApplicationWillEnterForegroundNotificationObserver = nil;
    }
    
    [self dismissImageValidationView];
    
    userAlbumsQueue = nil;
    userAlbums = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = [VectorL10n mediaPickerTitle];
    
    MXWeakify(self);
    
    UIBarButtonItem *closeBarButtonItem = [[MXKBarButtonItem alloc] initWithTitle:[VectorL10n cancel] style:UIBarButtonItemStylePlain action:^{
        MXStrongifyAndReturnIfNil(self);
        [self.delegate mediaPickerControllerDidCancel:self];
    }];
    
    self.navigationItem.rightBarButtonItem = closeBarButtonItem;
    // Hide back button title
    [self vc_removeBackTitle];
    
    // Register collection view cell class
    [self.recentCapturesCollectionView registerNib:MXKMediaCollectionViewCell.nib forCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier]];
    
    // Register album table view cell class
    [self.userAlbumsTableView registerNib:MediaAlbumTableCell.nib forCellReuseIdentifier:[MediaAlbumTableCell defaultReuseIdentifier]];
    self.userAlbumsTableView.alwaysBounceVertical = NO;
    
    // Force UI refresh according to selected  media types - Set default media type if none.
    self.mediaTypes = _mediaTypes ? _mediaTypes : @[(NSString *)kUTTypeImage];
    
    
    // Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
    UIApplicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);

        [self checkPhotoLibraryAuthorizationStatusAndReload];

    }];

    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);

        [self userInterfaceThemeDidChange];
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.userAlbumsTableView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.recentCapturesCollectionContainerView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.recentCapturesCollectionView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.userAlbumsTableView.separatorColor = ThemeService.shared.theme.lineBreakColor;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    [self updateRecentCapturesCollectionViewHeightIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self userInterfaceThemeDidChange];
    
    if (!userAlbumsQueue)
    {
        userAlbumsQueue = dispatch_queue_create("media.picker.user.albums", DISPATCH_QUEUE_SERIAL);
    }
    
    [self checkPhotoLibraryAuthorizationStatusAndReload];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        [self updateRecentCapturesCollectionViewHeightIfNeeded];
    });
}
    
- (void)checkPhotoLibraryAuthorizationStatusAndReload
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                // Load recent captures if this is not already done
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self reloadRecentCapturesCollection];
                    [self reloadUserLibraryAlbums];
                    
                });
                break;
            }
            default:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentPermissionDeniedAlert];
                });
                break;
            }
        }
    }];
}

- (void)presentPermissionDeniedAlert
{
    NSString *appDisplayName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    
    NSString *message = [VectorL10n photoLibraryAccessNotGranted:appDisplayName];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n mediaPickerTitle]
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction * action) {
                                                [self.delegate mediaPickerControllerDidCancel:self];
                                            }]];
    
    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n settings]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [UIApplication.sharedApplication openURL:settingsURL options:@{} completionHandler:^(BOOL success) {
                                                    if (success)
                                                    {
                                                        [self.delegate mediaPickerControllerDidCancel:self];
                                                    }
                                                    else
                                                    {
                                                        MXLogDebug(@"[MediaPickerVC] Fails to open settings");
                                                    }
                                                }];
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -

- (void)setMediaTypes:(NSArray *)mediaTypes
{
    if (_mediaTypes != mediaTypes)
    {
        _mediaTypes = mediaTypes;
        
        [self checkPhotoLibraryAuthorizationStatusAndReload];
    }
}

#pragma mark - UI Refresh/Update

- (void)updateRecentCapturesCollectionViewHeightIfNeeded
{
    // Update Captures collection display
    if (recentCaptures.count)
    {
        // recents Collection is limited to the first 12 assets
        NSInteger recentsCount = ((recentCaptures.count > 12) ? 12 : recentCaptures.count);

        CGFloat collectionViewHeight = (ceil(recentsCount / 4.0) * ((self.view.frame.size.width - 6) / 4)) + 10;
        
        if (self.recentCapturesCollectionContainerViewHeightConstraint.constant != collectionViewHeight)
        {
            self.recentCapturesCollectionContainerViewHeightConstraint.constant = collectionViewHeight;
            [self.recentCapturesCollectionView reloadData];
        }
    }
    else
    {
        self.recentCapturesCollectionContainerViewHeightConstraint.constant = 0;
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
        
        MXLogDebug(@"[MediaPickerVC] lists %tu assets that were recently added to the photo library", recentCaptures.count);
    }
    else
    {
        recentCaptures = nil;
    }
    
    if (recentCaptures.count)
    {
        self.recentCapturesCollectionView.hidden = NO;
        [self.recentCapturesCollectionView reloadData];
    }
    else
    {
        self.recentCapturesCollectionView.hidden = YES;
    }

    // Force call updateRecentCapturesCollectionViewHeightIfNeeded
    [self.recentCapturesCollectionContainerView setNeedsLayout];
    [self.recentCapturesCollectionContainerView layoutIfNeeded];
}

- (void)reloadUserLibraryAlbums
{
    // Sanity check
    if (!userAlbumsQueue)
    {
        return;
    }
    
    MXWeakify(self);
        
    dispatch_async(userAlbumsQueue, ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        // List user albums which are not empty
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        
        NSMutableArray *updatedUserAlbums = [NSMutableArray array];
        __block PHAssetCollection *cameraRollAlbum, *videoAlbum;
        
        // Set up fetch options.
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        if ([self->_mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
        {
            if ([self->_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
            {
                options.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            }
            else
            {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeImage];
            }
        }
        else if ([self->_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeVideo];
        }
        
        [albums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
            
            PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            MXLogDebug(@"album title %@, estimatedAssetCount %tu", collection.localizedTitle, assets.count);
            
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
            
            self->userAlbums = updatedUserAlbums;
            if (self->userAlbums.count)
            {
                self.userAlbumsTableView.hidden = NO;
                self.libraryViewContainerViewHeightConstraint.constant = (self->userAlbums.count * 74);
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

#pragma mark - Validation step

- (void)didSelectAsset:(PHAsset *)asset
{
    // Check whether a selection is already in progress
    if (isValidationInProgress)
    {
        return;
    }
    
    if (asset.mediaType == PHAssetMediaTypeImage)
    {
        isValidationInProgress = YES;
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = NO;
        options.networkAccessAllowed = YES;
        
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
                // Validate the selection
                [self validateSelectedImage:result responseHandler:^(BOOL isValidated) {
                    
                    if (isValidated)
                    {
                        // Note we can use `options.progressHandler` to display an animation during the potential download.
                        
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
                                MXLogDebug(@"[MediaPickerVC] didSelectAsset: Got image data");
                                
                                CFStringRef uti = (__bridge CFStringRef)dataUTI;
                                NSString *mimeType = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
                                
                                // Send the original image
                                [self.delegate mediaPickerController:self didSelectImage:imageData withMimeType:mimeType isPhotoLibraryAsset:YES];
                            }
                            else
                            {
                                MXLogDebug(@"[MediaPickerVC] didSelectAsset: Failed to get image data for asset");
                                
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
                    
                    self->isValidationInProgress = NO;
                }];
            }
            else
            {
                MXLogDebug(@"[MediaPickerVC] didSelectAsset: Failed to get image for asset");
                self->isValidationInProgress = NO;
                
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
                    MXLogDebug(@"[MediaPickerVC] didSelectAsset: Got AVAsset for video");
                    
                    // Validate first the selected video
                    [self validateSelectedVideo:asset responseHandler:^(BOOL isValidated) {
                        
                        if (isValidated)
                        {
                            [self.delegate mediaPickerController:self didSelectVideo:asset];
                        }
                        
                        self->isValidationInProgress = NO;
                        
                    }];
                }
                else
                {
                    MXLogDebug(@"[MediaPickerVC] didSelectAsset: Failed to get image for asset");
                    self->isValidationInProgress = NO;
                    
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
        MXLogDebug(@"[MediaPickerVC] didSelectAsset: Unexpected media type");
    }
}

- (void)validateSelectedImage:(UIImage*)selectedImage responseHandler:(void (^)(BOOL isValidated))handler
{
    [self dismissImageValidationView];
    
    // Add a preview to let the user validates his selection
    __weak typeof(self) weakSelf = self;
    
    validationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
    validationView.stretchable = YES;
    
    // the user validates the image
    [validationView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // Dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (YES);
    }];
    
    // the user wants to use an other image
    [validationView setLeftButtonTitle:[VectorL10n cancel] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (NO);
    }];
    
    validationView.image = selectedImage;
    [validationView showFullScreen];
    
    // Hide the status bar
    isStatusBarHidden = YES;
    // Trigger status bar update
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)validateSelectedVideo:(AVAsset*)selectedVideo responseHandler:(void (^)(BOOL isValidated))handler
{
    [self dismissImageValidationView];
    
    // Add a preview to let the user validates his selection
    __weak typeof(self) weakSelf = self;
    
    validationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
    validationView.stretchable = NO;
    
    // the user validates the image
    [validationView setRightButtonTitle:[VectorL10n ok] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // Dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (YES);
    }];
    
    // the user wants to use an other image
    [validationView setLeftButtonTitle:[VectorL10n cancel] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (NO);
    }];
    
    // Display first video frame
    videoPlayer = [[AVPlayerViewController alloc] init];
    if (videoPlayer)
    {
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:selectedVideo];
        videoPlayer.allowsPictureInPicturePlayback = NO;
        videoPlayer.updatesNowPlayingInfoCenter = NO;
        videoPlayer.player = [AVPlayer playerWithPlayerItem:item];
        videoPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
        videoPlayer.showsPlaybackControls = NO;

        //  create a thumbnail for the first frame
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:selectedVideo];
        generator.appliesPreferredTrackTransform = YES;
        CGImageRef thumbnailRef = [generator copyCGImageAtTime:kCMTimeZero actualTime:nil error:nil];

        //  set thumbnail on validationView
        validationView.image = [UIImage imageWithCGImage:thumbnailRef];
    }

    [validationView showFullScreen];

    // Now, there is a thumbnail, show the video control
    videoPlayerControl = [UIButton buttonWithType:UIButtonTypeCustom];
    [videoPlayerControl addTarget:self action:@selector(controlVideoPlayer) forControlEvents:UIControlEventTouchUpInside];
    videoPlayerControl.frame = CGRectMake(0, 0, 44, 44);
    [videoPlayerControl setImage:AssetImages.cameraPlay.image forState:UIControlStateNormal];
    [videoPlayerControl setImage:AssetImages.cameraPlay.image forState:UIControlStateHighlighted];
    [validationView addSubview:videoPlayerControl];
    videoPlayerControl.center = validationView.imageView.center;

    videoPlayerControl.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:videoPlayerControl
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:validationView.imageView
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1
                                                                          constant:0.0f];

    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:videoPlayerControl
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:validationView.imageView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1
                                                                          constant:0.0f];

    [NSLayoutConstraint activateConstraints:@[centerXConstraint, centerYConstraint]];
    
    // Hide the status bar
    isStatusBarHidden = YES;
    // Trigger status bar update
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)dismissImageValidationView
{
    if (validationView)
    {
        if (videoPlayer)
        {
            [videoPlayer.player pause];
            videoPlayer.player = nil;
            
            [videoPlayer.view removeFromSuperview];
            videoPlayer = nil;
            
            [videoPlayerControl removeFromSuperview];
            videoPlayerControl = nil;
        }
        
        [validationView dismissSelection];
        [validationView removeFromSuperview];
        validationView = nil;
        
        // Restore the status bar
        isStatusBarHidden = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)controlVideoPlayer
{
    // Check whether the video player is already playing
    if (videoPlayer.view.superview)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        [videoPlayer.player pause];
        [videoPlayer.player seekToTime:kCMTimeZero];
        [videoPlayer.view removeFromSuperview];
        
        [videoPlayerControl setImage:AssetImages.cameraPlay.image forState:UIControlStateNormal];
        [videoPlayerControl setImage:AssetImages.cameraPlay.image forState:UIControlStateHighlighted];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerPlaybackDidFinishNotification:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        
        CGRect frame = validationView.imageView.frame;
        frame.origin = CGPointZero;
        videoPlayer.view.frame = frame;
        videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [validationView.imageView addSubview:videoPlayer.view];
        
        [videoPlayer.player play];
        
        [videoPlayerControl setImage:AssetImages.cameraStop.image forState:UIControlStateNormal];
        [videoPlayerControl setImage:AssetImages.cameraStop.image forState:UIControlStateHighlighted];
        [validationView bringSubviewToFront:videoPlayerControl];
    }
}

#pragma mark - Action


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Collection is limited to the first 12 assets
    return ((recentCaptures.count > 12) ? 12 : recentCaptures.count);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MXKMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier] forIndexPath:indexPath];
    
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
        
        cell.bottomLeftIcon.image = AssetImages.videoIcon.image;
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
        
        // Report first asset thumbnail (except for 'Recently Deleted' and 'Hidden' albums)
        BOOL isSensitiveCollection = collection.assetCollectionSubtype == 1000000201 || collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden;
        if (assets.count && !isSensitiveCollection)
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
                    cell.bottomLeftIcon.image = AssetImages.videoIcon.image;
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
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    // Update the selected background view
    if (ThemeService.shared.theme.selectedBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
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

        // Enable multiselection only if the delegate is configured to receive them
        if ([_delegate respondsToSelector:@selector(mediaPickerController:didSelectAssets:)])
        {
            albumContentViewController.allowsMultipleSelection = self.allowsMultipleSelection;
        }

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

#pragma mark - MediaAlbumContentViewControllerDelegate

- (void)mediaAlbumContentViewController:(MediaAlbumContentViewController *)mediaAlbumContentViewController didSelectAsset:(PHAsset*)asset
{
    [self didSelectAsset:asset];
}

- (void)mediaAlbumContentViewController:(MediaAlbumContentViewController *)mediaAlbumContentViewController didSelectAssets:(NSArray<PHAsset *> *)assets
{
    if ([self.delegate respondsToSelector:@selector(mediaPickerController:didSelectAssets:)])
    {
        [self.delegate mediaPickerController:self didSelectAssets:assets];
    }
}

#pragma mark - Movie player observer

- (void)moviePlayerPlaybackDidFinishNotification:(NSNotification *)notification
{
    // Remove player view from superview
    [self controlVideoPlayer];
}

@end
