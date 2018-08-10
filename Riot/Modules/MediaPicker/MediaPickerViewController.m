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

#import "AppDelegate.h"

#import <Photos/Photos.h>

#import <MediaPlayer/MediaPlayer.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "MediaAlbumContentViewController.h"

#import "MediaAlbumTableCell.h"

#import <MatrixKit/MatrixKit.h>

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *RecordingContext = &RecordingContext;

@interface MediaPickerViewController ()
{
    /**
     Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
     */
    id UIApplicationWillEnterForegroundNotificationObserver;
    
    BOOL isPictureCaptureEnabled;
    BOOL isVideoCaptureEnabled;
    
    // Set up only one session at the time.
    BOOL isCaptureSessionSetupInProgress;
    
    AVCaptureSession *captureSession;
    AVCaptureDeviceInput *frontCameraInput;
    AVCaptureDeviceInput *backCameraInput;
    AVCaptureDeviceInput *currentCameraInput;
    
    AVCaptureMovieFileOutput *movieFileOutput;
    AVCaptureStillImageOutput *stillImageOutput;
    
    AVCaptureVideoPreviewLayer *cameraPreviewLayer;
    Boolean canToggleCamera;
    
    dispatch_queue_t cameraQueue;
    
    BOOL lockInterfaceRotation;
    
    UIAlertController *alert;
    
    PHFetchResult *recentCaptures;
    
    /**
     User's albums
     */
    dispatch_queue_t userAlbumsQueue;
    NSArray *userAlbums;
    
    MXKImageView* validationView;
    
    MPMoviePlayerController *videoPlayer;
    UIButton *videoPlayerControl;
    
    BOOL isValidationInProgress;
    
    NSTimer *updateVideoRecordingTimer;
    NSDate *videoRecordStartDate;
    
    /**
     Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
     */
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
    
    /**
     The current visibility of the status bar in this view controller.
     */
    BOOL isStatusBarHidden;
}

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

@implementation MediaPickerViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MediaPickerViewController class])
                          bundle:[NSBundle bundleForClass:[MediaPickerViewController class]]];
}

+ (instancetype)mediaPickerViewController
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
    
    cameraQueue = dispatch_queue_create("media.picker.vc.camera", NULL);
    canToggleCamera = YES;
    
    // Keep visible the status bar by default.
    isStatusBarHidden = NO;
    
    isCaptureSessionSetupInProgress = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Register collection view cell class
    [self.recentCapturesCollectionView registerClass:MXKMediaCollectionViewCell.class forCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier]];
    
    // Register album table view cell class
    [self.userAlbumsTableView registerClass:MediaAlbumTableCell.class forCellReuseIdentifier:[MediaAlbumTableCell defaultReuseIdentifier]];
    
    // Force UI refresh according to selected  media types - Set default media type if none.
    self.mediaTypes = _mediaTypes ? _mediaTypes : @[(NSString *)kUTTypeImage];
    
    // Check camera access before set up AV capture
    [self checkDeviceAuthorizationStatus];
    
    // Set camera preview background
    self.cameraPreviewContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    // The top buttons background is circular
    self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width / 2;
    self.closeButton.clipsToBounds = YES;
    self.cameraSwitchButton.layer.cornerRadius = self.cameraSwitchButton.frame.size.width / 2;
    self.cameraSwitchButton.clipsToBounds = YES;
    
    self.cameraVideoCaptureProgressView.progress = 0;
    
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    
    // Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
    UIApplicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self reloadRecentCapturesCollection];
        [self reloadUserLibraryAlbums];
        
    }];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.cameraVideoCaptureProgressView.progressColor = kRiotPrimaryBgColor;
    self.cameraVideoCaptureProgressView.unprogressColor = [UIColor clearColor];
    
    self.userAlbumsTableView.backgroundColor = kRiotPrimaryBgColor;
    self.view.backgroundColor = kRiotPrimaryBgColor;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return kRiotDesignStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the current status bar visibility.
    return isStatusBarHidden;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Here the views frames are ready, set up the camera preview if it is not already done.
    if (!captureSession)
    {
        // Adjust camera preview ratio
        [self handleScreenOrientation];
        [self setupAVCapture];
    }
}

