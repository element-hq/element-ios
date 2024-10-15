/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentsViewController.h"

/**
 The `FavouritesViewController` screen is the view controller displayed when `Favourites` tab is selected.
 */
@interface FavouritesViewController : RecentsViewController

+ (instancetype)instantiate;

/**
 Scroll the next room with missed notifications to the top.
 */
- (void)scrollToNextRoomWithMissedNotifications;

@end
