/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

/**
 `MXKErrorPresentable` describe an error to display on screen.
 */
@protocol MXKErrorPresentable

@required

@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *message;

- (id)initWithTitle:(NSString*)title message:(NSString*)message;

@end
