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

#define VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH 39

#define VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X 48
#define VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH 4

NSString *const kMXKRoomBubbleCellVectorEditButtonPressed = @"kMXKRoomBubbleCellVectorEditButtonPressed";

@implementation MXKRoomBubbleTableViewCell (Vector)

- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex
{
    self.bubbleInfoContainer.hidden = NO;
    
    MXKRoomBubbleComponent *component;
    if (componentIndex < bubbleData.bubbleComponents.count)
    {
        component  = bubbleData.bubbleComponents[componentIndex];
    }
    
    if (component && component.date)
    {
        CGFloat timeLabelPosX = self.bubbleInfoContainer.frame.size.width - VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH;
        CGFloat timeLabelPosY = componentIndex ? component.position.y + self.msgTextViewTopConstraint.constant - self.bubbleInfoContainerTopConstraint.constant: 0;
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelPosX, timeLabelPosY, VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH , 18)];
        
        timeLabel.text = [bubbleData.eventFormatter timeStringFromDate:component.date];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.textColor = kVectorTextColorGray;
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
        {
             timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        }
        else
        {
             timeLabel.font = [UIFont systemFontOfSize:12];
        }
        timeLabel.adjustsFontSizeToFitWidth = YES;

        timeLabel.tag = componentIndex;
        
        [timeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bubbleInfoContainer addSubview:timeLabel];
        
        // Define timeLabel constraints (to handle auto-layout in case of screen rotation)
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.bubbleInfoContainer
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.bubbleInfoContainer
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:timeLabelPosY];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:18];
        
        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[rightConstraint, topConstraint, widthConstraint, heightConstraint]];
    }
}

- (void)selectComponent:(NSUInteger)componentIndex
{
    if (componentIndex < bubbleData.bubbleComponents.count)
    {
        // Add time label
        [self addTimestampLabelForComponent:componentIndex];
        
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
        }
        
        // Add the edit button
        [self addEditButtonForComponent:componentIndex completion:nil];
    }
}

- (void)markComponent:(NSUInteger)componentIndex
{
    if (componentIndex < bubbleData.bubbleComponents.count)
    {
        MXKRoomBubbleComponent *component = bubbleData.bubbleComponents[componentIndex];

        // Define the marker frame
        CGFloat markPosY = component.position.y + self.msgTextViewTopConstraint.constant;

        CGFloat markHeight;
        if (componentIndex == bubbleData.bubbleComponents.count - 1)
        {
            // There is no component after this component in the cell,
            // use the rest of the cell height
            markHeight = self.contentView.frame.size.height - markPosY;
        }
        else
        {
            // Stop the marker height to the top of the next component in the cell
            MXKRoomBubbleComponent *nextComponent  = bubbleData.bubbleComponents[componentIndex + 1];
            markHeight = nextComponent.position.y - component.position.y;
        }

        UIView *markerView = [[UIView alloc] initWithFrame:CGRectMake(VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X,
                                                                markPosY,
                                                                VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH,
                                                                markHeight)];
        markerView.backgroundColor = kVectorColorGreen;

        [markerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addSubview:markerView];

        // Define the marker constraints
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.contentView
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.contentView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:markPosY];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:markHeight];

        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[leftConstraint, topConstraint, widthConstraint, heightConstraint]];
        
        // Store the created button
        self.markerView = markerView;
    }
}

- (void)addDateLabel
{
    self.bubbleInfoContainer.hidden = NO;
    
    NSDate *date = bubbleData.date;
    if (date)
    {
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bubbleInfoContainer.frame.size.width , 18)];
        
        timeLabel.text = [bubbleData.eventFormatter dateStringFromDate:date withTime:NO];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.textColor = kVectorTextColorGray;
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)])
        {
            timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
        }
        else
        {
            timeLabel.font = [UIFont systemFontOfSize:12];
        }
        timeLabel.adjustsFontSizeToFitWidth = YES;
        
        [timeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bubbleInfoContainer addSubview:timeLabel];
        
        // Define timeLabel constraints (to handle auto-layout in case of screen rotation)
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.bubbleInfoContainer
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.bubbleInfoContainer
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:0];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.bubbleInfoContainer
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:0];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:18];
        
        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[rightConstraint, topConstraint, widthConstraint, heightConstraint]];
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

- (void)setMarkerView:(UIView *)markerView
{
    objc_setAssociatedObject(self, @selector(markerView), markerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIView *)markerView
{
    return objc_getAssociatedObject(self, @selector(markerView));
}

#pragma mark - User actions

- (IBAction)onEditButtonPressed:(id)sender
{
    if (self.delegate)
    {
        MXEvent *selectedEvent = nil;
        
        // Note edit button tag is equal to the index of the related component.
        NSInteger index = ((UIView*)sender).tag;
        if (index < bubbleData.bubbleComponents.count)
        {
            MXKRoomBubbleComponent *component = bubbleData.bubbleComponents[index];
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
    MXKRoomBubbleComponent *component  = bubbleData.bubbleComponents[componentIndex];
    
    // Define 'Edit' button frame
    UIImage *editIcon = [UIImage imageNamed:@"edit_icon"];
    CGFloat editBtnPosX = self.bubbleInfoContainer.frame.size.width - VECTOR_ROOMBUBBLETABLEVIEWCELL_TIMELABEL_WIDTH - 22 - editIcon.size.width / 2;
    CGFloat editBtnPosY = componentIndex ? component.position.y + self.msgTextViewTopConstraint.constant - self.bubbleInfoContainerTopConstraint.constant - 13 : -13;
    UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(editBtnPosX, editBtnPosY, 44, 44)];
    
    [editButton setImage:editIcon forState:UIControlStateNormal];
    [editButton setImage:editIcon forState:UIControlStateSelected];
    
    editButton.tag = componentIndex;
    [editButton addTarget:self action:@selector(onEditButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [editButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.bubbleInfoContainer addSubview:editButton];
    self.bubbleInfoContainer.userInteractionEnabled = YES;
    
    // Define edit button constraints
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.bubbleInfoContainer
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:editBtnPosX];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.bubbleInfoContainer
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:editBtnPosY];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:44];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:editButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:44];
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[leftConstraint, topConstraint, widthConstraint, heightConstraint]];
    
    // Store the created button
    self.editButton = editButton;
}

@end
