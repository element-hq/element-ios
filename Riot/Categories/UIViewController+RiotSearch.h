/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

/**
 The `RiotSearch` category adds the management of the search bar in Riot screens.
 */

#import <UIKit/UIKit.h>

@interface UIViewController (RiotSearch) <UISearchBarDelegate>

/**
 The search bar.
 */
@property (nonatomic, readonly) UISearchBar *searchBar;

/**
 The search bar state.
 */
@property (nonatomic, readonly) BOOL searchBarHidden;

/**
 Show/Hide the search bar.

 @param animated or not.
 */
- (void)showSearch:(BOOL)animated;
- (void)hideSearch:(BOOL)animated;

@end