- (void)dealloc
{
    // Check whether destroy is required
    if (captureSession)
    {
        [self destroy];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"MediaPicker"];
    
    if (!userAlbumsQueue)
    {
        userAlbumsQueue = dispatch_queue_create("media.picker.user.albums", DISPATCH_QUEUE_SERIAL);
    }
    
    [self reloadRecentCapturesCollection];
    [self reloadUserLibraryAlbums];
    
    // Hide the navigation bar, and force the preview camera to be at the top (behing the status bar)
    self.navigationController.navigationBarHidden = YES;
    self.mainScrollView.contentOffset = CGPointMake(0, 0);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotate
{
    // Disable autorotation of the interface when recording is in progress.
    return !lockInterfaceRotation;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Hide camera preview during transition
    cameraPreviewLayer.hidden = YES;
    [self.cameraActivityIndicator startAnimating];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self handleScreenOrientation];
        
        // Show camera preview with delay to hide awful animation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.cameraActivityIndicator stopAnimating];
            cameraPreviewLayer.hidden = NO;
            
        });
    });
}

// The following methods are deprecated since iOS 8
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [[cameraPreviewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
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

- (void)updateVideoRecordingDuration
{
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:videoRecordStartDate];
    
    // The progress animation makes a turn in 30 sec.
    NSUInteger loopNb = (int)(duration/30);
    
    // Switch progress color at each turn
    if (loopNb & 0x01)
    {
        if (self.cameraVideoCaptureProgressView.progressColor != [UIColor lightGrayColor])
        {
            self.cameraVideoCaptureProgressView.progressColor = [UIColor lightGrayColor];
            self.cameraVideoCaptureProgressView.unprogressColor = kRiotPrimaryBgColor;
        }
    }
    else if (self.cameraVideoCaptureProgressView.progressColor != kRiotPrimaryBgColor)
    {
        self.cameraVideoCaptureProgressView.progressColor = kRiotPrimaryBgColor;
        self.cameraVideoCaptureProgressView.unprogressColor = [UIColor lightGrayColor];
    }
    
    duration -= loopNb * 30;
    
    self.cameraVideoCaptureProgressView.progress = duration / 30;
}

#pragma mark -

- (void)setMediaTypes:(NSArray *)mediaTypes
{
    if ([mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
    {
        isPictureCaptureEnabled = YES;
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_capture"] forState:UIControlStateNormal];
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_capture"] forState:UIControlStateHighlighted];
        
        // Check whether video capture should be enabled too
        if ([mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            isVideoCaptureEnabled = YES;
        }
        else
        {
            isVideoCaptureEnabled = NO;
        }
    }
    else if ([mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
    {
        isPictureCaptureEnabled = NO;
        isVideoCaptureEnabled = YES;
        
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_video_capture"] forState:UIControlStateNormal];
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_video_capture"] forState:UIControlStateHighlighted];
    }
    
    if (isVideoCaptureEnabled)
    {
        // Add a long gesture recognizer on cameraCaptureButton (in order to handle video recording)
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGesture:)];
        [self.cameraCaptureButton addGestureRecognizer:longPress];
    }
    
    if (_mediaTypes != mediaTypes)
    {
        _mediaTypes = mediaTypes;
        
        [self reloadRecentCapturesCollection];
        [self reloadUserLibraryAlbums];
    }
}

#pragma mark - Camera preview layout

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == _mainScrollView)
    {
        // Force camera preview at the top (behind the status bar)
        if (scrollView.contentOffset.y < 0)
        {
            scrollView.contentOffset = CGPointMake(0, 0);
        }
    }
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
            _mainScrollView.contentOffset = CGPointMake(0, 0);
        }
    }
    
    // Refresh camera preview layer
    if (cameraPreviewLayer)
    {
        [[cameraPreviewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)screenOrientation];
        cameraPreviewLayer.frame = self.cameraPreviewContainerView.bounds;
    }
    
    // Update Captures collection display
    if (recentCaptures.count)
    {
        // recents Collection is limited to the first 12 assets
        NSInteger recentsCount = ((recentCaptures.count > 12) ? 12 : recentCaptures.count);
        
        self.recentCapturesCollectionContainerViewHeightConstraint.constant = (ceil(recentsCount / 4.0) * ((self.view.frame.size.width - 6) / 4)) + 10;
        [self.recentCapturesCollectionContainerView needsUpdateConstraints];
        
        [self.recentCapturesCollectionView reloadData];
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

- (void)launchPreview
{
    [self.cameraActivityIndicator stopAnimating];
    
    self.cameraSwitchButton.enabled = YES;
    
    if (isPictureCaptureEnabled)
    {
        self.cameraCaptureButtonWidthConstraint.constant = 83;
        
        // Switch back to picture mode by default
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_capture"] forState:UIControlStateNormal];
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_capture"] forState:UIControlStateHighlighted];
        
        if (captureSession)
        {
            [captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
        }
    }
    else
    {
        self.cameraCaptureButtonWidthConstraint.constant = 93;
        
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_video_capture"] forState:UIControlStateNormal];
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_video_capture"] forState:UIControlStateHighlighted];
        
        if (captureSession)
        {
            [captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        }
    }
    
    self.cameraCaptureButton.enabled = YES;
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
                                NSLog(@"[MediaPickerVC] didSelectAsset: Got image data");
                                
                                CFStringRef uti = (__bridge CFStringRef)dataUTI;
                                NSString *mimeType = (__bridge_transfer NSString *) UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
                                
                                // Send the original image
                                [self.delegate mediaPickerController:self didSelectImage:imageData withMimeType:mimeType isPhotoLibraryAsset:YES];
                            }
                            else
                            {
                                NSLog(@"[MediaPickerVC] didSelectAsset: Failed to get image data for asset");
                                
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
                    
                    isValidationInProgress = NO;
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
                        
                        // Validate first the selected video
                        [self validateSelectedVideo:[avURLAsset URL] responseHandler:^(BOOL isValidated) {
                            
                            if (isValidated)
                            {
                                [self.delegate mediaPickerController:self didSelectVideo:[avURLAsset URL]];
                            }
                            
                            isValidationInProgress = NO;
                            
                        }];
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

- (void)validateSelectedImage:(UIImage*)selectedImage responseHandler:(void (^)(BOOL isValidated))handler
{
    [self dismissImageValidationView];
    
    // Add a preview to let the user validates his selection
    __weak typeof(self) weakSelf = self;
    
    validationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
    validationView.stretchable = YES;
    
    // the user validates the image
    [validationView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // Dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (YES);
    }];
    
    // the user wants to use an other image
    [validationView setLeftButtonTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
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

- (void)validateSelectedVideo:(NSURL*)selectedVideoURL responseHandler:(void (^)(BOOL isValidated))handler
{
    [self dismissImageValidationView];
    
    // Add a preview to let the user validates his selection
    __weak typeof(self) weakSelf = self;
    
    validationView = [[MXKImageView alloc] initWithFrame:CGRectZero];
    validationView.stretchable = NO;
    
    // the user validates the image
    [validationView setRightButtonTitle:[NSBundle mxk_localizedStringForKey:@"ok"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // Dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (YES);
    }];
    
    // the user wants to use an other image
    [validationView setLeftButtonTitle:[NSBundle mxk_localizedStringForKey:@"cancel"] handler:^(MXKImageView* imageView, NSString* buttonTitle) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        // dismiss the image view
        [strongSelf dismissImageValidationView];
        
        handler (NO);
    }];
    
    // Display first video frame
    videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:selectedVideoURL];
    if (videoPlayer)
    {
        [videoPlayer setShouldAutoplay:NO];
        videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
        videoPlayer.controlStyle = MPMovieControlStyleNone;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerThumbnailImageRequestDidFinishNotification:)
                                                     name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                                   object:nil];
        [videoPlayer requestThumbnailImagesAtTimes:@[@0.0f] timeOption:MPMovieTimeOptionNearestKeyFrame];
    }

    [validationView showFullScreen];
    
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
            [videoPlayer stop];
            
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
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        
        [videoPlayer stop];
        [videoPlayer.view removeFromSuperview];
        
        [videoPlayerControl setImage:[UIImage imageNamed:@"camera_play"] forState:UIControlStateNormal];
        [videoPlayerControl setImage:[UIImage imageNamed:@"camera_play"] forState:UIControlStateHighlighted];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerPlaybackDidFinishNotification:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];
        
        CGRect frame = validationView.imageView.frame;
        frame.origin = CGPointZero;
        videoPlayer.view.frame = frame;
        videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [validationView.imageView addSubview:videoPlayer.view];
        
        [videoPlayer play];
        
        [videoPlayerControl setImage:[UIImage imageNamed:@"camera_stop"] forState:UIControlStateNormal];
        [videoPlayerControl setImage:[UIImage imageNamed:@"camera_stop"] forState:UIControlStateHighlighted];
        [validationView bringSubviewToFront:videoPlayerControl];
    }
}

