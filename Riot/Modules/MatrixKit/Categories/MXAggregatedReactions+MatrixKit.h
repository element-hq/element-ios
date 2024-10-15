/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKEventFormatter.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Define a `MXEvent` category at matrixKit level to store data related to UI handling.
 */
@interface MXAggregatedReactions (MatrixKit)

- (nullable MXAggregatedReactions *)aggregatedReactionsWithSingleEmoji;

@end

NS_ASSUME_NONNULL_END
