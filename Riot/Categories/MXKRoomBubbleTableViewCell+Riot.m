/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomBubbleTableViewCell+Riot.h"

#import <objc/runtime.h>

#import "RoomBubbleCellData.h"
#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

#define VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X 48
#define VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH 4

NSString *const kMXKRoomBubbleCellRiotEditButtonPressed = @"kMXKRoomBubbleCellRiotEditButtonPressed";
NSString *const kMXKRoomBubbleCellTapOnReceiptsContainer = @"kMXKRoomBubbleCellTapOnReceiptsContainer";
NSString *const kMXKRoomBubbleCellTapOnAddReaction = @"kMXKRoomBubbleCellTapOnAddReaction";
NSString *const kMXKRoomBubbleCellLongPressOnReactionView = @"kMXKRoomBubbleCellLongPressOnReactionView";
NSString *const kMXKRoomBubbleCellKeyVerificationIncomingRequestAcceptPressed = @"kMXKRoomBubbleCellKeyVerificationAcceptPressed";
NSString *const kMXKRoomBubbleCellKeyVerificationIncomingRequestDeclinePressed = @"kMXKRoomBubbleCellKeyVerificationDeclinePressed";

@implementation MXKRoomBubbleTableViewCell (Riot)

- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex
{
    BOOL isFirstDisplayedComponent = (componentIndex == 0);
    BOOL isLastMessageMostRecentComponent = NO;
    
    RoomBubbleCellData *roomBubbleCellData;
    
    if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
    {
        roomBubbleCellData = (RoomBubbleCellData*)bubbleData;
        isFirstDisplayedComponent = (componentIndex == roomBubbleCellData.oldestComponentIndex);
        isLastMessageMostRecentComponent = roomBubbleCellData.containsLastMessage && (componentIndex == roomBubbleCellData.mostRecentComponentIndex);
    }
    
    // Display timestamp on the left for selected component when it cannot overlap other UI elements like user's avatar
    BOOL displayLabelOnLeft = roomBubbleCellData.displayTimestampForSelectedComponentOnLeftWhenPossible
    && !isLastMessageMostRecentComponent
    && (!isFirstDisplayedComponent || roomBubbleCellData.shouldHideSenderInformation);
    
    [self addTimestampLabelForComponent:componentIndex displayOnLeft:displayLabelOnLeft];
}

- (void)addTimestampLabelForComponent:(NSUInteger)componentIndex
                        displayOnLeft:(BOOL)displayLabelOnLeft
{
    MXKRoomBubbleComponent *component;
    
    NSArray *bubbleComponents = bubbleData.bubbleComponents;
    
    if (componentIndex < bubbleComponents.count)
    {
        component = bubbleComponents[componentIndex];
    }
    
    if (component && component.date)
    {
        BOOL isFirstDisplayedComponent = (componentIndex == 0);
        
        RoomBubbleCellData *roomBubbleCellData;
        
        if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
        {
            roomBubbleCellData = (RoomBubbleCellData*)bubbleData;
            isFirstDisplayedComponent = (componentIndex == roomBubbleCellData.oldestComponentIndex);
        }
        
        [self addTimestampLabelForComponentIndex:componentIndex
                       isFirstDisplayedComponent:isFirstDisplayedComponent
                                         viewTag:componentIndex
                                   displayOnLeft:displayLabelOnLeft];
    }
}

