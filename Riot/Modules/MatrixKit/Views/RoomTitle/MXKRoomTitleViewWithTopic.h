/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomTitleView.h"

/**
 'MXKRoomTitleViewWithTopic' inherits 'MXKRoomTitleView' to add an editable room topic field.
 */
@interface MXKRoomTitleViewWithTopic : MXKRoomTitleView <UIGestureRecognizerDelegate>{
}

@property (weak, nonatomic) IBOutlet UITextField *topicTextField;

@property (nonatomic) BOOL hiddenTopic;

/**
 Stop topic animation.
 
 @return YES if the animation has been stopped.
 */
- (BOOL)stopTopicAnimation;

@end