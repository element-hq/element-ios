/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
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

#import "MXKMediaCollectionViewCell.h"

@implementation MXKMediaCollectionViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.moviePlayer.player pause];
    self.moviePlayer.player = nil;
    self.moviePlayer = nil;
    
    // Restore the cell in reusable state
    self.mxkImageView.hidden = NO;
    self.mxkImageView.stretchable = NO;
    // Cancel potential image download
    self.mxkImageView.enableInMemoryCache = NO;
    [self.mxkImageView setImageURI:nil
                          withType:nil
               andImageOrientation:UIImageOrientationUp
                      previewImage:nil
                      mediaManager:nil];
    
    self.customView.hidden = YES;
    self.centerIcon.hidden = YES;
    
    // Remove added view in custon view
    NSArray *subViews = self.customView.subviews;
    for (UIView *view in subViews)
    {
        [view removeFromSuperview];
    }
    
    // Remove potential media download observer
    if (self.notificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.notificationObserver];
        self.notificationObserver = nil;
    }
    
    // Remove all gesture recognizers
    while (self.gestureRecognizers.count)
    {
        [self removeGestureRecognizer:self.gestureRecognizers[0]];
    }
    self.tag = -1;
}

- (void)dealloc
{
    [self.moviePlayer.player pause];
    self.moviePlayer.player = nil;
}

@end

