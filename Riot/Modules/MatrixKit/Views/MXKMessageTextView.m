/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKMessageTextView.h"
#import "GeneratedInterface-Swift.h"

@interface MXKMessageTextView()

@property (nonatomic, readwrite) CGPoint lastHitTestLocation;
@property (nonatomic) NSHashTable *pillViews;

@end


@implementation MXKMessageTextView

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    self.lastHitTestLocation = point;
    return [super hitTest:point withEvent:event];
}

// Indicate to receive a touch event only if a link is hitted.
// Otherwise it means that the touch event will pass through and could be received by a view below.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (![super pointInside:point withEvent:event])
    {
        return NO;
    }
    
    return [self isThereALinkNearLocation:point];
}

#pragma mark - Pills Flushing

- (void)setText:(NSString *)text
{
    if (@available(iOS 15.0, *)) {
        [self flushPills];
    }
    [super setText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    self.linkTextAttributes = @{};
    if (@available(iOS 15.0, *)) {
        [self flushPills];
    }
    [super setAttributedText:attributedText];

    if (@available(iOS 15.0, *)) {
        // Fixes an iOS 16 issue where attachment are not drawn properly by
        // forcing the layoutManager to redraw the glyphs at all NSAttachment positions.
        [self vc_invalidateTextAttachmentsDisplay];
    }
}

- (void)registerPillView:(UIView *)pillView
{
    [self.pillViews addObject:pillView];
}

/// Flushes all previously registered Pills from their hierarchy.
- (void)flushPills API_AVAILABLE(ios(15))
{
    for (UIView* view in self.pillViews)
    {
        view.alpha = 0.0;
        [view removeFromSuperview];
    }
    self.pillViews = [NSHashTable weakObjectsHashTable];
}

@end
