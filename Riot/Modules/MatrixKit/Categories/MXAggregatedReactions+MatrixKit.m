/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXAggregatedReactions+MatrixKit.h"

#import "MXKTools.h"

@implementation MXAggregatedReactions (MatrixKit)

- (nullable MXAggregatedReactions *)aggregatedReactionsWithSingleEmoji
{
    NSMutableArray *reactions = [NSMutableArray arrayWithCapacity:self.reactions.count];
    for (MXReactionCount *reactionCount in self.reactions)
    {
        if ([MXKTools isSingleEmojiString:reactionCount.reaction])
        {
            [reactions addObject:reactionCount];
        }
    }

    MXAggregatedReactions *aggregatedReactionsWithSingleEmoji;
    if (reactions.count)
    {
        aggregatedReactionsWithSingleEmoji = [MXAggregatedReactions new];
        aggregatedReactionsWithSingleEmoji.reactions = reactions;
    }

    return aggregatedReactionsWithSingleEmoji;
}

@end