- (void)addTimestampLabelForComponentIndex:(NSInteger)componentIndex
                 isFirstDisplayedComponent:(BOOL)isFirstDisplayedComponent
                                   viewTag:(NSInteger)viewTag
                             displayOnLeft:(BOOL)displayOnLeft
{
    if (!self.bubbleInfoContainer)
    {
        MXLogDebug(@"[MXKRoomBubbleTableViewCell+Riot] bubbleInfoContainer property is missing for cell class: %@", NSStringFromClass(self.class));
        return;
    }
    
    NSArray *bubbleComponents = bubbleData.bubbleComponents;
    MXKRoomBubbleComponent *component = bubbleComponents[componentIndex];
    
    self.bubbleInfoContainer.hidden = NO;
    
    CGFloat timeLabelPosX;
    CGFloat timeLabelPosY;
    CGFloat timeLabelHeight = PlainRoomCellLayoutConstants.timestampLabelHeight;
    CGFloat timeLabelWidth;
    NSTextAlignment timeLabelTextAlignment;
    
    CGRect componentFrame = [self componentFrameInContentViewForIndex:componentIndex];
    
    if (displayOnLeft)
    {
        CGFloat leftMargin = 10.0;
        CGFloat rightMargin = (self.contentView.frame.size.width - (self.bubbleInfoContainer.frame.origin.x + self.bubbleInfoContainer.frame.size.width));
        
        timeLabelPosX = 0;
        
        if (CGRectEqualToRect(componentFrame, CGRectNull) == false)
        {
            timeLabelPosY = componentFrame.origin.y - self.bubbleInfoContainerTopConstraint.constant;
        }
        else
        {
            timeLabelPosY = component.position.y + self.msgTextViewTopConstraint.constant - self.bubbleInfoContainerTopConstraint.constant;
        }
        
        timeLabelWidth = self.contentView.frame.size.width - leftMargin - rightMargin;
        timeLabelTextAlignment = NSTextAlignmentLeft;
    }
    else
    {
        timeLabelPosX = self.bubbleInfoContainer.frame.size.width - PlainRoomCellLayoutConstants.timestampLabelWidth;
        
        if (isFirstDisplayedComponent)
        {
            timeLabelPosY = 0;
        }
        else if (CGRectEqualToRect(componentFrame, CGRectNull) == false)
        {
            timeLabelPosY = componentFrame.origin.y - self.bubbleInfoContainerTopConstraint.constant - timeLabelHeight;
        }
        else
        {
            timeLabelPosY = component.position.y + self.msgTextViewTopConstraint.constant - timeLabelHeight - self.bubbleInfoContainerTopConstraint.constant;
        }
        
        timeLabelWidth = PlainRoomCellLayoutConstants.timestampLabelWidth;
        timeLabelTextAlignment = NSTextAlignmentRight;
    }
    
    timeLabelPosY = MAX(0.0, timeLabelPosY);
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelPosX, timeLabelPosY, timeLabelWidth, timeLabelHeight)];
    
    timeLabel.text = [bubbleData.eventFormatter timeStringFromDate:component.date];
    timeLabel.textAlignment = timeLabelTextAlignment;
    timeLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    timeLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightLight];
    timeLabel.adjustsFontSizeToFitWidth = YES;
    
    timeLabel.tag = viewTag;
    
    [timeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    timeLabel.accessibilityIdentifier = @"timestampLabel";
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
                                                                        constant:timeLabelWidth];
    
    
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:timeLabel
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:timeLabelHeight];
    
    // Available on iOS 8 and later
    [NSLayoutConstraint activateConstraints:@[rightConstraint, topConstraint, widthConstraint, heightConstraint]];
}

- (void)selectComponent:(NSUInteger)componentIndex
{
    [self selectComponent:componentIndex showEditButton:NO showTimestamp:YES];
}

- (void)selectComponent:(NSUInteger)componentIndex showEditButton:(BOOL)showEditButton showTimestamp:(BOOL)showTimestamp
{
    if (componentIndex < bubbleData.bubbleComponents.count)
    {
        if (showTimestamp)
        {
            // Add time label
            [self addTimestampLabelForComponent:componentIndex];
        }
        
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
        for (UIView* view in self.tmpSubviews)
        {
            // Note read receipt container tag is equal to the index of the related component.
            if (view.tag != componentIndex)
            {
                view.alpha = 0.2;
            }
        }
        
        if (showEditButton)
        {
            // Add the edit button
            [self addEditButtonForComponent:componentIndex completion:nil];
        }
    }
}

