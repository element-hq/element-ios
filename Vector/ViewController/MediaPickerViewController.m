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

#import "MediaPickerViewController.h"

#import "MediaAssetCollectionViewCell.h"

#import <Photos/Photos.h>

#import <MediaPlayer/MediaPlayer.h>

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *RecordingContext = &RecordingContext;

NSString* const recentItemCollectionViewCellId = @"recentItemCollectionViewCellId";

@interface MediaPickerViewController ()
{
    BOOL isVideoCaptureMode;
    
    AVCaptureSession *captureSession;
    AVCaptureDeviceInput *frontCameraInput;
    AVCaptureDeviceInput *backCameraInput;
    AVCaptureDeviceInput *currentCameraInput;
    
    AVCaptureMovieFileOutput *movieFileOutput;
    AVCaptureStillImageOutput *stillImageOutput;
    
    AVCaptureVideoPreviewLayer *cameraPreviewLayer;
    Boolean canToggleCamera;
    
    NSURL *outputVideoFileURL;
    MPMoviePlayerController *videoPlayer;
    
    dispatch_queue_t cameraQueue;
    
    BOOL lockInterfaceRotation;
    
    MXKAlert *alert;
    
    PHFetchResult *assetsFetchResult;
    
    NSMutableArray *selectedAssets;
}

@property (nonatomic) AVCaptureVideoOrientation previewOrientation;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onButtonPressed:)];
    
    cameraQueue = dispatch_queue_create("media.picker.vc.camera", NULL);
    canToggleCamera = YES;
    
    // Register collection view cell class
    [self.recentPicturesCollectionView registerClass:MediaAssetCollectionViewCell.class forCellWithReuseIdentifier:recentItemCollectionViewCellId];
    
    // Adjust layout according to screen size
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat maxSize = (screenSize.height > screenSize.width) ? screenSize.height : screenSize.width;
    self.captureViewContainerHeightConstraint.constant = maxSize / 2;
    [self.view layoutIfNeeded];
    
    // Adjust camera preview ratio
    self.previewOrientation = (AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation];
    
    // Set default media type
    self.mediaTypes = _mediaTypes ? _mediaTypes : @[(NSString *)kUTTypeImage];
    
    // Check camera access before set up AV capture
    [self checkDeviceAuthorizationStatus];
    [self setupAVCapture];
    
    // Set button status
    self.cameraRetakeButton.enabled = NO;
    self.cameraChooseButton.enabled = NO;
    self.libraryChooseButton.enabled = NO;
    
    // Set camera preview background
    self.cameraCaptureContainerView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    
    // TODO Localized string
    
}

- (void)dealloc
{
    cameraQueue = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

- (NSUInteger)supportedInterfaceOrientations
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
        
        self.previewOrientation = (AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation];
        
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
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (!granted)
        {
            // Not granted access to mediaType
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                alert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"camera_access_not_granted", @"Vector", nil) style:MXKAlertStyleAlert];
                alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->alert = nil;
                }];
                [alert showInViewController:self];
            });
        }
    }];
}

#pragma mark -

