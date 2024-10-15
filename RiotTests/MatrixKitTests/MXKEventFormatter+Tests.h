/*
Copyright 2024 New Vector Ltd.
Copyright 2021 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKEventFormatter.h"

@interface MXKEventFormatter (Tests)

- (NSString*)userDisplayNameFromContentInEvent:(MXEvent*)event withMembershipFilter:(NSString *)filter;
- (NSString*)userAvatarUrlFromContentInEvent:(MXEvent*)event withMembershipFilter:(NSString *)filter;
- (NSString*)buildHTMLStringForEvent:(MXEvent*)event inReplyToEvent:(MXEvent*)repliedEvent;

@end
