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

#import "CustomTableViewCell.h"
#import "MediaManager.h"

@interface CustomTableViewCell () {
    id userPictureLoader;
}
@end

@implementation CustomTableViewCell

- (void)setPictureURL:(NSString *)pictureURL {
    // Cancel media loader in progress (if any)
    if (userPictureLoader) {
        [MediaManager cancel:userPictureLoader];
        userPictureLoader = nil;
    }
    
    _pictureURL = pictureURL;
    
    // Reset image view
    _pictureView.image = nil;
    if (_placeholder) {
        // Set picture placeholder
        _pictureView.image = [UIImage imageNamed:_placeholder];
    }
    // Consider provided url to update image view
    if (pictureURL) {
        // Load picture
        userPictureLoader = [MediaManager loadPicture:pictureURL
                                        success:^(UIImage *image) {
            _pictureView.image = image;
        }
                                        failure:nil];
    }
}

- (void)dealloc
{
    if (userPictureLoader) {
        [MediaManager cancel:userPictureLoader];
        userPictureLoader = nil;
    }
}

@end