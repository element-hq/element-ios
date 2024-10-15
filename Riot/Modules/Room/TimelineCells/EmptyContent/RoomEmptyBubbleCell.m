/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomEmptyBubbleCell.h"

@implementation RoomEmptyBubbleCell

- (void)prepareForReuse
{
    [super prepareForReuse];

    if (self.heightConstraint != 0)
    {
        self.heightConstraint = 0;
    }
}

@end