- (void)markComponent:(NSUInteger)componentIndex
{
    NSArray *bubbleComponents = bubbleData.bubbleComponents;
    
    if (componentIndex < bubbleComponents.count)
    {
        CGRect componentFrame = [self componentFrameInContentViewForIndex:componentIndex];
        if (CGRectIsEmpty(componentFrame))
        {
            return;
        }

        CGRect markerFrame = CGRectMake(VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_X,
                                        CGRectGetMinY(componentFrame),
                                        VECTOR_ROOMBUBBLETABLEVIEWCELL_MARK_WIDTH,
                                        CGRectGetHeight(componentFrame));

        UIView *markerView = [[UIView alloc] initWithFrame:markerFrame];
        markerView.backgroundColor = ThemeService.shared.theme.tintColor;

        [markerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        markerView.accessibilityIdentifier = @"markerView";
        [self.contentView addSubview:markerView];

        // Define the marker constraints
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.contentView
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:CGRectGetMinX(markerFrame)];
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.contentView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:CGRectGetMinY(markerFrame)];
        NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:CGRectGetWidth(markerFrame)];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:markerView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:CGRectGetHeight(markerFrame)];

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
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bubbleInfoContainer.frame.size.width, PlainRoomCellLayoutConstants.timestampLabelHeight)];
        
        timeLabel.text = [bubbleData.eventFormatter dateStringFromDate:date withTime:NO];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
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
        timeLabel.accessibilityIdentifier = @"dateLabel";
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
                                                                             constant:PlainRoomCellLayoutConstants.timestampLabelHeight];
        
        // Available on iOS 8 and later
        [NSLayoutConstraint activateConstraints:@[rightConstraint, topConstraint, widthConstraint, heightConstraint]];
    }
}

