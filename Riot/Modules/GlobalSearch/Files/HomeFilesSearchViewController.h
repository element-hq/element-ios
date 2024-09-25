/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */


#import "MatrixKit.h"

@class AnalyticsScreenTracker;

/**
 `HomeFilesSearchViewController` displays the files search in user's rooms under a `HomeViewController` segment.
 */
@interface HomeFilesSearchViewController : MXKSearchViewController

/**
 The event selected in the search results
 */
@property (nonatomic, readonly) MXEvent *selectedEvent;

/**
 The screen timer used for analytics if they've been enabled. The default value is nil.
 */
@property (nonatomic) AnalyticsScreenTracker *screenTracker;

@end
