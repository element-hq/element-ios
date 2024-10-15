/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>
#import "MXKAttachmentAnimator.h"

@interface MXKAttachmentInteractionController : UIPercentDrivenInteractiveTransition

@property (nonatomic) BOOL interactionInProgress;

- (instancetype)initWithDestinationViewController:(UIViewController <MXKDestinationAttachmentAnimatorDelegate> *)viewController sourceViewController:(UIViewController <MXKSourceAttachmentAnimatorDelegate> *)sourceViewController;

@end
