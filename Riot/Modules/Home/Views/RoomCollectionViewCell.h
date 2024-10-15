/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@class BadgeLabel;
@class PresenceIndicatorView;

/**
 'RoomCollectionViewCell' class is used to display a room in a collection view.
 */
@interface RoomCollectionViewCell : MXKCollectionViewCell <MXKCellRendering>
{
@protected
    /**
     The current cell data displayed by the collection view cell
     */
    id<MXKRecentCellDataStoring> roomCellData;
}

@property (weak, nonatomic) IBOutlet UILabel *roomTitle;
@property (weak, nonatomic) IBOutlet UILabel *roomTitle1;
@property (weak, nonatomic) IBOutlet UILabel *roomTitle2;

@property (weak, nonatomic) IBOutlet UIView *editionArrowView;

@property (weak, nonatomic) IBOutlet MXKImageView *roomAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;
@property (weak, nonatomic) IBOutlet PresenceIndicatorView *presenceIndicatorView;

@property (weak, nonatomic) IBOutlet BadgeLabel *badgeLabel;

@property (nonatomic, readonly) NSString *roomId;

@property (nonatomic) NSInteger collectionViewTag; // default is -1

/**
 The default collection view cell size.
 */
+ (CGSize)defaultCellSize;

@end
