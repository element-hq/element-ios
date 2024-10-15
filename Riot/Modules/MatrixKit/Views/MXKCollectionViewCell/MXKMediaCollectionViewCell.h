/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKCollectionViewCell.h"

#import <AVKit/AVKit.h>

#import "MXKImageView.h"

/**
 'MXKMediaCollectionViewCell' class is used to display picture or video thumbnail.
 */
@interface MXKMediaCollectionViewCell : MXKCollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *customView;
@property (weak, nonatomic) IBOutlet MXKImageView *mxkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *centerIcon;
@property (weak, nonatomic) IBOutlet UIImageView *bottomLeftIcon;
@property (weak, nonatomic) IBOutlet UIImageView *bottomRightIcon;
@property (weak, nonatomic) IBOutlet UIImageView *topRightIcon;

/**
 A potential player used in the cell.
 */
@property (nonatomic) AVPlayerViewController *moviePlayer;

/**
 A potential observer used to update cell display.
 */
@property (nonatomic) id notificationObserver;

@end
