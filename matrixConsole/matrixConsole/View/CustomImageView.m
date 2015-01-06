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

@interface CustomImageView () {
    id imageLoader;
    UIActivityIndicatorView *loadingWheel;
    
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
    NSString* loadedImageURL;
    UIImage* _image;
}
@end

@implementation CustomImageView
@synthesize canBeZoomed;

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
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    if (loadingWheel) {
        [loadingWheel removeFromSuperview];
        loadingWheel = nil;
    }
    if (bottomBarView) {
        [bottomBarView removeFromSuperview];
        bottomBarView = nil;
    }
}

- (void)startActivityIndicator {
    // Add activity indicator if none
    if (loadingWheel == nil) {
        loadingWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:loadingWheel];
    }
    // Adjust position
    CGPoint center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    loadingWheel.center = center;
    // Adjust color
    if ([self.backgroundColor isEqual:[UIColor blackColor]]) {
        loadingWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    } else {
        loadingWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }
    // Start
    [loadingWheel startAnimating];
}

- (void)stopActivityIndicator {
    if (loadingWheel) {
        [loadingWheel stopAnimating];
    }
}

#pragma mark -

// image setter/getter
- (void)setImage:(UIImage *)anImage {
    _image = anImage;
    
    imageView.image = anImage;
    [self initScrollZoomFactors];
}

- (UIImage*)image {
    return _image;
}

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

    // use the same text color as the tabbar
    [button setTitleColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor forState:UIControlStateNormal];
    [button setTitleColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor forState:UIControlStateHighlighted];

    // keep the bottomView background color
    button.backgroundColor = [UIColor clearColor];
    
    [button addTarget:self action:@selector(onButtonToggle:) forControlEvents:UIControlEventTouchUpInside];
    [bottomBarView addSubview:button];
    
    return button;
}

- (void)initScrollZoomFactors {
    // check if the image can be zoomed
    if (self.image && self.canBeZoomed && imageView.frame.size.width && imageView.frame.size.height) {
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

- (void)layoutSubviews {
    
    // call upper layer
    [super layoutSubviews];

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
    
    // the image has been updated
    if (imageView.image != self.image) {
        imageView.image = self.image;
    }

    // update the scrollview frame
    CGRect oneSelfFrame = CGRectIntegral(self.frame);
    CGRect scrollViewFrame = CGRectIntegral(scrollView.frame);
    
    oneSelfFrame.origin = scrollViewFrame.origin = CGPointZero;
    
    // use integral rect to avoid rounded value issue (float precision)
    if (!CGRectEqualToRect(CGRectIntegral(self.frame), CGRectIntegral(scrollView.frame))) {
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

            // default tabbar background color
            CGFloat base = 248.0 / 255.0f;
            bottomBarView.backgroundColor = [UIColor colorWithRed:base green:base blue:base alpha:1.0];
            
            [[AppDelegate theDelegate].masterTabBarController.tabBar addSubview:bottomBarView];
        }

        // manage the item 
        CGRect tabBarFrame = [AppDelegate theDelegate].masterTabBarController.tabBar.frame;
        tabBarFrame.origin.y = 0;
        bottomBarView.frame = tabBarFrame;
        
        if (leftButton) {
            leftButton.frame = CGRectMake(0, 0, CUSTOM_IMAGE_VIEW_BUTTON_WIDTH, bottomBarView.frame.size.height);
        }
        
        if (rightButton) {
            rightButton.frame = CGRectMake(bottomBarView.frame.size.width - CUSTOM_IMAGE_VIEW_BUTTON_WIDTH, 0, CUSTOM_IMAGE_VIEW_BUTTON_WIDTH, bottomBarView.frame.size.height);
        }
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

- (void)setImageURL:(NSString *)imageURL {
    // the displayed image is already the expected one ?
    if ([imageURL isEqualToString:loadedImageURL]) {
        
        // check if the image content has not been released
        if (self.image.size.width && self.image.size.height) {
            return;
        }
        
        loadedImageURL = nil;
    }
    
    // Cancel media loader in progress (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    
    _imageURL = imageURL;
    
    // Reset image view
    self.image = nil;
    if (_placeholder) {
        // Set picture placeholder
        self.image = [UIImage imageNamed:_placeholder];
    }
    
    // Consider provided url to update image view
    if (imageURL) {
        // Load picture
        if (!_hideActivityIndicator) {
            [self startActivityIndicator];
        }
        imageLoader = [MediaManager loadPicture:imageURL
                                        success:^(UIImage *anImage) {
                                            [self stopActivityIndicator];
                                            self.image = anImage;
                                            loadedImageURL = imageURL;
                                        }
                                        failure:^(NSError *error) {
                                            [self stopActivityIndicator];
                                            NSLog(@"Failed to download image (%@): %@", imageURL, error);
                                        }];
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
}

#pragma mark - UIScrollViewDelegate
// require to be able to zoom an image
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.canBeZoomed ? imageView : nil;
}

@end