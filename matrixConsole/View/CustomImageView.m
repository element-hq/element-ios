/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "CustomImageView.h"
#import "MediaManager.h"
#import "AppDelegate.h"
#import "PieChartView.h"

@interface CustomImageView () {
    id imageLoader;
    
    // the loading view is composed with the spinner and a pie chart
    // the spinner is display until progress > 0
    UIView* loadingView;
    UIActivityIndicatorView *waitingDownloadSpinner;
    PieChartView *pieChartView;

    // validation buttons
    UIButton* leftButton;
    UIButton* rightButton;
    
    NSString* leftButtonTitle;
    NSString* rightButtonTitle;
    
    blockCustomImageView_onClick leftHandler;
    blockCustomImageView_onClick rightHandler;
    
    UIView* bottomBarView;

    // sub items
    UIScrollView* scrollView;
    UIImageView* imageView;

    //
    NSString* downloadingImageURL;
    NSString* loadedImageURL;
    UIImage* _image;
    
    BOOL useFullScreen;
}
@end

@implementation CustomImageView
@synthesize stretchable;

#define CUSTOM_IMAGE_VIEW_BUTTON_WIDTH 100

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        leftButtonTitle = nil;
        leftHandler = nil;
        rightButtonTitle = nil;
        rightHandler = nil;
        
        self.backgroundColor = [UIColor blackColor];
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaDownloadProgressNotification object:nil];
    
    [self stopActivityIndicator];
    
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    if (loadingView) {
        [loadingView removeFromSuperview];
        loadingView = nil;
    }
    if (bottomBarView) {
        [bottomBarView removeFromSuperview];
        bottomBarView = nil;
    }
}

- (void)startActivityIndicator {
    // create the views if they don't exist
    if (!waitingDownloadSpinner) {
        waitingDownloadSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        CGRect frame = waitingDownloadSpinner.frame;
        frame.size.width += 30;
        frame.size.height += 30;
        waitingDownloadSpinner.bounds = frame;
        [waitingDownloadSpinner.layer setCornerRadius:5];
    }
    
    if (!loadingView) {
        loadingView = [[UIView alloc] init];
        loadingView.frame = waitingDownloadSpinner.bounds;
        [loadingView addSubview:waitingDownloadSpinner];
        loadingView.backgroundColor = [UIColor clearColor];
        [self addSubview:loadingView];
    }
    
    if (!pieChartView) {
        pieChartView = [[PieChartView alloc] init];
        pieChartView.frame = loadingView.bounds;
        pieChartView.progress = 0;
        pieChartView.progressColor = [UIColor redColor];
        pieChartView.unprogressColor = [UIColor clearColor];
    
        [loadingView addSubview:pieChartView];
    }
    
    // initvalue
    loadingView.hidden = NO;
    pieChartView.progress = 0;
    
    // Adjust color
    if ([self.backgroundColor isEqual:[UIColor blackColor]]) {
        waitingDownloadSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        // a preview image could be displayed
        // ensure that the white spinner is visible
        // it could be drawn on a white area
        waitingDownloadSpinner.backgroundColor = [UIColor darkGrayColor];
        
    } else {
        waitingDownloadSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }

        // ensure that the spinner is drawn at the top
    [loadingView.superview bringSubviewToFront:loadingView];
    
    // Adjust position
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    loadingView.center = center;
    
    // Start
    [waitingDownloadSpinner startAnimating];
}

- (void)stopActivityIndicator {
    if (waitingDownloadSpinner && waitingDownloadSpinner.isAnimating) {
        [waitingDownloadSpinner stopAnimating];
    }
    
    pieChartView.progress = 0;
    loadingView.hidden = YES;
}

#pragma mark - setters/getters

- (void)setImage:(UIImage *)anImage {
    _image = anImage;
    
    imageView.image = anImage;
    [self initScrollZoomFactors];
}

- (UIImage*)image {
    return _image;
}

- (void)setFullScreen:(BOOL)fullScreen {
    useFullScreen = fullScreen;
    
    [self initLayout];
    
    if (useFullScreen) {
        [self removeFromSuperview];
        [UIApplication sharedApplication].statusBarHidden = YES;
                
        self.frame = [AppDelegate theDelegate].window.rootViewController.view.bounds;
        [[AppDelegate theDelegate].window.rootViewController.view addSubview:self];
    }
}

