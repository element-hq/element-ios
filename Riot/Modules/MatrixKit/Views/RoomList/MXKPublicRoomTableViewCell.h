/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <MatrixSDK/MatrixSDK.h>

#import "MXKTableViewCell.h"

@interface MXKPublicRoomTableViewCell : MXKTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *roomDisplayName;
@property (weak, nonatomic) IBOutlet UILabel *memberCount;
@property (weak, nonatomic) IBOutlet UILabel *roomTopic;

@property (nonatomic, getter=isHighlightedPublicRoom) BOOL highlightedPublicRoom;

/**
 Configure the cell in order to display the public room.
 
 @param publicRoom the public room to render.
 */
- (void)render:(MXPublicRoom*)publicRoom;

@end