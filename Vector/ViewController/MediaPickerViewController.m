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

#import <Photos/PHCollection.h>
#import <Photos/PHFetchResult.h>
#import <Photos/PHFetchOptions.h>
#import <Photos/PHAsset.h>

@interface MediaPickerViewController ()
{
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
    
    MXKAlert *alert;
}

@property (nonatomic) AVCaptureVideoOrientation previewOrientation;

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
    
    // Adjust layout according to screen size
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat maxSize = (screenSize.height > screenSize.width) ? screenSize.height : screenSize.width;
    self.captureViewContainerHeightConstraint.constant = maxSize / 2;
    [self.view layoutIfNeeded];
    
    // Adjust camera preview ratio
    self.previewOrientation = (AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation];
    
    
//    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumRecentlyAdded options:nil];
//    
//    //set up fetch options, mediaType is image.
//    PHFetchOptions *options = [[PHFetchOptions alloc] init];
//    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
//    options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
//    
//    for (NSInteger i =0; i < smartAlbums.count; i++)
//    {
//        PHAssetCollection *assetCollection = smartAlbums[i];
//        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
//        
//        NSLog(@"sub album title is %@, count is %tu", assetCollection.localizedTitle, assetsFetchResult.count);
//        if (assetsFetchResult.count > 0)
//        {
//            for (PHAsset *asset in assetsFetchResult)
//            {
//                //you have got your image type asset.
//                NSLog(@"%@", asset);
//            }
//        }
//    }
    
    // Check camera access before set up AV capture
    [self checkDeviceAuthorizationStatus];
    [self setupAVCapture];
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

#pragma mark - Override MXKViewController

- (void)destroy
{
    [self stopAVCapture];
    
    cameraQueue = nil;
    
    [super destroy];
}

#pragma mark -

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.navigationItem.leftBarButtonItem)
    {
        [self stopAVCapture];
         
        // Cancel has been pressed
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else if (sender == self.cameraSwitchButton)
    {
        [self toggleCamera];
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
        NSLog(@"Attemping to setup AVCapture when it is already started!");
        return;
    }
    
    [self.cameraActivityIndicator startAnimating];
    
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
            NSLog(@"Failed to take out lock on camera. Device not setup properly.");
        }
    }
    
    currentCameraInput = nil;
    NSError *error = nil;
    if (frontCamera)
    {
        frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontCamera error:&error];
        if (error)
        {
            NSLog(@"Error: %@", error);
        }
        
        if (frontCameraInput == nil)
        {
            NSLog(@"Error creating front camera capture input");
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
            NSLog(@"Error: %@", error);
        }
        
        if (backCameraInput == nil)
        {
            NSLog(@"Error creating back camera capture input");
        }
        else
        {
            currentCameraInput = backCameraInput;
        }
    }
    
    if (currentCameraInput)
    {
        // Create the AVCapture Session
        captureSession = [[AVCaptureSession alloc] init];
        
        [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
        
        cameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        cameraPreviewLayer.frame = self.cameraPreviewContainerView.bounds;
        [[cameraPreviewLayer connection] setVideoOrientation:self.previewOrientation];
        cameraPreviewLayer.masksToBounds = NO;
        cameraPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        cameraPreviewLayer.backgroundColor = [[UIColor blackColor] CGColor];
        cameraPreviewLayer.borderWidth = 2;
        
        [self.cameraPreviewContainerView.layer addSublayer:cameraPreviewLayer];
        [captureSession addInput:currentCameraInput];
        
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
        
        stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([captureSession canAddOutput:stillImageOutput])
        {
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [captureSession addOutput:stillImageOutput];
        }
    }
    else
    {
        [self.cameraActivityIndicator stopAnimating];
    }
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
    
    movieFileOutput = nil;
    stillImageOutput = nil;
    
    currentCameraInput = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:nil];
}

- (void)caughtAVRuntimeError:(NSNotification*)note
{
    NSError *error = [[note userInfo] objectForKey:AVCaptureSessionErrorKey];
    NSLog(@"AV Session Error: %@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self tearDownAVCapture];
        // Retry
        [self performSelector:@selector(setupAVCapture) withObject:nil afterDelay:1.0];
    });
}

- (void)AVCaptureSessionDidStartRunning:(NSNotification*)note {
    
    [self.cameraActivityIndicator stopAnimating];
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

- (void)runStillImageCaptureAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [cameraPreviewLayer setOpacity:0.0];
        
        [UIView animateWithDuration:.25 animations:^{
            [cameraPreviewLayer setOpacity:1.0];
        }];
    });
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
