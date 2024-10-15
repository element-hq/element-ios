/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCellWithButton.h"

@implementation MXKTableViewCellWithButton

- (void)prepareForReuse
{
    [super prepareForReuse];

    // TODO: Code commented for a quick fix for https://github.com/vector-im/riot-ios/issues/1323
    // This line was a fix for https://github.com/vector-im/riot-ios/issues/1354
    // but it creates a regression that is worse than the bug it fixes.
    // self.mxkButton.titleLabel.text = nil;

    [self.mxkButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    self.mxkButton.accessibilityIdentifier = nil;
}

@end