- (BOOL)fullScreen {
    return useFullScreen;
}

#pragma mark -
- (IBAction)onButtonToggle:(id)sender
{
    if (sender == leftButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            leftHandler(self, leftButtonTitle);
        });
    } else if (sender == rightButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            rightHandler(self, rightButtonTitle);
        });
    }
}

// add a generic button to the bottom view
// return the added UIButton
- (UIButton*) addbuttonWithTitle:(NSString*)title  {
    UIButton* button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateHighlighted];
    
    if (useFullScreen) {
        // use the same text color as the tabbar
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    }
    else  {
        // use the same text color as the tabbar
        [button setTitleColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor forState:UIControlStateNormal];
        [button setTitleColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor forState:UIControlStateHighlighted];
    }

    // keep the bottomView background color
    button.backgroundColor = [UIColor clearColor];
    
    [button addTarget:self action:@selector(onButtonToggle:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarView addSubview:button];
    
    return button;
}

- (void)initScrollZoomFactors {
    // check if the image can be zoomed
    if (self.image && self.stretchable && imageView.frame.size.width && imageView.frame.size.height) {
        // ensure that the content size is properly initialized
        scrollView.contentSize = scrollView.frame.size;
        
        // compute the appliable zoom factor
        // assume that the user does not expect to zoom more than 100%
        CGSize imageSize = self.image.size;
        
        CGFloat scaleX = imageSize.width  / imageView.frame.size.width;
        CGFloat scaleY = imageSize.height / imageView.frame.size.height;
        
        if (scaleX < scaleY)
        {
            scaleX = scaleY;
        }
        
        if (scaleX < 1.0)
        {
            scaleX = 1.0;
        }
        
        scrollView.zoomScale        = 1.0;
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = scaleX;
        
        // update the image frame to ensure that it fits to the scrollview frame
        imageView.frame = scrollView.bounds;
    }
}

- (void)removeFromSuperview {
    [super removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaDownloadProgressNotification object:nil];
    
    if (useFullScreen) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    
    [self stopActivityIndicator];
}

- (void)initLayout {
    // create the subviews if they don't exist
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] init];
        scrollView.delegate = self;
        scrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:scrollView];
        
        imageView = [[UIImageView alloc] init];
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [scrollView addSubview:imageView];
    }
}

- (void)layoutSubviews {
    
    // call upper layer
    [super layoutSubviews];

    [self initLayout];
    
    // the image has been updated
    if (imageView.image != self.image) {
        imageView.image = self.image;
    }
    
    CGRect tabBarFrame = [AppDelegate theDelegate].masterTabBarController.tabBar.frame;

    // update the scrollview frame
    CGRect oneSelfFrame = self.frame;
    CGRect scrollViewFrame = CGRectIntegral(scrollView.frame);
    
    if (leftButtonTitle || rightButtonTitle) {
        oneSelfFrame.size.height -= tabBarFrame.size.height;
    }
    
    oneSelfFrame = CGRectIntegral(oneSelfFrame);
    oneSelfFrame.origin = scrollViewFrame.origin = CGPointZero;
    
    // use integral rect to avoid rounded value issue (float precision)
    if (!CGRectEqualToRect(oneSelfFrame, scrollViewFrame)) {
        scrollView.frame = oneSelfFrame;
        imageView.frame = oneSelfFrame;
        
        [self initScrollZoomFactors];
    }
    
    // check if the dedicated buttons are already added
    if (leftButtonTitle || rightButtonTitle) {
        
        if (!bottomBarView) {
            bottomBarView = [[UIView alloc] init];
            
            if (leftButtonTitle) {
                leftButton = [self addbuttonWithTitle:leftButtonTitle];
            }
            
            rightButton = [[UIButton alloc] init];
            
            if (rightButtonTitle) {
                rightButton = [self addbuttonWithTitle:rightButtonTitle];
            }

            // in fullscreen, display both buttons above the view
            if (useFullScreen) {
                bottomBarView.backgroundColor = [UIColor blackColor];
                [self addSubview:bottomBarView];
            }
            // display them above the tabbar
            else {
                // default tabbar background color
                CGFloat base = 248.0 / 255.0f;
  
                bottomBarView.backgroundColor = [UIColor colorWithRed:base green:base blue:base alpha:1.0];
                [[AppDelegate theDelegate].masterTabBarController.tabBar addSubview:bottomBarView];
            }
        }
        
        if (useFullScreen) {
            tabBarFrame.origin.y = self.frame.size.height - tabBarFrame.size.height;
        }
        else {
            tabBarFrame.origin.y = 0;
        }
        bottomBarView.frame = tabBarFrame;
        
        if (leftButton) {
            leftButton.frame = CGRectMake(0, 0, CUSTOM_IMAGE_VIEW_BUTTON_WIDTH, bottomBarView.frame.size.height);
        }
        
        if (rightButton) {
            rightButton.frame = CGRectMake(bottomBarView.frame.size.width - CUSTOM_IMAGE_VIEW_BUTTON_WIDTH, 0, CUSTOM_IMAGE_VIEW_BUTTON_WIDTH, bottomBarView.frame.size.height);
        }
    }
    
    if (!loadingView.hidden) {
        // ensure that the spinner is drawn at the top
        [loadingView.superview bringSubviewToFront:loadingView];
        
        // Adjust position
        CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        loadingView.center = center;
    }
}