#pragma mark - Override MXKViewController

- (void)destroy
{
    [self stopAVCapture];
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    if (UIApplicationWillEnterForegroundNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillEnterForegroundNotificationObserver];
        UIApplicationWillEnterForegroundNotificationObserver = nil;
    }
    
    [self dismissImageValidationView];
    
    if (updateVideoRecordingTimer)
    {
        [updateVideoRecordingTimer invalidate];
        updateVideoRecordingTimer = nil;
    }
    
    cameraQueue = nil;
    userAlbumsQueue = nil;
    userAlbums = nil;
    
    [super destroy];
}

#pragma mark - Action

- (IBAction)onLongPressGesture:(UILongPressGestureRecognizer*)longPressGestureRecognizer
{
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        UIView* view = longPressGestureRecognizer.view;
        
        // Check the view on which long press has been detected
        if (view == self.cameraCaptureButton)
        {
            self.cameraCaptureButtonWidthConstraint.constant = 93;
            
            [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_video_capture"] forState:UIControlStateNormal];
            [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_video_capture"] forState:UIControlStateHighlighted];
            
            if (captureSession)
            {
                [captureSession setSessionPreset:AVCaptureSessionPresetHigh];
            }
            
            // Record a new video
            [self startMovieRecording];
        }
    }
    else if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded || longPressGestureRecognizer.state == UIGestureRecognizerStateCancelled || longPressGestureRecognizer.state == UIGestureRecognizerStateFailed)
    {
        [self stopMovieRecording];
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.closeButton)
    {
        // Close has been pressed
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
    else if (sender == self.cameraSwitchButton)
    {
        [self toggleCamera];
    }
    else if (sender == self.cameraCaptureButton)
    {
        if (isPictureCaptureEnabled)
        {
            [self snapStillImage];
        }
    }
}

#pragma mark - Capture handling methods

- (void)setupAVCapture
{
    if (captureSession || isCaptureSessionSetupInProgress)
    {
        NSLog(@"[MediaPickerVC] Attemping to setup AVCapture when it is already started!");
        return;
    }
    if (!cameraQueue)
    {
        NSLog(@"[MediaPickerVC] Attemping to setup AVCapture when it is being destroyed!");
        return;
    }

    isCaptureSessionSetupInProgress = YES;
    
    [self.cameraActivityIndicator startAnimating];
    
    dispatch_async(cameraQueue, ^{
        
        // Get the Camera Device
        AVCaptureDevice *frontCamera = nil;
        AVCaptureDevice *backCamera = nil;
        NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *thisCamera in cameras)
        {
            if (thisCamera.position == AVCaptureDevicePositionFront)
            {
                frontCamera = thisCamera;
            }
            else if (thisCamera.position == AVCaptureDevicePositionBack)
            {
                backCamera = thisCamera;
            }
            
            NSError *lockError = nil;
            [thisCamera lockForConfiguration:&lockError];
            if (!lockError)
            {
                if ([thisCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
                {
                    [thisCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                }
                else if ([thisCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus])
                {
                    [thisCamera setFocusMode:AVCaptureFocusModeAutoFocus];
                }
                
                if ([thisCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
                {
                    [thisCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
                }
                if ([thisCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
                {
                    [thisCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
                }
                thisCamera.videoZoomFactor = 1.0;
                
                [thisCamera unlockForConfiguration];
            }
            else
            {
                NSLog(@"[MediaPickerVC] Failed to take out lock on camera. Device not setup properly.");
            }
        }
        
        currentCameraInput = nil;
        NSError *error = nil;
        if (frontCamera)
        {
            frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&error];
            if (error)
            {
                NSLog(@"[MediaPickerVC] Error: %@", error);
            }
            
            if (frontCameraInput == nil)
            {
                NSLog(@"[MediaPickerVC] Error creating front camera capture input");
            }
            else
            {
                currentCameraInput = frontCameraInput;
            }
        }
        
        if (backCamera)
        {
            error = nil;
            backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:backCamera error:&error];
            if (error)
            {
                NSLog(@"[MediaPickerVC] Error: %@", error);
            }
            
            if (backCameraInput == nil)
            {
                NSLog(@"[MediaPickerVC] Error creating back camera capture input");
            }
            else
            {
                currentCameraInput = backCameraInput;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cameraSwitchButton.hidden = (!frontCamera || !backCamera);
        });
        
        if (currentCameraInput)
        {
            // Create the AVCapture Session
            captureSession = [[AVCaptureSession alloc] init];
            
            if (isPictureCaptureEnabled)
            {
                [captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
            }
            else if (isVideoCaptureEnabled)
            {
                [captureSession setSessionPreset:AVCaptureSessionPresetHigh];
            }
            
            cameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
            cameraPreviewLayer.masksToBounds = NO;
            cameraPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//AVLayerVideoGravityResizeAspect;
            cameraPreviewLayer.backgroundColor = [[UIColor blackColor] CGColor];
//            cameraPreviewLayer.borderWidth = 2;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[cameraPreviewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
                [cameraPreviewLayer connection].videoScaleAndCropFactor = 1.0;
                cameraPreviewLayer.frame = self.cameraPreviewContainerView.bounds;
                cameraPreviewLayer.hidden = YES;
                
                [self.cameraPreviewContainerView.layer addSublayer:cameraPreviewLayer];
                
            });
            
            [captureSession addInput:currentCameraInput];
            
            AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
            AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            
            if (error)
            {
                NSLog(@"[MediaPickerVC] Error: %@", error);
            }
            
            if ([captureSession canAddInput:audioDeviceInput])
            {
                [captureSession addInput:audioDeviceInput];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(caughtAVRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVCaptureSessionDidStartRunning:) name:AVCaptureSessionDidStartRunningNotification object:nil];
            
            [captureSession startRunning];
            
            movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            if ([captureSession canAddOutput:movieFileOutput])
            {
                [captureSession addOutput:movieFileOutput];
                AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                if ([connection isVideoStabilizationSupported])
                {
                    // Available on iOS 8 and later
                    [connection setPreferredVideoStabilizationMode:YES];
                }
            }
            [movieFileOutput addObserver:self forKeyPath:@"recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
            
            stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ([captureSession canAddOutput:stillImageOutput])
            {
                [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
                [captureSession addOutput:stillImageOutput];
            }
            [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.cameraActivityIndicator stopAnimating];
            });
        }
        
        isCaptureSessionSetupInProgress = NO;
        
    });
}


- (void)stopAVCapture
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (captureSession)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(AVCaptureSessionDidStopRunning:) name:AVCaptureSessionDidStopRunningNotification object:nil];
        
        [captureSession stopRunning];
    }
}

- (void)tearDownAVCapture
{
    if (!cameraQueue)
    {
        NSLog(@"[MediaPickerVC] Attemping to tear down AVCapture when it is being destroyed!");
        return;
    }

    dispatch_sync(cameraQueue, ^{
        frontCameraInput = nil;
        backCameraInput = nil;
        captureSession = nil;

        if (movieFileOutput)
        {
            [movieFileOutput removeObserver:self forKeyPath:@"recording" context:RecordingContext];
            movieFileOutput = nil;
        }

        if (stillImageOutput)
        {
            [stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage" context:CapturingStillImageContext];
            stillImageOutput = nil;
        }

        currentCameraInput = nil;

        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:nil];
    });
}

- (void)caughtAVRuntimeError:(NSNotification*)note
{
    NSError *error = [[note userInfo] objectForKey:AVCaptureSessionErrorKey];
    NSLog(@"[MediaPickerVC] AV Session Error: %@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self tearDownAVCapture];
        // Retry
        [self performSelector:@selector(setupAVCapture) withObject:nil afterDelay:1.0];
    });
}

- (void)AVCaptureSessionDidStartRunning:(NSNotification*)note
{
    // Show camera preview with delay to hide camera settlement
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self.cameraActivityIndicator stopAnimating];
        cameraPreviewLayer.hidden = NO;
        
    });
}

