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

#import "RoomBubbleCellData.h"

#import "VectorDesignValues.h"

#import <objc/runtime.h>

NSString *const kMXKRoomBubbleCellVectorEditButtonPressed = @"kMXKRoomBubbleCellVectorEditButtonPressed";

@implementation MXKRoomBubbleTableViewCell (Vector)

- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex
{
    self.bubbleInfoContainer.hidden = NO;
    
    MXKRoomBubbleComponent *component;
    if (componentIndex < self.bubbleData.bubbleComponents.count)
    {
        component  = self.bubbleData.bubbleComponents[componentIndex];
    }
    
    if (component && component.date)
    {
        UILabel *dateTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, component.position.y, self.bubbleInfoContainer.frame.size.width , 18)];
        
        dateTimeLabel.text = [self.bubbleData.eventFormatter timeStringFromDate:component.date];
        dateTimeLabel.textAlignment = NSTextAlignmentRight;
        dateTimeLabel.textColor = kVectorTextColorGray;
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
        {
             dateTimeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        }
        else
        {
             dateTimeLabel.font = [UIFont systemFontOfSize:12];
        }
        dateTimeLabel.adjustsFontSizeToFitWidth = YES;

        dateTimeLabel.tag = componentIndex;
        
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
                                                                             constant:18];
        
        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, heightConstraint]];
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
        // Add time label
        [self addTimestampLabelForComponent:componentIndex];
        
        // Hightlight selection by blurring other components
        component  = self.bubbleData.bubbleComponents[componentIndex];
        [self highlightTextMessageForEvent:component.event.eventId];
        
        // Blur timestamp labels which are not related to the selected component (if any)
        for (UIView* view in self.bubbleInfoContainer.subviews)
        {
            // Note dateTime label tag is equal to the index of the related component.
            if (view.tag != componentIndex)
            {
                view.alpha = 0.2;
            }
        }
        
        // Retrieve the read receipts container related to the selected component (if any)
        // Blur the others
        for (UIView* view in self.bubbleOverlayContainer.subviews)
        {
            // Note read receipt container tag is equal to the index of the related component.
            if (view.tag != componentIndex)
            {
                view.alpha = 0.2;
            }
            else if ([view isKindOfClass:MXKReceiptSendersContainer.class])
            {
                self.selectedReadReceiptsContainer = (MXKReceiptSendersContainer*)view;
            }
        }
        
        // Add the edit button (shift left the receipts container if any).
        [self addEditButtonForComponent:componentIndex completion:nil];
    }
}

- (void)unselectComponent
{
    // Remove edit button (Restore receipts container position if any)
    [self removeEditButton:nil];

    // Remove all timestamps by default
    [self removeTimestampLabels];
    
    // Restore timestamp for the last message if the current bubble is the last one
    if ([self.bubbleData isKindOfClass:RoomBubbleCellData.class])
    {
        RoomBubbleCellData *cellData = (RoomBubbleCellData*)self.bubbleData;
        if (cellData.isLastBubble && cellData.bubbleComponents.count)
        {
            [self addTimestampLabelForComponent:cellData.bubbleComponents.count - 1];
        }
    }
    
    // Restore original string
    [self highlightTextMessageForEvent:nil];
    
    // Restore read receipts display
    for (UIView* view in self.bubbleOverlayContainer.subviews)
    {
        view.alpha = 1;
    }
}