- (void)setMediaTypes:(NSArray *)mediaTypes
{
    _mediaTypes = mediaTypes;
    
    // Retrieve recents snapshot for the selected media types
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded options:nil];
    
    // Set up fetch options.
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    if ([mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
    {
        if ([mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            options.predicate = [NSPredicate predicateWithFormat:@"(mediaType = %d) || (mediaType = %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            self.cameraModeButton.hidden = NO;
            isVideoCaptureMode = NO;
        }
        else
        {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
            self.cameraModeButton.hidden = YES;
            isVideoCaptureMode = NO;
        }
    }
    else if ([mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
    {
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeVideo];
        self.cameraModeButton.hidden = YES;
        isVideoCaptureMode = YES;
    }
    
    // Only one album is expected
    if (smartAlbums.count)
    {
        PHAssetCollection *assetCollection = smartAlbums[0];
        assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
        
        NSLog(@"[MediaPickerVC] lists %tu assets that were recently added to the photo library", assetsFetchResult.count);
    }
    
    if (assetsFetchResult.count)
    {
        self.recentPicturesCollectionView.hidden = NO;
        self.recentPictureCollectionViewHeightConstraint.constant = 130;
        self.libraryChooseButton.hidden = NO;
        
        selectedAssets = [NSMutableArray arrayWithCapacity:assetsFetchResult.count];
        for (NSUInteger index = 0; index < assetsFetchResult.count; index++)
        {
            [selectedAssets addObject:@NO];
        }
        
        [self.recentPicturesCollectionView reloadData];
    }
    else
    {
        self.recentPicturesCollectionView.hidden = YES;
        self.recentPictureCollectionViewHeightConstraint.constant = 0;
        self.libraryChooseButton.hidden = YES;
        selectedAssets = nil;
    }
}

- (void)reset
{
    if (videoPlayer)
    {
        [videoPlayer stop];
        
        [videoPlayer.view removeFromSuperview];
        videoPlayer = nil;
    }

    if (outputVideoFileURL)
    {
        [[NSFileManager defaultManager] removeItemAtURL:outputVideoFileURL error:nil];
        outputVideoFileURL = nil;
    }
    
    self.cameraCaptureContainerView.hidden = YES;
    
    self.cameraModeButton.enabled = YES;
    self.cameraSwitchButton.enabled = YES;
    
    self.cameraChooseButton.enabled = NO;
    self.cameraRetakeButton.enabled = NO;
    
    if (isVideoCaptureMode)
    {
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_record"] forState:UIControlStateNormal];
    }
    self.cameraCaptureButton.enabled = YES;
}

#pragma mark - Override MXKViewController

- (void)destroy
{
    [self stopAVCapture];
    
    cameraQueue = nil;
    
    [super destroy];
}

#pragma mark - Action

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.navigationItem.leftBarButtonItem)
    {
        [self stopAVCapture];
        [self reset];
         
        // Cancel has been pressed
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else if (sender == self.cameraModeButton)
    {
        [self toggleCaptureMode];
    }
    else if (sender == self.cameraSwitchButton)
    {
        [self toggleCamera];
    }
    else if (sender == self.cameraCaptureButton)
    {
        if (isVideoCaptureMode)
        {
            if (outputVideoFileURL)
            {
                // Play/Stop captured video
                [self controlVideoPlayer];
            }
            else
            {
                // Record a new video
                [self toggleMovieRecording];
            }
        }
        else
        {
            [self snapStillImage];
        }
    }
    else if (sender == self.cameraRetakeButton)
    {
        [self reset];
    }
    else if (sender == self.cameraChooseButton)
    {
        self.cameraChooseButton.enabled = NO;
        [self.cameraActivityIndicator startAnimating];
        
        if (outputVideoFileURL)
        {
            [MXKMediaManager saveMediaToPhotosLibrary:outputVideoFileURL isImage:NO success:^{
                
                if (self.delegate)
                {
                    [self.delegate mediaPickerController:self didSelectVideo:outputVideoFileURL];
                }
                
                [self.cameraActivityIndicator stopAnimating];
                outputVideoFileURL = nil;
                
                [self reset];
                
            } failure:^(NSError *error) {
                
                self.cameraChooseButton.enabled = YES;
                [self.cameraActivityIndicator stopAnimating];
                
                __weak typeof(self) weakSelf = self;
                alert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"save_media_failed", @"Vector", nil) style:MXKAlertStyleAlert];
                alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->alert = nil;
                }];
                [alert showInViewController:self];
                
            }];
        }
        else if (!self.cameraCaptureContainerView.isHidden && self.cameraCaptureImageView.image)
        {
            [MXKMediaManager saveImageToPhotosLibrary:self.cameraCaptureImageView.image success:^{
                
                if (self.delegate)
                {
                    [self.delegate mediaPickerController:self didSelectImage:self.cameraCaptureImageView.image];
                }
                
                [self.cameraActivityIndicator stopAnimating];
                                
                [self reset];
                
            } failure:^(NSError *error) {
                
                self.cameraChooseButton.enabled = YES;
                [self.cameraActivityIndicator stopAnimating];
                
                __weak typeof(self) weakSelf = self;
                alert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"save_media_failed", @"Vector", nil) style:MXKAlertStyleAlert];
                alert.cancelButtonIndex = [alert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"] style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf->alert = nil;
                }];
                [alert showInViewController:self];
                
            }];
        }
        else
        {
            NSLog(@"[MediaPickerVC] Selection is empty");
            self.cameraChooseButton.enabled = YES;
            [self.cameraActivityIndicator stopAnimating];
        }
    }
    else if (sender == self.libraryChooseButton && selectedAssets && self.delegate)
    {
        self.libraryChooseButton.enabled = NO;
        [self.activityIndicator startAnimating];
        
        PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];
        for (NSUInteger index = 0; index < selectedAssets.count; index++)
        {
            if ([selectedAssets[index] boolValue])
            {
                PHAsset *asset = assetsFetchResult[index];
                [asset requestContentEditingInputWithOptions:editOptions
                                           completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                               
                                               if (contentEditingInput.mediaType == PHAssetMediaTypeImage)
                                               {
                                                   // Here the fullSizeImageURL is related to a local file path
                                                   UIImage *image = [UIImage imageWithContentsOfFile:contentEditingInput.fullSizeImageURL.path];
                                                   [self.delegate mediaPickerController:self didSelectImage:image];
                                               }
                                               else if (contentEditingInput.mediaType == PHAssetMediaTypeVideo)
                                               {
                                                   if ([contentEditingInput.avAsset isKindOfClass:[AVURLAsset class]])
                                                   {
                                                       AVURLAsset *avURLAsset = (AVURLAsset*)contentEditingInput.avAsset;
                                                       [self.delegate mediaPickerController:self didSelectVideo:[avURLAsset URL]];
                                                   }
                                                   else
                                                   {
                                                       NSLog(@"[MediaPickerVC] Selected video asset is not initialized from an URL!");
                                                   }
                                               }
                                           }];
                
                // Reset selection
                selectedAssets[index] = @NO;
            }
        }
        
        [self.activityIndicator stopAnimating];
        [self.recentPicturesCollectionView reloadData];
    }
}