- (void)AVCaptureSessionDidStopRunning:(NSNotification*)note
{
    [self tearDownAVCapture];
}

- (void)toggleCamera
{
    if (frontCameraInput && backCameraInput)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!canToggleCamera)
            {
                return;
            }
            canToggleCamera = NO;
            
            AVCaptureDeviceInput *newInput = nil;
            AVCaptureDeviceInput *oldInput = nil;
            if (currentCameraInput == frontCameraInput)
            {
                newInput = backCameraInput;
                oldInput = frontCameraInput;
            }
            else
            {
                newInput = frontCameraInput;
                oldInput = backCameraInput;
            }
            
            dispatch_async(cameraQueue, ^{
                
                [captureSession beginConfiguration];
                [captureSession removeInput:oldInput];
                if ([captureSession canAddInput:newInput]) {
                    [captureSession addInput:newInput];
                    currentCameraInput = newInput;
                }
                [captureSession commitConfiguration];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.cameraActivityIndicator stopAnimating];
                    cameraPreviewLayer.hidden = NO;
                    canToggleCamera = YES;
                });
            });
            
            [self.cameraActivityIndicator startAnimating];
            cameraPreviewLayer.hidden = YES;
        });
    }
}

- (void)startMovieRecording
{
    self.cameraCaptureButton.enabled = NO;
    
    dispatch_async(cameraQueue, ^{
        if (![movieFileOutput isRecording])
        {
            lockInterfaceRotation = YES;
            
            if ([[UIDevice currentDevice] isMultitaskingSupported])
            {
                // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until the App returns to the foreground unless you request background execution time.
                [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    
                    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundRecordingID];
                    self.backgroundRecordingID = UIBackgroundTaskInvalid;
                    
                    NSLog(@"[MediaPickerVC] pauseInBackgroundTask : %08lX expired", (unsigned long)self.backgroundRecordingID);
                    
                }]];
                
                NSLog(@"[MediaPickerVC] pauseInBackgroundTask : %08lX starts", (unsigned long)self.backgroundRecordingID);
            }
            
            // Update the orientation on the movie file output video connection before starting recording.
            [[movieFileOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[cameraPreviewLayer connection] videoOrientation]];
            
            // Turning OFF flash for video recording
            [MediaPickerViewController setFlashMode:AVCaptureFlashModeOff forDevice:[currentCameraInput device]];
            
            // Start recording to a temporary file.
            NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie" stringByAppendingPathExtension:@"mov"]];
            [movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
        }
    });
}

