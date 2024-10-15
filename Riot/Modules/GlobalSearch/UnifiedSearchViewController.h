/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "SegmentedViewController.h"

#import "ContactsTableViewController.h"

/**
 The `UnifiedSearchViewController` screen is the global search screen.
 */
@interface UnifiedSearchViewController : SegmentedViewController <UIGestureRecognizerDelegate, ContactsTableViewControllerDelegate>

+ (instancetype)instantiate;

/**
 Open the public rooms directory page.
 It uses the `publicRoomsDirectoryDataSource` managed by the recents view controller data source
 */
- (void)showPublicRoomsDirectory;

/**
 Tell whether an event has been selected from messages or files search tab.
 */
@property (nonatomic, readonly) MXEvent *selectedSearchEvent;
@property (nonatomic, readonly) MXSession *selectedSearchEventSession;

@end