- (void)setBlurred:(BOOL)blurred
{
    objc_setAssociatedObject(self, @selector(blurred), [NSNumber numberWithBool:blurred], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (blurred)
    {
        self.bubbleOverlayContainer.hidden = NO;
        self.bubbleOverlayContainer.backgroundColor = [UIColor whiteColor];
        self.bubbleOverlayContainer.alpha = 0.8;
        self.bubbleOverlayContainer.userInteractionEnabled = YES;
        
        // Blur read receipts if any
        for (UIView* view in self.bubbleOverlayContainer.subviews)
        {
            view.alpha = 0.2;
        }
    }
    else
    {
        if (self.bubbleOverlayContainer.subviews.count)
        {
            // Keep this overlay visible, adjust background color
            self.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
            self.bubbleOverlayContainer.alpha = 1;
            self.bubbleOverlayContainer.userInteractionEnabled = NO;
            
            // Restore read receipts display
            for (UIView* view in self.bubbleOverlayContainer.subviews)
            {
                view.alpha = 1;
            }
        }
        else
        {
            self.bubbleOverlayContainer.hidden = YES;
        }
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

- (void)setEditButton:(UIButton *)editButton
{
    objc_setAssociatedObject(self, @selector(editButton), editButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIButton*)editButton
{
    return objc_getAssociatedObject(self, @selector(editButton));
}

- (void)setSelectedReadReceiptsContainer:(MXKReceiptSendersContainer *)readReceiptsContainer
{
    objc_setAssociatedObject(self, @selector(selectedReadReceiptsContainer), readReceiptsContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIButton*)selectedReadReceiptsContainer
{
    return objc_getAssociatedObject(self, @selector(selectedReadReceiptsContainer));
}

- (void)setSelectedReadReceiptsContainerTrailingConstraint:(NSLayoutConstraint *)readReceiptsContainerTrailingConstraint
{
    objc_setAssociatedObject(self, @selector(selectedReadReceiptsContainerTrailingConstraint), readReceiptsContainerTrailingConstraint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIButton*)selectedReadReceiptsContainerTrailingConstraint
{
    return objc_getAssociatedObject(self, @selector(selectedReadReceiptsContainerTrailingConstraint));
}

#pragma mark - User actions

- (IBAction)onEditButtonPressed:(id)sender
{
    if (self.delegate)
    {
        MXEvent *selectedEvent = nil;
        
        // Note edit button tag is equal to the index of the related component.
        NSInteger index = ((UIView*)sender).tag;
        if (index < self.bubbleData.bubbleComponents.count)
        {
            MXKRoomBubbleComponent *component = self.bubbleData.bubbleComponents[index];
            selectedEvent = component.event;
        }
        
        if (selectedEvent)
        {
            [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellVectorEditButtonPressed userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
        }
    }
}

#pragma mark - Internals

- (void)addEditButtonForComponent:(NSUInteger)componentIndex completion:(void (^ __nullable)(BOOL finished))completion
{
    MXKRoomBubbleComponent *component  = self.bubbleData.bubbleComponents[componentIndex];
    
    // Define 'Edit' button frame by overlapping slightly the time label
    // (vertical pos = (component.position.y + 4) instead of (component.position.y + 18))
    UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(0, component.position.y + 4, self.bubbleInfoContainer.frame.size.width + 15 , 44)];
    
    [editButton setTitle:NSLocalizedStringFromTable(@"room_event_action_edit", @"Vector", nil) forState:UIControlStateNormal];
    [editButton setTitle:NSLocalizedStringFromTable(@"room_event_action_edit", @"Vector", nil) forState:UIControlStateSelected];
    [editButton setTitleColor:kVectorColorGree forState:UIControlStateNormal];
    [editButton setTitleColor:kVectorColorGree forState:UIControlStateSelected];
    
    // Align button label on the right border of the bubbleInfoContainer
    editButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    UIEdgeInsets edgeInset = editButton.titleEdgeInsets;
    edgeInset.right = 15;
    editButton.titleEdgeInsets = edgeInset;
    
    editButton.backgroundColor = [UIColor clearColor];
    if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
    {
        editButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    }
    else
    {
        editButton.titleLabel.font = [UIFont systemFontOfSize:15];
    }
    
    editButton.hidden = YES;
    editButton.tag = componentIndex;
    [editButton addTarget:self action:@selector(onEditButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [editButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bubbleInfoContainer addSubview:editButton];
    self.bubbleInfoContainer.userInteractionEnabled = YES;
    
    // Force edit button in full width (to handle auto-layout in case of screen rotation)
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.bubbleInfoContainer
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.bubbleInfoContainer
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:15];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.bubbleInfoContainer
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:component.position.y + 4];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:44];
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, heightConstraint]];
    
    // Store the created button
    self.editButton = editButton;
    
    // Check whether this edit button overlaps a potential receipts container displayed for this component
    if (self.selectedReadReceiptsContainer)
    {
        // Adjust edit button frame to be able to compare it to bubble overlay container (superview of receipts container).
        CGRect frame = CGRectOffset (editButton.frame, self.bubbleInfoContainer.frame.origin.x, self.bubbleInfoContainer.frame.origin.y);
        if (CGRectIntersectsRect(frame, self.selectedReadReceiptsContainer.frame))
        {
            // Retrieve the trailing constraint of the receipts container
            NSArray *constraints = self.bubbleOverlayContainer.constraints;
            for (NSLayoutConstraint *constraint in constraints)
            {
                if (constraint.firstAttribute == NSLayoutAttributeTrailing && constraint.firstItem == self.selectedReadReceiptsContainer)
                {
                    self.selectedReadReceiptsContainerTrailingConstraint = constraint;
                    break;
                }
            }
        }
    }
    
    if (self.selectedReadReceiptsContainerTrailingConstraint)
    {
        // Update layout with animation
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             // Shift the container to left
                             self.selectedReadReceiptsContainerTrailingConstraint.constant -= (self.bubbleInfoContainer.frame.size.width + 6);
                             
                             // Force to render the view
                             [self layoutIfNeeded];
                             
                             editButton.hidden = NO;
                             
                         }
                         completion:^(BOOL finished){
                             
                             if (completion)
                             {
                                 completion(finished);
                             }
                             
                         }];
    }
    else
    {
        editButton.hidden = NO;
        
        if (completion)
        {
            completion(YES);
        }
    }
}

- (void)removeEditButton:(void (^ __nullable)(BOOL finished))completion
{
    if (self.selectedReadReceiptsContainerTrailingConstraint)
    {
        // Update layout with animation
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             
                             [self.editButton removeFromSuperview];
                             
                             self.selectedReadReceiptsContainerTrailingConstraint.constant = -6;
                             
                             // Force to render the view
                             [self layoutIfNeeded];
                         }
                         completion:^(BOOL finished){
                             
                             self.editButton = nil;
                             self.selectedReadReceiptsContainer = nil;
                             self.selectedReadReceiptsContainerTrailingConstraint = nil;
                             
                             if (completion)
                             {
                                 completion(finished);
                             }
                             
                         }];
    }
    else
    {
        [self.editButton removeFromSuperview];
        self.editButton = nil;
        self.selectedReadReceiptsContainer = nil;
        self.selectedReadReceiptsContainerTrailingConstraint = nil;
        
        if (completion)
        {
            completion(YES);
        }
    }
}

@end
