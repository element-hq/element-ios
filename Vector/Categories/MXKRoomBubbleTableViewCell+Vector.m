/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MXKRoomBubbleTableViewCell+Vector.h"

#import <objc/runtime.h>

@implementation MXKRoomBubbleTableViewCell (Vector)

- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex
{
    // FIXME GFO uncomment the following block
//    // Ensure that older subviews are removed
//    // They should be (they are removed when the is not anymore used).
//    // But, it seems that is not always true.
//    NSArray* views = [self.bubbleInfoContainer subviews];
//    for (UIView* view in views)
//    {
//        [view removeFromSuperview];
//    }
    
    self.bubbleInfoContainer.hidden = NO;
    
    MXKRoomBubbleComponent *component;
    if (componentIndex < self.bubbleData.bubbleComponents.count)
    {
        component  = self.bubbleData.bubbleComponents[componentIndex];
    }
    
    if (component && component.date)
    {
        UILabel *dateTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, component.position.y, self.bubbleInfoContainer.frame.size.width , 15)];
        
        dateTimeLabel.text = [self.bubbleData.eventFormatter timeStringFromDate:component.date];
        dateTimeLabel.textAlignment = NSTextAlignmentRight;
        dateTimeLabel.textColor = [UIColor lightGrayColor];
        dateTimeLabel.font = [UIFont systemFontOfSize:11];
        dateTimeLabel.adjustsFontSizeToFitWidth = NO;
        
        [dateTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bubbleInfoContainer addSubview:dateTimeLabel];
        
        // Force dateTimeLabel in full width (to handle auto-layout in case of screen rotation)
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.bubbleInfoContainer
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:0];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.bubbleInfoContainer
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        // Vertical constraints are required for iOS > 8
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.bubbleInfoContainer
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:component.position.y];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:15];
        
        if ([NSLayoutConstraint respondsToSelector:@selector(activateConstraints:)])
        {
            [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, heightConstraint]];
        }
        else
        {
            [self.bubbleInfoContainer addConstraint:leftConstraint];
            [self.bubbleInfoContainer addConstraint:rightConstraint];
            [self.bubbleInfoContainer addConstraint:topConstraint];
            [dateTimeLabel addConstraint:heightConstraint];
        }
    }
}

- (void)removeTimestampLabels
{
    // In Vector, only time labels are displayed in bubbleInfoContainer
    // So we may remove all bubbleInfoContainer subviews here.
    NSArray* views = [self.bubbleInfoContainer subviews];
    for (UIView* view in views)
    {
        [view removeFromSuperview];
    }
    
    self.bubbleInfoContainer.hidden = YES;
}

- (void)selectComponent:(NSUInteger)componentIndex
{
    MXKRoomBubbleComponent *component;
    if (componentIndex < self.bubbleData.bubbleComponents.count)
    {
        [self addTimestampLabelForComponent:componentIndex];
        
        component  = self.bubbleData.bubbleComponents[componentIndex];
        [self highlightTextMessageForEvent:component.event.eventId];
    }
}

- (void)unselectComponent
{
    // FIXME GFO: handle the case of the last message thanks to showDateTime flag
    [self removeTimestampLabels];
    
    // Restore original string
    [self highlightTextMessageForEvent:nil];
}

- (void)setBlurred:(BOOL)blurred
{
    objc_setAssociatedObject(self, @selector(blurred), [NSNumber numberWithBool:blurred], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (blurred)
    {
        self.bubbleOverlayContainer.backgroundColor = [UIColor whiteColor];
        self.bubbleOverlayContainer.alpha = 0.8;
        self.bubbleOverlayContainer.hidden = NO;
    }
    else
    {
        self.bubbleOverlayContainer.hidden = YES;
    }
}

- (BOOL)blurred
{
    NSNumber *associatedBlurred = objc_getAssociatedObject(self, @selector(blurred));
    if (associatedBlurred)
    {
        return [associatedBlurred boolValue];
    }
    return NO;
}

@end