- (void)setBlurred:(BOOL)blurred
{
    objc_setAssociatedObject(self, @selector(blurred), @(blurred), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (blurred)
    {
        self.bubbleOverlayContainer.hidden = NO;
        self.bubbleOverlayContainer.backgroundColor = ThemeService.shared.theme.backgroundColor;
        self.bubbleOverlayContainer.alpha = 0.8;
        self.bubbleOverlayContainer.userInteractionEnabled = YES;
        
        // Blur subviews if any
        for (UIView* view in self.bubbleOverlayContainer.subviews)
        {
            view.alpha = 0.2;
        }
        
        // Move this view in front
        [self.bubbleOverlayContainer.superview bringSubviewToFront:self.bubbleOverlayContainer];
    }
    else
    {
        if (self.bubbleOverlayContainer.subviews.count)
        {
            // Keep this overlay visible, adjust background color
            self.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
            self.bubbleOverlayContainer.alpha = 1;
            self.bubbleOverlayContainer.userInteractionEnabled = NO;
            
            // Restore subviews display
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

- (void)setMessageStatusViews:(NSArray *)arrayOfViews
{
    objc_setAssociatedObject(self, @selector(messageStatusViews), arrayOfViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSArray *)messageStatusViews
{
    return objc_getAssociatedObject(self, @selector(messageStatusViews));
}

- (void)updateUserNameColor
{
    static UserNameColorGenerator *userNameColorGenerator;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userNameColorGenerator = [UserNameColorGenerator new];
    });
    
    id<Theme> theme = ThemeService.shared.theme;
    
    userNameColorGenerator.defaultColor = theme.textPrimaryColor;
    userNameColorGenerator.userNameColors = theme.userNameColors;
    
    NSString *senderId = self.bubbleData.senderId;
    
    if (senderId)
    {
        self.userNameLabel.textColor = [userNameColorGenerator colorFrom:senderId];
    }
    else
    {
        self.userNameLabel.textColor = userNameColorGenerator.defaultColor;
    }
}

- (CGRect)componentFrameInTableViewForIndex:(NSInteger)componentIndex
{
    CGRect componentFrameInContentView = [self componentFrameInContentViewForIndex:componentIndex];
    return [self.contentView convertRect:componentFrameInContentView toView:self.superview];
}

- (CGRect)surroundingFrameInTableViewForComponentIndex:(NSInteger)componentIndex
{
    CGRect surroundingFrame;
    
    CGRect componentFrameInContentView = [self componentFrameInContentViewForIndex:componentIndex];
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = self;
    MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
    
    NSInteger firstVisibleComponentIndex = NSNotFound;
    NSInteger lastMostRecentComponentIndex = NSNotFound;
    
    if ([bubbleCellData isKindOfClass:[RoomBubbleCellData class]])
    {
        RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)bubbleCellData;
        firstVisibleComponentIndex = [roomBubbleCellData firstVisibleComponentIndex];
        
        if (roomBubbleCellData.containsLastMessage
            && roomBubbleCellData.mostRecentComponentIndex != NSNotFound
            && roomBubbleCellData.firstVisibleComponentIndex != roomBubbleCellData.mostRecentComponentIndex
            && componentIndex == roomBubbleCellData.mostRecentComponentIndex)
        {
            lastMostRecentComponentIndex = roomBubbleCellData.mostRecentComponentIndex;
        }
    }
    
    // Do not overlap timestamp for last message
    if (lastMostRecentComponentIndex != NSNotFound)
    {
        CGFloat componentBottomY = componentFrameInContentView.origin.y + componentFrameInContentView.size.height;
        
        CGFloat x = 0;
        CGFloat y = componentFrameInContentView.origin.y - PlainRoomCellLayoutConstants.timestampLabelHeight;
        CGFloat width = roomBubbleTableViewCell.contentView.frame.size.width;
        CGFloat height = componentBottomY - y;
        
        surroundingFrame = CGRectMake(x, y, width, height);
    } // Do not overlap user name label for first visible component
    else if (!CGRectEqualToRect(componentFrameInContentView, CGRectNull)
        && firstVisibleComponentIndex != NSNotFound
        && componentIndex <= firstVisibleComponentIndex
        && roomBubbleTableViewCell.userNameLabel
        && roomBubbleTableViewCell.userNameLabel.isHidden == NO)
    {
        CGFloat componentBottomY = componentFrameInContentView.origin.y + componentFrameInContentView.size.height;
        
        CGFloat x = 0;
        CGFloat y = roomBubbleTableViewCell.userNameLabel.frame.origin.y;
        CGFloat width = roomBubbleTableViewCell.contentView.frame.size.width;
        CGFloat height = componentBottomY - y;
        
        surroundingFrame = CGRectMake(x, y, width, height);
    }
    else
    {
        surroundingFrame = componentFrameInContentView;
    }    
    
    return [self.contentView convertRect:surroundingFrame toView:self.superview];
}

- (CGRect)componentFrameInContentViewForIndex:(NSInteger)componentIndex
{
    MXKRoomBubbleTableViewCell *roomBubbleTableViewCell = self;
    MXKRoomBubbleCellData *bubbleCellData = roomBubbleTableViewCell.bubbleData;
    MXKRoomBubbleComponent *selectedComponent;
    
    if (bubbleCellData.bubbleComponents.count > componentIndex)
    {
        selectedComponent = bubbleCellData.bubbleComponents[componentIndex];
    }
    
    if (!selectedComponent)
    {
        return CGRectNull;
    }
    
    CGFloat selectedComponenContentViewYOffset = 0;
    CGFloat selectedComponentPositionY = 0;
    CGFloat selectedComponentHeight = 0;
    
    CGRect componentFrame = CGRectNull;
    
    if (roomBubbleTableViewCell.attachmentView)
    {
        CGRect attachamentViewFrame = roomBubbleTableViewCell.attachmentView.frame;
        
        selectedComponenContentViewYOffset = attachamentViewFrame.origin.y;
        selectedComponentHeight = attachamentViewFrame.size.height;
    }
    else if (roomBubbleTableViewCell.messageTextView)
    {
        // Force the textView used underneath to layout its frame properly
        [roomBubbleTableViewCell setNeedsLayout];
        [roomBubbleTableViewCell layoutIfNeeded];
                
        // Compute the height
        CGFloat textMessageHeight = 0;
        if ([bubbleCellData isKindOfClass:[RoomBubbleCellData class]])
        {
            RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)bubbleCellData;
            
            if (!roomBubbleCellData.attachment && selectedComponent.attributedTextMessage)
            {
                // Get the width of messageTextView to compute the needed height
                CGFloat maxTextWidth = CGRectGetWidth(roomBubbleTableViewCell.messageTextView.bounds);
                
                // Compute text message height
                textMessageHeight = [roomBubbleCellData rawTextHeight:selectedComponent.attributedTextMessage withMaxWidth:maxTextWidth];
            }
        }
                
        // Get the messageText frame in the cell content view (as the messageTextView may be inside a stackView and not directly a child of the tableViewCell)
        UITextView *messageTextView = roomBubbleTableViewCell.messageTextView;
        CGRect messageTextViewFrame = [messageTextView convertRect:messageTextView.bounds toView:roomBubbleTableViewCell.contentView];

        if (textMessageHeight > 0)
        {
            selectedComponentHeight = textMessageHeight;
        }
        else
        {
            // if we don't have a height, use the messageTextView height without the text container vertical insets to stay aligned with the text.
            selectedComponentHeight = CGRectGetHeight(messageTextViewFrame) - messageTextView.textContainerInset.top - messageTextView.textContainerInset.bottom;
        }
        
        // Get the vertical position of the messageTextView relative to the contentView
        selectedComponenContentViewYOffset = CGRectGetMinY(messageTextViewFrame);

        // Get the position of the component inside the messageTextView
        selectedComponentPositionY = selectedComponent.position.y;
    }
        
    if (roomBubbleTableViewCell.attachmentView || roomBubbleTableViewCell.messageTextView)
    {
        CGFloat x = 0;
        CGFloat y = selectedComponenContentViewYOffset + selectedComponentPositionY;
        CGFloat width = roomBubbleTableViewCell.contentView.frame.size.width;
        
        componentFrame = CGRectMake(x, y, width, selectedComponentHeight);
    }
    else
    {
        componentFrame = roomBubbleTableViewCell.bounds;
    }
    
    return componentFrame;
}

+ (CGFloat)attachmentBubbleCellHeightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    MXKRoomBubbleTableViewCell* cell = [self cellWithOriginalXib];
    CGFloat rowHeight = 0;
    
    RoomBubbleCellData *bubbleData;
    
    if ([cellData isKindOfClass:[RoomBubbleCellData class]])
    {
        bubbleData = (RoomBubbleCellData*)cellData;
    }
    
    if (bubbleData && cell.attachmentView && bubbleData.isAttachmentWithThumbnail)
    {
        // retrieve the suggested image view height
        rowHeight = bubbleData.contentSize.height;
        
        // Check here the minimum height defined in cell view for text message
        if (cell.attachViewMinHeightConstraint && rowHeight < cell.attachViewMinHeightConstraint.constant)
        {
            rowHeight = cell.attachViewMinHeightConstraint.constant;
        }
        
        // Finalize the row height by adding the vertical constraints.
        
        rowHeight += cell.attachViewTopConstraint.constant;
        
        CGFloat additionalHeight = bubbleData.additionalContentHeight;
        
        if (additionalHeight)
        {
            rowHeight += additionalHeight;
        }
        else
        {
            rowHeight += cell.attachViewBottomConstraint.constant;
        }
    }
    
    return rowHeight;
}

