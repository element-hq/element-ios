/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@interface PublicRoomTableViewCell : MXKPublicRoomTableViewCell

/**
 Configure the cell in order to display the public room.

 @param publicRoom the public room to render.
 */
- (void)render:(MXPublicRoom*)publicRoom withMatrixSession:(MXSession*)mxSession;

@property (weak, nonatomic) IBOutlet MXKImageView *roomAvatar;

/**
 Get the cell height.
 
 @return the cell height.
 */
+ (CGFloat)cellHeight;

@end