#pragma mark - Capture handling methods

- (void)setPreviewOrientation:(AVCaptureVideoOrientation)previewOrientation
{
    // Check whether the preview ratio must be inverted
    CGFloat ratio = 0.0;
    switch (previewOrientation)
    {
        case AVCaptureVideoOrientationPortrait:
        case AVCaptureVideoOrientationPortraitUpsideDown:
        {
            if (self.cameraPreviewContainerAspectRatio.multiplier > 1)
            {
                ratio = (1 / self.cameraPreviewContainerAspectRatio.multiplier);
            }
            break;
        }
        case AVCaptureVideoOrientationLandscapeRight:
        case AVCaptureVideoOrientationLandscapeLeft:
        {
            if (self.cameraPreviewContainerAspectRatio.multiplier < 1)
            {
                ratio = (1 / self.cameraPreviewContainerAspectRatio.multiplier);
            }
            break;
        }
        default:
            break;
    }
    
    if (ratio)
    {
        // Replace the current ratio constraint by a new one
        if ([NSLayoutConstraint respondsToSelector:@selector(deactivateConstraints:)])
        {
            [NSLayoutConstraint deactivateConstraints:@[self.cameraPreviewContainerAspectRatio]];
        }
        else
        {
            [self.view removeConstraint:self.cameraPreviewContainerAspectRatio];
        }
        
        self.cameraPreviewContainerAspectRatio = [NSLayoutConstraint constraintWithItem:self.cameraPreviewContainerView
                                                                              attribute:NSLayoutAttributeWidth
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self.cameraPreviewContainerView
                                                                              attribute:NSLayoutAttributeHeight
                                                                             multiplier:ratio
                                                                               constant:0.0f];
        
        if ([NSLayoutConstraint respondsToSelector:@selector(activateConstraints:)])
        {
            [NSLayoutConstraint activateConstraints:@[self.cameraPreviewContainerAspectRatio]];
        }
        else
        {
            [self.view addConstraint:self.cameraPreviewContainerAspectRatio];
        }
        
        // Force layout refresh
        [self.view layoutIfNeeded];
    }
    
    // Refresh camera preview layer
    if (cameraPreviewLayer)
    {
        [[cameraPreviewLayer connection] setVideoOrientation:previewOrientation];
        cameraPreviewLayer.frame = self.cameraPreviewContainerView.bounds;
    }
    
    _previewOrientation = previewOrientation;
}

- (void)setupAVCapture
{
    if (captureSession)
    {
        NSLog(@"[MediaPickerVC] Attemping to setup AVCapture when it is already started!");
        return;
    }
    
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
        
        self.cameraSwitchButton.hidden = (!frontCamera || !backCamera);
        
        if (currentCameraInput)
        {
            // Create the AVCapture Session
            captureSession = [[AVCaptureSession alloc] init];
            
            [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
            
            cameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
            cameraPreviewLayer.masksToBounds = NO;
            cameraPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            cameraPreviewLayer.backgroundColor = [[UIColor blackColor] CGColor];
            cameraPreviewLayer.borderWidth = 2;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[cameraPreviewLayer connection] setVideoOrientation:self.previewOrientation];
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
                    if ([connection respondsToSelector:@selector(setPreferredVideoStabilizationMode:)])
                    {
                        [connection setPreferredVideoStabilizationMode:YES];
                    }
                    else
                    {
                        [connection setEnablesVideoStabilizationWhenAvailable:YES];
                    }
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

- (void)toggleCaptureMode
{
    if (isVideoCaptureMode)
    {
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_capture"] forState:UIControlStateNormal];
        [self.cameraModeButton setImage:[UIImage imageNamed:@"camera_video"] forState:UIControlStateNormal];
        isVideoCaptureMode = NO;
    }
    else
    {
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_record"] forState:UIControlStateNormal];
        [self.cameraModeButton setImage:[UIImage imageNamed:@"camera_picture"] forState:UIControlStateNormal];
        isVideoCaptureMode = YES;
    }
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

- (void)toggleMovieRecording
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
        else
        {
            [movieFileOutput stopRecording];
        }
    });
}

