/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentsViewController.h"
#import "ContactsDataSource.h"

/**
 'PeopleViewController' instance is used to display/filter the direct rooms and a list of contacts.
 */
@interface PeopleViewController : RecentsViewController

+ (instancetype)instantiate;

/**
 Scroll the next room with missed notifications to the top.
 */
- (void)scrollToNextRoomWithMissedNotifications;

@end

