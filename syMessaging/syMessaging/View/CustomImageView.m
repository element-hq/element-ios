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
        if (loadingWheel == nil) {
            loadingWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            loadingWheel.center = self.center;
            [self addSubview:loadingWheel];
        }
        
        [loadingWheel startAnimating];
        imageLoader = [MediaManager loadPicture:imageURL
                                        success:^(UIImage *image) {
                                            [loadingWheel stopAnimating];
                                            self.image = image;
                                        }
                                        failure:^(NSError *error) {
                                            [loadingWheel stopAnimating];
                                            NSLog(@"Failed to download image (%@): %@", imageURL, error);
                                        }];
    }
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
}

@end