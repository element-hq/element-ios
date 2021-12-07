/*
 Copyright 2019 The Matrix.org Foundation C.I.C

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
