/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

