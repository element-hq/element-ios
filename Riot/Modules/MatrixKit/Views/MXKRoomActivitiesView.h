/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import "MXKView.h"

@protocol MXKRoomActivitiesViewDelegate;

/**
 Customize UIView to display some extra info above the RoomInputToolBar
 */
@interface MXKRoomActivitiesView : MXKView

@property (nonatomic) CGFloat height;

@property (weak, nonatomic) id<MXKRoomActivitiesViewDelegate> delegate;

/**
 Returns the `UINib` object initialized for a `MXKRoomActivitiesView`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `roomActivitiesView` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKRoomActivitiesView-inherited` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKRoomActivitiesView-inherited` object if successful, `nil` otherwise.
 */
+ (instancetype)roomActivitiesView;

/**
 Dispose any resources and listener.
 */
- (void)destroy;

@end

@protocol MXKRoomActivitiesViewDelegate <NSObject>

/**
 Called when the activities view height changes.

 @param roomActivitiesView the MXKRoomActivitiesView instance.
 @param oldHeight its previous height.
 @param newHeight its new height.
 */
- (void)didChangeHeight:(MXKRoomActivitiesView*)roomActivitiesView oldHeight:(CGFloat)oldHeight newHeight:(CGFloat)newHeight;

@end
