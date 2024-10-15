/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

/**
 `MXKResponderRageShaking` defines a protocol an object must conform to handle rage shake
 on view controllers or other kinds of `UIResponder`.
 */
@protocol MXKResponderRageShaking <NSObject>

/**
 Tells the receiver that a motion event has begun.
 
 @param responder the view controller (or another kind of `UIResponder`) which observed the motion.
 */
- (void)startShaking:(UIResponder*)responder;

/**
 Tells the receiver that a motion event has ended.
 
 @param responder the view controller (or another kind of `UIResponder`) which observed the motion.
 */
- (void)stopShaking:(UIResponder*)responder;

/**
 Ignore pending rage shake related to the provided responder.
 
 @param responder a view controller (or another kind of `UIResponder`).
 */
- (void)cancel:(UIResponder*)responder;

@end