- (void)setHideActivityIndicator:(BOOL)hideActivityIndicator {
    _hideActivityIndicator = hideActivityIndicator;
    if (hideActivityIndicator) {
        [self stopActivityIndicator];
    } else if (imageLoader) {
        // Loading is in progress, start activity indicator
        [self startActivityIndicator];
    }
}

- (void)setImageURL:(NSString *)anImageURL withPreviewImage:(UIImage*)previewImage {
    // the displayed image is already the expected one ?
    if ([anImageURL isEqualToString:loadedImageURL]) {
        
        // check if the image content has not been released
        if (self.image.size.width && self.image.size.height) {
            return;
        }
        
        loadedImageURL = nil;
    }
    
    // the current image is already downloading
    // please wait....
    // it could be triggered after a screen rotation, new message ...
    if (anImageURL && [anImageURL isEqualToString:downloadingImageURL]) {
        return;
    }
    
    // Cancel media loader in progress (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
        downloadingImageURL = nil;
    }
    
    // preview image until the image is loaded
    self.image = previewImage;
    
    // Consider provided url to update image view
    if (anImageURL) {
        
        // store the downloading media
        downloadingImageURL = anImageURL;
        
        // Load picture
        if (!_hideActivityIndicator) {
            [self startActivityIndicator];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadProgress:) name:kMediaDownloadProgressNotification object:nil];
        
        imageLoader = [MediaManager loadPicture:downloadingImageURL
                                        success:^(UIImage *anImage) {
                                            downloadingImageURL = nil;
                                            [self stopActivityIndicator];
                                            self.image = anImage;
                                            loadedImageURL = anImageURL;
                                            
                                            [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaDownloadProgressNotification object:nil];
                                        }
                                        failure:^(NSError *error) {
                                            [self stopActivityIndicator];
                                            downloadingImageURL = nil;
                                            NSLog(@"Failed to download image (%@): %@", anImageURL, error);
                                            [[NSNotificationCenter defaultCenter] removeObserver:self name:kMediaDownloadProgressNotification object:nil];
                                        }];
    }
}

- (void)onMediaDownloadProgress:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:downloadingImageURL]) {
            NSNumber* progressNumber = [notif.userInfo valueForKey:kMediaManagerProgressKey];
            
            if (progressNumber) {
                pieChartView.progress = progressNumber.floatValue;
                waitingDownloadSpinner.hidden = YES;
            }
        }
    }
}

#pragma mark - buttons management

- (void)setLeftButtonTitle: aLeftButtonTitle handler:(blockCustomImageView_onClick)handler {
    leftButtonTitle = aLeftButtonTitle;
    leftHandler = handler;
}

- (void)setRightButtonTitle:aRightButtonTitle handler:(blockCustomImageView_onClick)handler {
    rightButtonTitle = aRightButtonTitle;
    rightHandler = handler;
}

- (void)dismissSelection {
    if (bottomBarView) {
        [bottomBarView removeFromSuperview];
        bottomBarView = nil;
    }
    
    if (useFullScreen) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
}

#pragma mark - UIScrollViewDelegate
// require to be able to zoom an image
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.stretchable ? imageView : nil;
}

@end