- (void)updateTickViewWithFailedEventIds:(NSSet *)failedEventIds
{
    for (UIView *tickView in self.messageStatusViews)
    {
        [tickView removeFromSuperview];
    }
    self.messageStatusViews = nil;
    
    NSMutableArray *statusViews = [NSMutableArray new];
    UIView *tickView = nil;

    if ([bubbleData isKindOfClass:RoomBubbleCellData.class]
        && ((RoomBubbleCellData*)bubbleData).componentIndexOfSentMessageTick >= 0)
    {
        UIImage *image = AssetImages.sentMessageTick.image;
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        tickView = [[UIImageView alloc] initWithImage:image];
        tickView.tintColor = ThemeService.shared.theme.textTertiaryColor;
        [statusViews addObject:tickView];
        [self addTickView:tickView atIndex:((RoomBubbleCellData*)bubbleData).componentIndexOfSentMessageTick];
    }
    
    NSInteger index = bubbleData.bubbleComponents.count;
    while (index--)
    {
        MXKRoomBubbleComponent *component = bubbleData.bubbleComponents[index];
        NSArray<MXReceiptData*> *receipts = bubbleData.readReceipts[component.event.eventId];
        if (receipts.count == 0) {
            if (component.event.sentState == MXEventSentStateUploading
                || component.event.sentState == MXEventSentStateEncrypting
                || component.event.sentState == MXEventSentStatePreparing
                || component.event.sentState == MXEventSentStateSending)
            {
                if ([failedEventIds containsObject:component.event.eventId] || (bubbleData.attachment && component.event.sentState != MXEventSentStateSending))
                {
                    UIView *progressContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
                    CircleProgressView *progressView = [[CircleProgressView alloc] initWithFrame:CGRectMake(24, 24, 16, 16)];
                    progressView.lineColor = ThemeService.shared.theme.textTertiaryColor;
                    [progressContentView addSubview:progressView];
                    self.progressChartView = progressView;

                    tickView = progressContentView;

                    [progressView startAnimating];
                    
                    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onProgressLongPressGesture:)];
                    [tickView addGestureRecognizer:longPress];
                }
                else
                {
                    UIImage *image = AssetImages.sendingMessageTick.image;
                    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    tickView = [[UIImageView alloc] initWithImage:image];
                    tickView.tintColor = ThemeService.shared.theme.textTertiaryColor;
                }

                [statusViews addObject:tickView];
                [self addTickView:tickView atIndex:index];
            }
        }
        
        if (component.event.sentState == MXEventSentStateFailed)
        {
            tickView = [[UIImageView alloc] initWithImage:AssetImages.errorMessageTick.image];
            [statusViews addObject:tickView];
            [self addTickView:tickView atIndex:index];
        }
    }
    
    
    if (statusViews.count)
    {
        self.messageStatusViews = statusViews;
    }
}

