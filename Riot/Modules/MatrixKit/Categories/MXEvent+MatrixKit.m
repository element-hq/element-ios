/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXEvent+MatrixKit.h"
#import <objc/runtime.h>

@implementation MXEvent (MatrixKit)

- (MXKEventFormatterError)mxkEventFormatterError
{
    NSNumber *associatedError = objc_getAssociatedObject(self, @selector(mxkEventFormatterError));
    if (associatedError)
    {
        return [associatedError unsignedIntegerValue];
    }
    return MXKEventFormatterErrorNone;
}

- (void)setMxkEventFormatterError:(MXKEventFormatterError)mxkEventFormatterError
{
    objc_setAssociatedObject(self, @selector(mxkEventFormatterError), [NSNumber numberWithUnsignedInteger:mxkEventFormatterError], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)mxkIsHighlighted
{
    NSNumber *associatedIsHighlighted = objc_getAssociatedObject(self, @selector(mxkIsHighlighted));
    if (associatedIsHighlighted)
    {
        return [associatedIsHighlighted boolValue];
    }
    return NO;
}

- (void)setMxkIsHighlighted:(BOOL)mxkIsHighlighted
{
    objc_setAssociatedObject(self, @selector(mxkIsHighlighted), [NSNumber numberWithBool:mxkIsHighlighted], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
