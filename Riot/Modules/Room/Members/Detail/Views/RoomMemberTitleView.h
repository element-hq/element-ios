/*
Copyright 2024 New Vector Ltd.
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

// We add here a protocol to handle title view layout update.
@class RoomMemberTitleView;
@protocol RoomMemberTitleViewDelegate <NSObject>

@optional
/**
 Tells the delegate that the layout has been updated.
 
 @param titleView the room member title view.
 */
- (void)roomMemberTitleViewDidLayoutSubview:(RoomMemberTitleView*)titleView;

@end

@interface RoomMemberTitleView : MXKView

/**
 *  Returns the `UINib` object initialized for the room member title view.
 *
 *  @return The initialized `UINib` object or `nil` if there were errors during
 *  initialization or the nib file could not be located.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `RoomMemberTitleView-inherited` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `RoomMemberTitleView-inherited` object if successful, `nil` otherwise.
 */
+ (instancetype)roomMemberTitleView;

@property (weak, nonatomic) IBOutlet UIView *memberAvatarMask;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *memberAvatarMaskCenterXConstraint;

/**
 The delegate.
 */
@property (nonatomic, weak) id<RoomMemberTitleViewDelegate> delegate;

@end