- (void)controlVideoPlayer
{
    // Check whether the video player is already playing
    if (videoPlayer.view.superview)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        
        [videoPlayer stop];
        [videoPlayer.view removeFromSuperview];
        
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_play"] forState:UIControlStateNormal];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerPlaybackDidFinishNotification:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:nil];
        
        CGRect frame = self.cameraCaptureImageView.frame;
        frame.origin = CGPointZero;
        videoPlayer.view.frame = frame;
        videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.cameraCaptureImageView addSubview:videoPlayer.view];
        
        [videoPlayer play];
        
        [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_stop"] forState:UIControlStateNormal];
    }
}

- (void)snapStillImage
{
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
                
                self.cameraCaptureImageView.image = [[UIImage alloc] initWithData:imageData];
                self.cameraCaptureContainerView.hidden = NO;
                self.cameraRetakeButton.enabled = YES;
                self.cameraChooseButton.enabled = YES;
                
                self.cameraCaptureButton.enabled = NO;
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
                self.cameraModeButton.enabled = NO;
                self.cameraSwitchButton.enabled = NO;
                [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_stop"] forState:UIControlStateNormal];
                self.cameraCaptureButton.enabled = YES;
            }
            else
            {
                [self.cameraCaptureButton setImage:[UIImage imageNamed:@"camera_play"] forState:UIControlStateNormal];
                self.cameraCaptureButton.enabled = YES;
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
    
    outputVideoFileURL = outputFileURL;
    
    // Display first video frame
    videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:outputVideoFileURL];
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
    
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
    if (backgroundRecordingID != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        NSLog(@"[MediaPickerVC] >>>>> background pause task finished");
    }
}

#pragma mark - Movie player observer

- (void)moviePlayerThumbnailImageRequestDidFinishNotification:(NSNotification *)notification
{
    self.cameraCaptureImageView.image = [[notification userInfo] objectForKey:MPMoviePlayerThumbnailImageKey];
    self.cameraCaptureContainerView.hidden = NO;
    self.cameraRetakeButton.enabled = YES;
    self.cameraChooseButton.enabled = YES;
    
    self.cameraCaptureButton.enabled = YES;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:nil];
}

- (void)moviePlayerPlaybackDidFinishNotification:(NSNotification *)notification
{
    // Remove player view from superview
    [self controlVideoPlayer];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return assetsFetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MediaAssetCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:recentItemCollectionViewCellId forIndexPath:indexPath];
    
    if (indexPath.row < assetsFetchResult.count)
    {
        PHAsset *asset = assetsFetchResult[indexPath.row];
        
        // Assets are display in full height in collection view
        CGFloat collectionCellHeight = self.recentPictureCollectionViewHeightConstraint.constant;
        // Request an image with the collection cell height by keeping ratio
        CGSize cellSize = CGSizeMake((asset.pixelWidth * collectionCellHeight) / asset.pixelHeight, collectionCellHeight);
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = YES;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:cellSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage *result, NSDictionary *info) {
            cell.imageView.image = result;
        }];
        
        cell.selectionImageView.hidden = ![selectedAssets[indexPath.row] boolValue];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < assetsFetchResult.count)
    {
        if ([selectedAssets[indexPath.row] boolValue])
        {
            selectedAssets[indexPath.row] = @NO;
            
            // Update attach button status by checking selected assets array
            self.libraryChooseButton.enabled = NO;
            for (NSNumber *number in selectedAssets)
            {
                if (number.boolValue)
                {
                    self.libraryChooseButton.enabled = YES;
                    break;
                }
            }
        }
        else
        {
            selectedAssets[indexPath.row] = @YES;
            self.libraryChooseButton.enabled = YES;
        }
        
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        
        // Refresh locally the table
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < assetsFetchResult.count)
    {
        PHAsset *asset = assetsFetchResult[indexPath.row];
        
        // Assets are display in full height in collection view
        CGFloat collectionCellHeight = self.recentPictureCollectionViewHeightConstraint.constant;
        CGSize cellSize = CGSizeMake((asset.pixelWidth * collectionCellHeight) / asset.pixelHeight, collectionCellHeight);
        
        return cellSize;
    }
    return CGSizeZero;
}

@end
