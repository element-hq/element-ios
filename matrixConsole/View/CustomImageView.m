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

@interface CustomImageView () {
    id imageLoader;
    UIActivityIndicatorView *loadingWheel;
}
@end

@implementation CustomImageView

- (void)dealloc {
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    if (loadingWheel) {
        [loadingWheel removeFromSuperview];
        loadingWheel = nil;
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
                                        success:^(UIImage *image) {
                                            [self stopActivityIndicator];
                                            self.image = image;
                                        }
                                        failure:^(NSError *error) {
                                            [self stopActivityIndicator];
                                            NSLog(@"Failed to download image (%@): %@", imageURL, error);
                                        }];
    }
}

@end