- (void)stopMovieRecording
{
   dispatch_async(cameraQueue, ^{
        if ([movieFileOutput isRecording])
        {
            [movieFileOutput stopRecording];
        }
    });
}

- (void)snapStillImage
{
    self.cameraCaptureButton.enabled = NO;
    
    dispatch_async(cameraQueue, ^{
        // Update the orientation on the still image output video connection before capturing.
        [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[cameraPreviewLayer connection] videoOrientation]];
        
        // Flash set to Auto for Still Capture
        [MediaPickerViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[currentCameraInput device]];
        
        // Capture a still image.
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            if (imageDataSampleBuffer)
            {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                
                // Open image validation view
                [self validateSelectedImage:image responseHandler:^(BOOL isValidated) {
                    
                    if (isValidated)
                    {
                        // Send the original image
                        [self.delegate mediaPickerController:self didSelectImage:imageData withMimeType:@"image/jpeg" isPhotoLibraryAsset:NO];
                    }
                    
                }];
                
                // Relaunch preview
                [self launchPreview];
            }
        }];
    });
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"[MediaPickerVC] %@", error);
        }
    }
}

- (void)runStillImageCaptureAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [cameraPreviewLayer setOpacity:0.0];
        
        [UIView animateWithDuration:.25 animations:^{
            [cameraPreviewLayer setOpacity:1.0];
        }];
    });
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == CapturingStillImageContext)
    {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if (isCapturingStillImage)
        {
            [self runStillImageCaptureAnimation];
        }
    }
    else if (context == RecordingContext)
    {
        BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (isRecording)
            {
                self.cameraSwitchButton.enabled = NO;
                
                videoRecordStartDate = [NSDate date];
                
                self.cameraVideoCaptureProgressView.hidden = NO;
                updateVideoRecordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateVideoRecordingDuration) userInfo:nil repeats:YES];
                
                self.cameraCaptureButton.enabled = YES;
            }
            else
            {
                self.cameraVideoCaptureProgressView.hidden = YES;
                [updateVideoRecordingTimer invalidate];
                updateVideoRecordingTimer = nil;
                self.cameraVideoCaptureProgressView.progress = 0;
                
                // The preview will be restored during captureOutput:didFinishRecordingToOutputFileAtURL: callback.
            }
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error)
    {
        NSLog(@"[MediaPickerVC] %@", error);
    }
    
    self.cameraCaptureButton.enabled = NO;
    
    lockInterfaceRotation = NO;
    
    // Validate the new captured video
    [self validateSelectedVideo:outputFileURL responseHandler:^(BOOL isValidated) {
        
        if (isValidated)
        {
            // Send the captured video
            [self.delegate mediaPickerController:self didSelectVideo:outputFileURL];
        }
        
        // Remove the temporary file
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        
    }];
    
    // Relaunch preview
    [self launchPreview];
    
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
    if (backgroundRecordingID != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        NSLog(@"[MediaPickerVC] >>>>> background pause task finished");
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

        // Enable multiselection only if the delegate is configured to receive them
        if ([_delegate respondsToSelector:@selector(mediaPickerController:didSelectAssets:)])
        {
            albumContentViewController.allowsMultipleSelection = YES;
        }

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

- (void)moviePlayerThumbnailImageRequestDidFinishNotification:(NSNotification *)notification
{
    if (validationView)
    {
        validationView.image = [[notification userInfo] objectForKey:MPMoviePlayerThumbnailImageKey];
        [validationView bringSubviewToFront:videoPlayerControl];

        // Now, there is a thumbnail, show the video control
        videoPlayerControl = [UIButton buttonWithType:UIButtonTypeCustom];
        [videoPlayerControl addTarget:self action:@selector(controlVideoPlayer) forControlEvents:UIControlEventTouchUpInside];
        videoPlayerControl.frame = CGRectMake(0, 0, 44, 44);
        [videoPlayerControl setImage:[UIImage imageNamed:@"camera_play"] forState:UIControlStateNormal];
        [videoPlayerControl setImage:[UIImage imageNamed:@"camera_play"] forState:UIControlStateHighlighted];
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
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
}

- (void)moviePlayerPlaybackDidFinishNotification:(NSNotification *)notification
{
    // Remove player view from superview
    [self controlVideoPlayer];
}

@end
