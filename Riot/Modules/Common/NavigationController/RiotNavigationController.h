/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

/**
 RiotNavigationController extends UINavigationController to handle status bar display.
 */

@interface RiotNavigationController : UINavigationController

/**
 When `true` the navigation stack will have its orientation fixed to portrait on iPhone.
 */
@property (nonatomic) BOOL isLockedToPortraitOnPhone;

/**
 Initializes and returns a newly created navigation controller that can be locked to
 portrait when presented on iPhone.
 @param isLockedToPortraitOnPhone Whether to lock interface to portrait on iPhone.
 */
- (instancetype)initWithIsLockedToPortraitOnPhone:(BOOL)isLockedToPortraitOnPhone;

@end

