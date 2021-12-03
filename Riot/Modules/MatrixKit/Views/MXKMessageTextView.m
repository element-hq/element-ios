/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKMessageTextView.h"
#import "UITextView+MatrixKit.h"

@interface MXKMessageTextView()

@property (nonatomic, readwrite) CGPoint lastHitTestLocation;

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
    
    return [self isThereALinkNearPoint:point];
}

@end