#pragma mark - User actions

- (IBAction)onEditButtonPressed:(id)sender
{
    if (self.delegate)
    {
        MXEvent *selectedEvent = nil;
        
        // Note edit button tag is equal to the index of the related component.
        NSInteger index = ((UIView*)sender).tag;
        NSArray *bubbleComponents = bubbleData.bubbleComponents;
        
        if (index < bubbleComponents.count)
        {
            MXKRoomBubbleComponent *component = bubbleComponents[index];
            selectedEvent = component.event;
        }
        
        if (selectedEvent)
        {
            [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellRiotEditButtonPressed userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
        }
    }
}

- (IBAction)onReceiptContainerTap:(UITapGestureRecognizer *)sender
{
    if (self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellTapOnReceiptsContainer userInfo:@{kMXKRoomBubbleCellReceiptsContainerKey : sender.view}];
    }
}

#pragma mark - Internals

- (void)addTickView:(UIView *)tickView atIndex:(NSInteger)index
{
    CGRect componentFrame = [self componentFrameInContentViewForIndex:index];
    tickView.frame = CGRectMake(self.contentView.bounds.size.width - tickView.frame.size.width - 2 * PlainRoomCellLayoutConstants.readReceiptsViewRightMargin, CGRectGetMaxY(componentFrame) - tickView.frame.size.height, tickView.frame.size.width, tickView.frame.size.height);

    [self.contentView addSubview:tickView];
}

- (void)addEditButtonForComponent:(NSUInteger)componentIndex completion:(void (^ __nullable)(BOOL finished))completion
{
    MXKRoomBubbleComponent *component  = bubbleData.bubbleComponents[componentIndex];
    
    // Check whether this is the first displayed component.
    BOOL isFirstDisplayedComponent = (componentIndex == 0);
    if ([bubbleData isKindOfClass:RoomBubbleCellData.class])
    {
        isFirstDisplayedComponent = (componentIndex == ((RoomBubbleCellData*)bubbleData).oldestComponentIndex);
    }
    
    // Define 'Edit' button frame
    UIImage *editIcon = AssetImages.editIcon.image;
    CGFloat editBtnPosX = self.bubbleInfoContainer.frame.size.width - PlainRoomCellLayoutConstants.timestampLabelWidth - 22 - editIcon.size.width / 2;
    CGFloat editBtnPosY = isFirstDisplayedComponent ? -13 : component.position.y + self.msgTextViewTopConstraint.constant - self.bubbleInfoContainerTopConstraint.constant - 13;
    UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(editBtnPosX, editBtnPosY, 44, 44)];
    
    [editButton setImage:editIcon forState:UIControlStateNormal];
    [editButton setImage:editIcon forState:UIControlStateSelected];
    
    editButton.tag = componentIndex;
    [editButton addTarget:self action:@selector(onEditButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [editButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    editButton.accessibilityIdentifier = @"editButton";
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

- (IBAction)onProgressLongPressGesture:(UILongPressGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan && self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kMXKRoomBubbleCellLongPressOnProgressView userInfo:nil];
    }
}

@end
