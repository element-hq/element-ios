/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@interface RecentRoomTableViewCell : MXKRecentTableViewCell

+ (CGFloat)cellHeight;

- (void)setCustomSelected:(BOOL)selected animated:(BOOL)animated;

@end
