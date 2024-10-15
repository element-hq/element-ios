/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKEventFormatter.h"

/**
 Define a `MXEvent` category at matrixKit level to store data related to UI handling.
 */
@interface MXEvent (MatrixKit)

/**
 The potential error observed when the event formatter tried to stringify the event (MXKEventFormatterErrorNone by default).
 */
@property (nonatomic) MXKEventFormatterError mxkEventFormatterError;

/**
 Tell whether the event is highlighted or not (NO by default).
 */
@property (nonatomic) BOOL mxkIsHighlighted;

@end
