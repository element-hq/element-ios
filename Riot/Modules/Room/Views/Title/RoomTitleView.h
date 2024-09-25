/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "RoomPreviewData.h"

// We add here a protocol to handle tap gesture in title view.
@class RoomTitleView;
@class PresenceIndicatorView;
@protocol PresenceIndicatorViewDelegate;
@protocol RoomTitleViewTapGestureDelegate <NSObject>

/**
 Tells the delegate that a tap gesture has been recognized.
 
 @param titleView the room title view.
 @param tapGestureRecognizer the recognized gesture.
 */
- (void)roomTitleView:(RoomTitleView*)titleView recognizeTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer;

@end

@interface RoomTitleView : MXKRoomTitleView <UIGestureRecognizerDelegate, PresenceIndicatorViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *titleMask;
@property (weak, nonatomic) IBOutlet UIImageView *badgeImageView;
@property (weak, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet PresenceIndicatorView *presenceIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *missedDiscussionsBadgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *typingLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *displayNameCenterYConstraint;
@property (weak, nonatomic) IBOutlet UIView *dotView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *missedDiscussionsBadgeLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pictureViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pictureViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dotViewCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dotViewCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeImageViewToPictureViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeImageViewToPictureViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeImageViewLeadingToPictureViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeImageViewCenterYToDisplayNameConstraint;

/**
 The room preview data may be used when mxRoom instance is not available
 */
@property (strong, nonatomic) RoomPreviewData *roomPreviewData;

/**
 The tap gesture delegate.
 */
@property (weak, nonatomic) id<RoomTitleViewTapGestureDelegate> tapGestureDelegate;

/**
 the typing notification string to be displayed (default nil if notification is hidden).
 */
@property (copy, nonatomic) NSString *typingNotificationString;

/**
 The method used to handle the gesture recognized by a receiver.
 */
- (void)reportTapGesture:(UITapGestureRecognizer*)tapGestureRecognizer;

/**
 update the layout of the title view according to the target orientation
 */
- (void)updateLayoutForOrientation:(UIInterfaceOrientation)orientation;

@end
