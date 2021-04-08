/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "RoomDataSource.h"

#import "EventFormatter.h"
#import "RoomBubbleCellData.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"
#import "AvatarGenerator.h"
#import "ThemeService.h"
#import "Riot-Swift.h"

#import "MXRoom+Riot.h"

const CGFloat kTypingCellHeight = 24;

@interface RoomDataSource() <BubbleReactionsViewModelDelegate>
{
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

// Observe key verification request changes
@property (nonatomic, weak) id keyVerificationRequestDidChangeNotificationObserver;

// Observe key verification transaction changes
@property (nonatomic, weak) id keyVerificationTransactionDidChangeNotificationObserver;

// Timer used to debounce cells refresh
@property (nonatomic, strong) NSTimer *refreshCellsTimer;

@property (nonatomic, readonly) id<RoomDataSourceDelegate> roomDataSourceDelegate;

@property(nonatomic, readwrite) RoomEncryptionTrustLevel encryptionTrustLevel;

@property (nonatomic, strong) NSMutableSet *failedEventIds;

@property (nonatomic) RoomBubbleCellData *roomCreationCellData;

@property (nonatomic) BOOL showRoomCreationCell;

@property (nonatomic) NSInteger typingCellIndex;

@end

@implementation RoomDataSource

- (instancetype)initWithRoomId:(NSString *)roomId andMatrixSession:(MXSession *)matrixSession
{
    self = [super initWithRoomId:roomId andMatrixSession:matrixSession];
    if (self)
    {
        // Replace default Cell data class
        [self registerCellDataClass:RoomBubbleCellData.class forCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
        
        // Replace the event formatter
        [self updateEventFormatter];

        // Handle timestamp and read receips display at Vector app level (see [tableView: cellForRowAtIndexPath:])
        self.useCustomDateTimeLabel = YES;
        self.useCustomReceipts = YES;
        self.useCustomUnsentButton = YES;
        
        // Set bubble pagination
        self.bubblesPagination = MXKRoomDataSourceBubblesPaginationPerDay;
        
        self.markTimelineInitialEvent = NO;
        
        self.showBubbleDateTimeOnSelection = YES;
        self.showReactions = YES;
        
        // Observe user interface theme change.
        kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // Force room data reload.
            [self updateEventFormatter];
            [self reload];
            
        }];
        
        [self registerKeyVerificationRequestNotification];
        [self registerKeyVerificationTransactionNotification];
        [self registerTrustLevelDidChangeNotifications];
        
        self.encryptionTrustLevel = RoomEncryptionTrustLevelUnknown;
    }
    return self;
}

- (void)finalizeInitialization
{
    [super finalizeInitialization];

    // Sadly, we need to make sure we have fetched all room members from the HS
    // to be able to display read receipts
    if (![self.mxSession.store hasLoadedAllRoomMembersForRoom:self.roomId])
    {
        [self.room members:^(MXRoomMembers *roomMembers) {
            NSLog(@"[MXKRoomDataSource] finalizeRoomDataSource: All room members have been retrieved");

            // Refresh the full table
            [self.delegate dataSource:self didCellChange:nil];

        } failure:^(NSError *error) {
            NSLog(@"[MXKRoomDataSource] finalizeRoomDataSource: Cannot retrieve all room members");
        }];
    }

    if (self.room.summary.isEncrypted)
    {
        // Make sure we have the trust shield value
        [self.room.summary enableTrustTracking:YES];
        [self fetchEncryptionTrustedLevel];
    }
}

- (id<RoomDataSourceDelegate>)roomDataSourceDelegate
{
    if (!self.delegate || ![self.delegate conformsToProtocol:@protocol(RoomDataSourceDelegate)])
    {
        return nil;
    }
    
    return ((id<RoomDataSourceDelegate>)(self.delegate));
}

- (void)updateEventFormatter
{
    // Set a new event formatter
    // TODO: We should use the same EventFormatter instance for all the rooms of a mxSession.
    self.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:self.mxSession];
    self.eventFormatter.treatMatrixUserIdAsLink = YES;
    self.eventFormatter.treatMatrixRoomIdAsLink = YES;
    self.eventFormatter.treatMatrixRoomAliasAsLink = YES;
    self.eventFormatter.treatMatrixGroupIdAsLink = YES;
    
    // Apply the event types filter to display only the wanted event types.
    self.eventFormatter.eventTypesFilterForMessages = [MXKAppSettings standardAppSettings].eventsFilterForMessages;
}

- (void)destroy
{
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    if (self.keyVerificationRequestDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.keyVerificationRequestDidChangeNotificationObserver];
    }
    
    if (self.keyVerificationTransactionDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self.keyVerificationTransactionDidChangeNotificationObserver];
    }
    
    [super destroy];
}

- (void)updateCellDataReactions:(id<MXKRoomBubbleCellDataStoring>)cellData forEventId:(NSString*)eventId
{
    [super updateCellDataReactions:cellData forEventId:eventId];

    [self setNeedsUpdateAdditionalContentHeightForCellData:cellData];
}

- (void)updateCellData:(MXKRoomBubbleCellData*)cellData withReadReceipts:(NSArray<MXReceiptData*>*)readReceipts forEventId:(NSString*)eventId
{
    [super updateCellData:cellData withReadReceipts:readReceipts forEventId:eventId];
    
    [self setNeedsUpdateAdditionalContentHeightForCellData:cellData];
}

- (CGFloat)cellHeightAtIndex:(NSInteger)index withMaximumWidth:(CGFloat)maxWidth
{
    if (index == self.typingCellIndex)
    {
        return kTypingCellHeight;
    }
    
    return [super cellHeightAtIndex:index withMaximumWidth:maxWidth];
}

- (void)setNeedsUpdateAdditionalContentHeightForCellData:(id<MXKRoomBubbleCellDataStoring>)cellData
{
    RoomBubbleCellData *roomBubbleCellData;
    
    if ([cellData isKindOfClass:[RoomBubbleCellData class]])
    {
        roomBubbleCellData = (RoomBubbleCellData*)cellData;
        [roomBubbleCellData setNeedsUpdateAdditionalContentHeight];
    }
}

#pragma mark Encryption trust level

- (void)registerTrustLevelDidChangeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomSummaryDidChange:) name:kMXRoomSummaryDidChangeNotification object:self.room.summary];
}


- (void)roomSummaryDidChange:(NSNotification*)notification
{
    if (!self.room.summary.isEncrypted)
    {
        return;
    }
    
    [self fetchEncryptionTrustedLevel];
    [self enableRoomCreationIntroCellDisplayIfNeeded];
}

- (void)fetchEncryptionTrustedLevel
{
    self.encryptionTrustLevel = self.room.summary.roomEncryptionTrustLevel;
    [self.roomDataSourceDelegate roomDataSource:self didUpdateEncryptionTrustLevel:self.encryptionTrustLevel];
}

- (void)roomDidSet
{
    [self enableRoomCreationIntroCellDisplayIfNeeded];
}

#pragma  mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [super tableView:tableView numberOfRowsInSection:section];
    
    if (count)
    {
        // Enable the containsLastMessage flag for the cell data which contains the last message.
        @synchronized(bubbles)
        {
            [self insertRoomCreationIntroCellDataIfNeeded];
            
            // Reset first all cell data
            for (RoomBubbleCellData *cellData in bubbles)
            {
                cellData.containsLastMessage = NO;
                cellData.componentIndexOfSentMessageTick = -1;
            }

            // The cell containing the last message is the last one with an actual display.
            NSInteger index = bubbles.count;
            while (index--)
            {
                RoomBubbleCellData *cellData = bubbles[index];
                if (cellData.attributedTextMessage)
                {
                    cellData.containsLastMessage = YES;
                    break;
                }
            }
            
            [self updateStatusInfo];
        }
        
        if (!self.currentTypingUsers)
        {
            self.typingCellIndex = -1;
            
            //  we may have changed the number of bubbles in this block, consider that change
            return bubbles.count;
        }
        
        self.typingCellIndex = bubbles.count;
        return bubbles.count + 1;
    }
    
    if (!self.currentTypingUsers)
    {
        self.typingCellIndex = -1;

        //  leave it as is, if coming as 0 from super
        return count;
    }
    
    self.typingCellIndex = count;
    return count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.typingCellIndex)
    {
        RoomTypingBubbleCell *cell = [tableView dequeueReusableCellWithIdentifier:RoomTypingBubbleCell.defaultReuseIdentifier forIndexPath:indexPath];
        [cell updateWithTheme:ThemeService.shared.theme];
        [cell updateTypingUsers:_currentTypingUsers mediaManager:self.mxSession.mediaManager];
        return cell;
    }
    
    // Do cell data customization that needs to be done before [MXKRoomBubbleTableViewCell render]
    RoomBubbleCellData *roomBubbleCellData = [self cellDataAtIndex:indexPath.row];

    // Use the Riot style placeholder
    if (!roomBubbleCellData.senderAvatarPlaceholder)
    {
        roomBubbleCellData.senderAvatarPlaceholder = [AvatarGenerator generateAvatarForMatrixItem:roomBubbleCellData.senderId withDisplayName:roomBubbleCellData.senderDisplayName];
    }
    
    [self updateKeyVerificationIfNeededForRoomBubbleCellData:roomBubbleCellData];

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        [self resetAccessibilityForCell:bubbleCell];

        RoomBubbleCellData *cellData = (RoomBubbleCellData*)bubbleCell.bubbleData;
        NSArray *bubbleComponents = cellData.bubbleComponents;

        BOOL isCollapsableCellCollapsed = cellData.collapsable && cellData.collapsed;
        
        // Display timestamp of the last message
        if (cellData.containsLastMessage && !isCollapsableCellCollapsed)
        {
            [bubbleCell addTimestampLabelForComponent:cellData.mostRecentComponentIndex];
        }
        
        NSMutableArray *temporaryViews = [NSMutableArray new];
        
        // Handle read receipts and read marker display.
        // Ignore the read receipts on the bubble without actual display.
        // Ignore the read receipts on collapsed bubbles
        if ((((self.showBubbleReceipts && cellData.readReceipts.count) || cellData.reactions.count) && !isCollapsableCellCollapsed) || self.showReadMarker)
        {
            // Read receipts container are inserted here on the right side into the content view.
            // Some vertical whitespaces are added in message text view (see RoomBubbleCellData class) to insert correctly multiple receipts.
            
            NSInteger index = 0;
            
            for (MXKRoomBubbleComponent *component in bubbleComponents)
            {
                NSString *componentEventId = component.event.eventId;
                
                if (component.event.sentState != MXEventSentStateFailed)
                {
                    CGFloat bottomPositionY;
                    
                    CGRect bubbleComponentFrame = [bubbleCell componentFrameInContentViewForIndex:index];
                    
                    if (CGRectEqualToRect(bubbleComponentFrame, CGRectNull) == NO)
                    {
                        bottomPositionY = bubbleComponentFrame.origin.y + bubbleComponentFrame.size.height;
                    }
                    else
                    {
                        continue;
                    }
                
                    MXAggregatedReactions* reactions = cellData.reactions[componentEventId].aggregatedReactionsWithNonZeroCount;
                    
                    BubbleReactionsView *reactionsView;
                    
                    if (!component.event.isRedactedEvent && reactions && !isCollapsableCellCollapsed)
                    {
                        BOOL showAllReactions = [cellData showAllReactionsForEvent:componentEventId];
                        BubbleReactionsViewModel *bubbleReactionsViewModel = [[BubbleReactionsViewModel alloc] initWithAggregatedReactions:reactions
                                                                                                                                   eventId:componentEventId
                                                                                                                                   showAll:showAllReactions];
                        
                        reactionsView = [BubbleReactionsView new];
                        reactionsView.viewModel = bubbleReactionsViewModel;
                        [reactionsView updateWithTheme:ThemeService.shared.theme];
                        
                        bubbleReactionsViewModel.viewModelDelegate = self;
                        
                        [temporaryViews addObject:reactionsView];
                        
                        if (!bubbleCell.tmpSubviews)
                        {
                            bubbleCell.tmpSubviews = [NSMutableArray array];
                        }
                        [bubbleCell.tmpSubviews addObject:reactionsView];
                        
                        if ([[bubbleCell class] conformsToProtocol:@protocol(BubbleCellReactionsDisplayable)])
                        {
                            id<BubbleCellReactionsDisplayable> reactionsDisplayable = (id<BubbleCellReactionsDisplayable>)bubbleCell;
                            [reactionsDisplayable addReactionsView:reactionsView];
                        }
                        else
                        {
                            reactionsView.translatesAutoresizingMaskIntoConstraints = NO;
                            [bubbleCell.contentView addSubview:reactionsView];
                            
                            CGFloat leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin;
                            
                            if (roomBubbleCellData.containsBubbleComponentWithEncryptionBadge)
                            {
                                leftMargin+= RoomBubbleCellLayout.encryptedContentLeftMargin;
                            }
                            
                            // Force receipts container size
                            [NSLayoutConstraint activateConstraints:
                             @[
                               [reactionsView.leadingAnchor constraintEqualToAnchor:reactionsView.superview.leadingAnchor constant:leftMargin],
                               [reactionsView.trailingAnchor constraintEqualToAnchor:reactionsView.superview.trailingAnchor constant:-RoomBubbleCellLayout.reactionsViewRightMargin],
                               [reactionsView.topAnchor constraintEqualToAnchor:reactionsView.superview.topAnchor constant:bottomPositionY + RoomBubbleCellLayout.reactionsViewTopMargin]
                               ]];
                        }
                    }
                    
                    MXKReceiptSendersContainer* avatarsContainer;
                    
                    // Handle read receipts (if any)
                    if (self.showBubbleReceipts && cellData.readReceipts.count && !isCollapsableCellCollapsed)
                    {
                        // Get the events receipts by ignoring the current user receipt.
                        NSArray* receipts =  cellData.readReceipts[component.event.eventId];
                        NSMutableArray *roomMembers;
                        NSMutableArray *placeholders;
                        
                        // Check whether some receipts are found
                        if (receipts.count)
                        {
                            // Retrieve the corresponding room members
                            roomMembers = [[NSMutableArray alloc] initWithCapacity:receipts.count];
                            placeholders = [[NSMutableArray alloc] initWithCapacity:receipts.count];
                            
                            for (MXReceiptData* data in receipts)
                            {
                                MXRoomMember * roomMember = [self.roomState.members memberWithUserId:data.userId];
                                if (roomMember)
                                {
                                    [roomMembers addObject:roomMember];
                                    [placeholders addObject:[AvatarGenerator generateAvatarForMatrixItem:roomMember.userId withDisplayName:roomMember.displayname]];
                                }
                            }
                        }
                        
                        // Check whether some receipts are found
                        if (roomMembers.count)
                        {
                            // Define the read receipts container, positioned on the right border of the bubble cell (Note the right margin 6 pts).
                            avatarsContainer = [[MXKReceiptSendersContainer alloc] initWithFrame:CGRectMake(bubbleCell.frame.size.width - RoomBubbleCellLayout.readReceiptsViewWidth + RoomBubbleCellLayout.readReceiptsViewRightMargin, bottomPositionY + RoomBubbleCellLayout.readReceiptsViewTopMargin, RoomBubbleCellLayout.readReceiptsViewWidth, RoomBubbleCellLayout.readReceiptsViewHeight) andMediaManager:self.mxSession.mediaManager];
                            
                            // Custom avatar display
                            avatarsContainer.maxDisplayedAvatars = 5;
                            avatarsContainer.avatarMargin = 6;
                            
                            // Set the container tag to be able to retrieve read receipts container from component index (see component selection in MXKRoomBubbleTableViewCell (Vector) category).
                            avatarsContainer.tag = index;
                            
                            avatarsContainer.moreLabelTextColor = ThemeService.shared.theme.textPrimaryColor;
                            
                            [avatarsContainer refreshReceiptSenders:roomMembers withPlaceHolders:placeholders andAlignment:ReadReceiptAlignmentRight];
                            avatarsContainer.readReceipts = receipts;
                            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:cell action:@selector(onReceiptContainerTap:)];
                            [tapRecognizer setNumberOfTapsRequired:1];
                            [tapRecognizer setNumberOfTouchesRequired:1];
                            [avatarsContainer addGestureRecognizer:tapRecognizer];
                            avatarsContainer.userInteractionEnabled = YES;
                            
                            avatarsContainer.translatesAutoresizingMaskIntoConstraints = NO;
                            avatarsContainer.accessibilityIdentifier = @"readReceiptsContainer";
                            
                            [temporaryViews addObject:avatarsContainer];
                            
                            // Add this read receipts container in the content view
                            if (!bubbleCell.tmpSubviews)
                            {
                                bubbleCell.tmpSubviews = [NSMutableArray arrayWithArray:@[avatarsContainer]];
                            }
                            else
                            {
                                [bubbleCell.tmpSubviews addObject:avatarsContainer];
                            }
                            
                            if ([[bubbleCell class] conformsToProtocol:@protocol(BubbleCellReadReceiptsDisplayable)])
                            {
                                id<BubbleCellReadReceiptsDisplayable> readReceiptsDisplayable = (id<BubbleCellReadReceiptsDisplayable>)bubbleCell;
                                
                                [readReceiptsDisplayable addReadReceiptsView:avatarsContainer];
                            }
                            else
                            {
                                [bubbleCell.contentView addSubview:avatarsContainer];
                                
                                // Force receipts container size
                                NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                                   attribute:NSLayoutAttributeWidth
                                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                                      toItem:nil
                                                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                                                  multiplier:1.0
                                                                                                    constant:RoomBubbleCellLayout.readReceiptsViewWidth];
                                NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                                    attribute:NSLayoutAttributeHeight
                                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                                       toItem:nil
                                                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                                                   multiplier:1.0
                                                                                                     constant:RoomBubbleCellLayout.readReceiptsViewHeight];
                                
                                // Force receipts container position
                                NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:avatarsContainer
                                                                                                      attribute:NSLayoutAttributeTrailing
                                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                                         toItem:avatarsContainer.superview
                                                                                                      attribute:NSLayoutAttributeTrailing
                                                                                                     multiplier:1.0
                                                                                                       constant:-RoomBubbleCellLayout.readReceiptsViewRightMargin];
                                
                                // At the bottom, we have reactions or nothing
                                NSLayoutConstraint *topConstraint;
                                if (reactionsView)
                                {
                                    topConstraint = [avatarsContainer.topAnchor constraintEqualToAnchor:reactionsView.bottomAnchor constant:RoomBubbleCellLayout.readReceiptsViewTopMargin];
                                }
                                else
                                {
                                    topConstraint = [avatarsContainer.topAnchor constraintEqualToAnchor:avatarsContainer.superview.topAnchor constant:bottomPositionY + RoomBubbleCellLayout.readReceiptsViewTopMargin];
                                }
                                
                                
                                // Available on iOS 8 and later
                                [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint, topConstraint, trailingConstraint]];
                            }
                        }
                    }
                    
                    // Check whether the read marker must be displayed here.
                    if (self.showReadMarker)
                    {
                        // The read marker is added into the overlay container.
                        // CAUTION: Keep disabled the user interaction on this container to not disturb tap gesture handling.
                        bubbleCell.bubbleOverlayContainer.backgroundColor = [UIColor clearColor];
                        bubbleCell.bubbleOverlayContainer.alpha = 1;
                        bubbleCell.bubbleOverlayContainer.userInteractionEnabled = NO;
                        bubbleCell.bubbleOverlayContainer.hidden = NO;
                        
                        if ([componentEventId isEqualToString:self.room.accountData.readMarkerEventId])
                        {
                            bubbleCell.readMarkerView = [[UIView alloc] initWithFrame:CGRectMake(0, bottomPositionY - RoomBubbleCellLayout.readMarkerViewHeight, bubbleCell.bubbleOverlayContainer.frame.size.width, RoomBubbleCellLayout.readMarkerViewHeight)];
                            bubbleCell.readMarkerView.backgroundColor = ThemeService.shared.theme.tintColor;
                            // Hide by default the marker, it will be shown and animated when the cell will be rendered.
                            bubbleCell.readMarkerView.hidden = YES;
                            bubbleCell.readMarkerView.tag = index;
                            
                            bubbleCell.readMarkerView.translatesAutoresizingMaskIntoConstraints = NO;
                            bubbleCell.readMarkerView.accessibilityIdentifier = @"readMarker";
                            [bubbleCell.bubbleOverlayContainer addSubview:bubbleCell.readMarkerView];
                            
                            // Force read marker constraints
                            bubbleCell.readMarkerViewTopConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.readMarkerView
                                                                                                  attribute:NSLayoutAttributeTop
                                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                                     toItem:bubbleCell.bubbleOverlayContainer
                                                                                                  attribute:NSLayoutAttributeTop
                                                                                                 multiplier:1.0
                                                                                                   constant:bottomPositionY - RoomBubbleCellLayout.readMarkerViewHeight];
                            bubbleCell.readMarkerViewLeadingConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.readMarkerView
                                                                                                      attribute:NSLayoutAttributeLeading
                                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                                         toItem:bubbleCell.bubbleOverlayContainer
                                                                                                      attribute:NSLayoutAttributeLeading
                                                                                                     multiplier:1.0
                                                                                                       constant:0];
                            bubbleCell.readMarkerViewTrailingConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.bubbleOverlayContainer
                                                                                                       attribute:NSLayoutAttributeTrailing
                                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                                          toItem:bubbleCell.readMarkerView
                                                                                                       attribute:NSLayoutAttributeTrailing
                                                                                                      multiplier:1.0
                                                                                                        constant:0];
                            
                            bubbleCell.readMarkerViewHeightConstraint = [NSLayoutConstraint constraintWithItem:bubbleCell.readMarkerView
                                                                                                     attribute:NSLayoutAttributeHeight
                                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                                        toItem:nil
                                                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                                                    multiplier:1.0
                                                                                                      constant:RoomBubbleCellLayout.readMarkerViewHeight];
                            
                            [NSLayoutConstraint activateConstraints:@[bubbleCell.readMarkerViewTopConstraint, bubbleCell.readMarkerViewLeadingConstraint, bubbleCell.readMarkerViewTrailingConstraint, bubbleCell.readMarkerViewHeightConstraint]];
                        }
                    }
                }
                
                index++;
            }
        }
        
        // Update attachmentView bottom constraint to display reactions and read receipts if needed
        
        UIView *attachmentView = bubbleCell.attachmentView;
        NSLayoutConstraint *attachmentViewBottomConstraint = bubbleCell.attachViewBottomConstraint;

        if (attachmentView && temporaryViews.count)
        {
            attachmentViewBottomConstraint.constant = roomBubbleCellData.additionalContentHeight;
        }
        else if (attachmentView)
        {
            [bubbleCell resetAttachmentViewBottomConstraintConstant];
        }
        
        // Check whether an event is currently selected: the other messages are then blurred
        if (_selectedEventId)
        {
            // Check whether the selected event belongs to this bubble
            NSInteger selectedComponentIndex = cellData.selectedComponentIndex;
            if (selectedComponentIndex != NSNotFound)
            {
                [bubbleCell selectComponent:cellData.selectedComponentIndex showEditButton:NO showTimestamp:cellData.showTimestampForSelectedComponent];
            }
            else
            {
                bubbleCell.blurred = YES;
            }
        }

        // Reset the marker if any
        if (bubbleCell.markerView)
        {
            [bubbleCell.markerView removeFromSuperview];
        }

        // Manage initial event (case of permalink or search result)
        if (self.timeline.initialEventId && self.markTimelineInitialEvent)
        {
            // Check if the cell contains this initial event
            for (NSUInteger index = 0; index < bubbleComponents.count; index++)
            {
                MXKRoomBubbleComponent *component = bubbleComponents[index];

                if ([component.event.eventId isEqualToString:self.timeline.initialEventId])
                {
                    // If yes, mark the event
                    [bubbleCell markComponent:index];
                    break;
                }
            }
        }
        
        // Auto animate the sticker in case of animated gif
        bubbleCell.isAutoAnimatedGif = (cellData.attachment && cellData.attachment.type == MXKAttachmentTypeSticker);
        
        [self applyMaskToAttachmentViewOfBubbleCell: bubbleCell];

        [self setupAccessibilityForCell:bubbleCell withCellData:cellData];
        
        // We are interested only by outgoing messages
        if ([cellData.senderId isEqualToString: self.mxSession.credentials.userId])
        {
            [bubbleCell updateTickViewWithFailedEventIds:self.failedEventIds];
        }
    }

    return cell;
}

- (RoomBubbleCellData*)roomBubbleCellDataForEventId:(NSString*)eventId
{
    id<MXKRoomBubbleCellDataStoring> cellData = [self cellDataOfEventWithEventId:eventId];
    RoomBubbleCellData *roomBubbleCellData;
    
    if ([cellData isKindOfClass:RoomBubbleCellData.class])
    {
        roomBubbleCellData = (RoomBubbleCellData*)cellData;
    }
    
    return roomBubbleCellData;
}

- (MXKeyVerificationRequest*)keyVerificationRequestFromEventId:(NSString*)eventId
{
    RoomBubbleCellData *roomBubbleCellData = [self roomBubbleCellDataForEventId:eventId];
    
    return roomBubbleCellData.keyVerification.request;
}

- (void)refreshCellsWithDelay
{
    if (self.refreshCellsTimer)
    {
        return;
    }
    
    self.refreshCellsTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(refreshCellsTimerFired) userInfo:nil repeats:NO];
}

- (void)refreshCellsTimerFired
{
    [self refreshCells];
    self.refreshCellsTimer = nil;
}

- (void)refreshCells
{
    if (self.delegate)
    {
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)registerKeyVerificationRequestNotification
{
    self.keyVerificationRequestDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationRequestDidChangeNotification
                                                                                                                 object:nil
                                                                                                                  queue:[NSOperationQueue mainQueue]
                                                                                                             usingBlock:^(NSNotification *notification)
                                                                {
                                                                    id notificationObject = notification.object;
                                                                    
                                                                    if ([notificationObject isKindOfClass:MXKeyVerificationByDMRequest.class])
                                                                    {
                                                                        MXKeyVerificationByDMRequest *keyVerificationByDMRequest = (MXKeyVerificationByDMRequest*)notificationObject;
                                                                        
                                                                        if ([keyVerificationByDMRequest.roomId isEqualToString:self.roomId])
                                                                        {
                                                                            RoomBubbleCellData *roomBubbleCellData = [self roomBubbleCellDataForEventId:keyVerificationByDMRequest.eventId];
                                                                            
                                                                            roomBubbleCellData.isKeyVerificationOperationPending = NO;
                                                                            roomBubbleCellData.keyVerification = nil;
                                                                            
                                                                            if (roomBubbleCellData)
                                                                            {
                                                                                [self refreshCellsWithDelay];
                                                                            }
                                                                        }
                                                                    }
                                                                }];
}

- (void)registerKeyVerificationTransactionNotification
{
    self.keyVerificationTransactionDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MXKeyVerificationTransactionDidChangeNotification
                                                                                                                        object:nil
                                                                                                                         queue:[NSOperationQueue mainQueue]
                                                                                                                    usingBlock:^(NSNotification *notification)
                                                                       {
                                                                           MXKeyVerificationTransaction *keyVerificationTransaction = (MXKeyVerificationTransaction*)notification.object;
                                                                           
                                                                           if ([keyVerificationTransaction.dmRoomId isEqualToString:self.roomId])
                                                                           {
                                                                               RoomBubbleCellData *roomBubbleCellData = [self roomBubbleCellDataForEventId:keyVerificationTransaction.dmEventId];
                                                                               
                                                                               roomBubbleCellData.isKeyVerificationOperationPending = NO;
                                                                               roomBubbleCellData.keyVerification = nil;
                                                                               
                                                                               if (roomBubbleCellData)
                                                                               {
                                                                                   [self refreshCellsWithDelay];
                                                                               }
                                                                           }
                                                                       }];
}

- (BOOL)shouldFetchKeyVerificationForEvent:(MXEvent*)event
{
    if (!event)
    {
        return NO;
    }
    
    BOOL shouldFetchKeyVerification = NO;
    
    switch (event.eventType)
    {
        case MXEventTypeKeyVerificationDone:
        case MXEventTypeKeyVerificationCancel:
            shouldFetchKeyVerification = YES;
            break;
        case MXEventTypeRoomMessage:
        {
            NSString *msgType = event.content[@"msgtype"];
            
            if ([msgType isEqualToString:kMXMessageTypeKeyVerificationRequest])
            {
                shouldFetchKeyVerification = YES;
            }
        }
            break;
        default:
            break;
    }
    
    return shouldFetchKeyVerification;
}

- (void)updateKeyVerificationIfNeededForRoomBubbleCellData:(RoomBubbleCellData*)bubbleCellData
{
    MXEvent *event = bubbleCellData.getFirstBubbleComponentWithDisplay.event;
    
    if (![self shouldFetchKeyVerificationForEvent:event])
    {
        return;
    }
    
    if (bubbleCellData.keyVerification != nil || bubbleCellData.isKeyVerificationOperationPending)
    {
        // Key verification already fetched or request is pending do nothing
        return;
    }
    
    __block MXHTTPOperation *operation = [self.mxSession.crypto.keyVerificationManager keyVerificationFromKeyVerificationEvent:event
                                                                                                                          success:^(MXKeyVerification * _Nonnull keyVerification)
                                          {
                                              BOOL shouldRefreshCells = bubbleCellData.isKeyVerificationOperationPending || bubbleCellData.keyVerification == nil;
                                              
                                              bubbleCellData.keyVerification = keyVerification;
                                              bubbleCellData.isKeyVerificationOperationPending = NO;
                                              
                                              if (shouldRefreshCells)
                                              {
                                                  [self refreshCellsWithDelay];
                                              }
                                              
                                          } failure:^(NSError * _Nonnull error) {
                                              
                                              NSLog(@"[RoomDataSource] updateKeyVerificationIfNeededForRoomBubbleCellData; keyVerificationFromKeyVerificationEvent fails with error: %@", error);
                                              
                                              bubbleCellData.isKeyVerificationOperationPending = NO;
                                          }];
    
    bubbleCellData.isKeyVerificationOperationPending = !operation;
}

#pragma mark -

- (void)setSelectedEventId:(NSString *)selectedEventId
{
    // Cancel the current selection (if any)
    if (_selectedEventId)
    {
        RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:_selectedEventId];
        cellData.selectedEventId = nil;
        cellData.showTimestampForSelectedComponent = NO;
    }
    
    if (selectedEventId.length)
    {
        RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:selectedEventId];
        
        cellData.showTimestampForSelectedComponent = self.showBubbleDateTimeOnSelection;

        if (cellData.collapsed && cellData.nextCollapsableCellData)
        {
            // Select nothing for a collased cell but open it
            [self collapseRoomBubble:cellData collapsed:NO];
            return;
        }
        else
        {
            cellData.selectedEventId = selectedEventId;
        }
    }
    
    _selectedEventId = selectedEventId;
}

- (Widget *)jitsiWidget
{
    Widget *jitsiWidget;

    // Note: Manage only one jitsi widget at a time for the moment
    jitsiWidget = [[WidgetManager sharedManager] widgetsOfTypes:@[kWidgetTypeJitsiV1, kWidgetTypeJitsiV2] inRoom:self.room withRoomState:self.roomState].firstObject;

    return jitsiWidget;
}

- (void)sendVideo:(NSURL*)videoLocalURL
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure
{
    UIImage *videoThumbnail = [MXKVideoThumbnailGenerator.shared generateThumbnailFrom:videoLocalURL];
    [self sendVideo:videoLocalURL withThumbnail:videoThumbnail success:success failure:failure];
}

- (void)acceptVerificationRequestForEventId:(NSString*)eventId success:(void(^)(void))success failure:(void(^)(NSError*))failure
{
    MXKeyVerificationRequest *keyVerificationRequest = [self keyVerificationRequestFromEventId:eventId];
    
    if (!keyVerificationRequest)
    {
        NSError *error;
        
        if (failure)
        {
            failure(error);
        }
        return;
    }
    
    [[AppDelegate theDelegate] presentIncomingKeyVerificationRequest:keyVerificationRequest inSession:self.mxSession];
    
    if (success)
    {
        success();
    }
}

- (void)declineVerificationRequestForEventId:(NSString*)eventId success:(void(^)(void))success failure:(void(^)(NSError*))failure
{
    MXKeyVerificationRequest *keyVerificationRequest = [self keyVerificationRequestFromEventId:eventId];
    
    if (!keyVerificationRequest)
    {
        NSError *error;
        
        if (failure)
        {
            failure(error);
        }
        return;
    }
    
    RoomBubbleCellData *roomBubbleCellData = [self roomBubbleCellDataForEventId:eventId];
    roomBubbleCellData.isKeyVerificationOperationPending = YES;
    
    [self refreshCells];
    
    [keyVerificationRequest cancelWithCancelCode:MXTransactionCancelCode.user success:^{
        
        // roomBubbleCellData.isKeyVerificationOperationPending will be set to NO by MXKeyVerificationRequestDidChangeNotification notification
        
        if (success)
        {
            success();
        }
        
    } failure:^(NSError * _Nonnull error) {
        
        roomBubbleCellData.isKeyVerificationOperationPending = NO;
        
        if (failure)
        {
            failure(error);
        }
    }];
}

- (void)resetTypingNotification {
    self.currentTypingUsers = nil;
}

#pragma - Accessibility

- (void)setupAccessibilityForCell:(MXKRoomBubbleTableViewCell *)cell withCellData:(RoomBubbleCellData*)cellData
{
    // Set accessibility only on media. Let VoiceOver automatically manages text messages
    if (cellData.attachment)
    {
        NSString *accessibilityLabel = [cellData accessibilityLabel];
        if (cell.messageTextView.text.length)
        {
            // Files are presented as text with link
            cell.messageTextView.accessibilityLabel = accessibilityLabel;
            cell.messageTextView.isAccessibilityElement = YES;
        }
        else
        {
            cell.attachmentView.accessibilityLabel = accessibilityLabel;
            cell.attachmentView.isAccessibilityElement = YES;
        }
    }
}

- (void)resetAccessibilityForCell:(MXKRoomBubbleTableViewCell *)cell
{
    cell.messageTextView.accessibilityLabel = nil;
    cell.attachmentView.accessibilityLabel = nil;
}

#pragma mark - BubbleReactionsViewModelDelegate

- (void)bubbleReactionsViewModel:(BubbleReactionsViewModel *)viewModel didAddReaction:(MXReactionCount *)reactionCount forEventId:(NSString *)eventId
{
    [self addReaction:reactionCount.reaction forEventId:eventId success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)bubbleReactionsViewModel:(BubbleReactionsViewModel *)viewModel didRemoveReaction:(MXReactionCount * _Nonnull)reactionCount forEventId:(NSString * _Nonnull)eventId
{
    [self removeReaction:reactionCount.reaction forEventId:eventId success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)bubbleReactionsViewModel:(BubbleReactionsViewModel *)viewModel didShowAllTappedForEventId:(NSString * _Nonnull)eventId
{
    [self setShowAllReactions:YES forEvent:eventId];
}

- (void)bubbleReactionsViewModel:(BubbleReactionsViewModel *)viewModel didShowLessTappedForEventId:(NSString * _Nonnull)eventId
{
    [self setShowAllReactions:NO forEvent:eventId];
}

- (void)setShowAllReactions:(BOOL)showAllReactions forEvent:(NSString*)eventId
{
    id<MXKRoomBubbleCellDataStoring> cellData = [self cellDataOfEventWithEventId:eventId];
    if ([cellData isKindOfClass:[RoomBubbleCellData class]])
    {
        RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)cellData;

        [roomBubbleCellData setShowAllReactions:showAllReactions forEvent:eventId];
        [self updateCellDataReactions:roomBubbleCellData forEventId:eventId];

        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)bubbleReactionsViewModel:(BubbleReactionsViewModel *)viewModel didLongPressForEventId:(NSString *)eventId
{
    [self.delegate dataSource:self didRecognizeAction:kMXKRoomBubbleCellLongPressOnReactionView inCell:nil userInfo:@{ kMXKRoomBubbleCellEventIdKey: eventId }];
}

- (void)applyMaskToAttachmentViewOfBubbleCell:(MXKRoomBubbleTableViewCell *)cell
{
    if (cell.attachmentView && !cell.attachmentView.layer.mask)
    {
        UIBezierPath *myClippingPath = [UIBezierPath bezierPathWithRoundedRect:cell.attachmentView.bounds cornerRadius:6];
        CAShapeLayer *mask = [CAShapeLayer layer];
        mask.path = myClippingPath.CGPath;
        cell.attachmentView.layer.mask = mask;
    }
}

#pragma mark - Message status management

- (void)updateStatusInfo
{
    if (!self.failedEventIds)
    {
        self.failedEventIds = [NSMutableSet new];
    }

    NSInteger bubbleIndex = bubbles.count;
    while (bubbleIndex--)
    {
        RoomBubbleCellData *cellData = bubbles[bubbleIndex];
        
        NSInteger componentIndex = cellData.bubbleComponents.count;
        while (componentIndex--) {
            MXKRoomBubbleComponent *component = cellData.bubbleComponents[componentIndex];
            MXEventSentState eventState = component.event.sentState;
            
            if (eventState == MXEventSentStateFailed)
            {
                [self.failedEventIds addObject:component.event.eventId];
                continue;
            }
            
            NSArray<MXReceiptData*> *receipts = cellData.readReceipts[component.event.eventId];
            if (receipts.count)
            {
                return;
            }
            
            if (eventState == MXEventSentStateSent)
            {
                cellData.componentIndexOfSentMessageTick = componentIndex;
                return;
            }
        }
    }
}

#pragma mark - Room creation intro cell

- (BOOL)canShowRoomCreationIntroCell
{
    NSString* userId = self.mxSession.myUser.userId;

    if (!userId || !self.isLive || self.isPeeking)
    {
        return NO;
    }
    
    // Room creation cell is only shown for the creator
    return [self.room.summary.creatorUserId isEqualToString:userId];
}

- (void)enableRoomCreationIntroCellDisplayIfNeeded
{
    self.showRoomCreationCell = [self canShowRoomCreationIntroCell];
}

// Insert the room creation intro cell at the begining
- (void)insertRoomCreationIntroCellDataIfNeeded
{
    @synchronized(bubbles)
    {
        NSUInteger existingRoomCreationCellDataIndex = [self roomBubbleDataIndexWithTag:RoomBubbleCellDataTagRoomCreationIntro];
        
        if (existingRoomCreationCellDataIndex != NSNotFound)
        {
            [bubbles removeObjectAtIndex:existingRoomCreationCellDataIndex];
        }
        
        if (self.showRoomCreationCell)
        {
            NSUInteger roomCreationConfigCellDataIndex = [self roomBubbleDataIndexWithTag:RoomBubbleCellDataTagRoomCreateConfiguration];
            
            // Only add room creation intro cell if `bubbles` array contains the room creation event
            if (roomCreationConfigCellDataIndex != NSNotFound)
            {
                if (!self.roomCreationCellData)
                {
                    MXEvent *event = [MXEvent new];
                    MXRoomState *roomState = [MXRoomState new];
                    RoomBubbleCellData *roomBubbleCellData = [[RoomBubbleCellData alloc] initWithEvent:event andRoomState:roomState andRoomDataSource:self];
                    roomBubbleCellData.tag = RoomBubbleCellDataTagRoomCreationIntro;
                    
                    self.roomCreationCellData = roomBubbleCellData;
                }
                
                [bubbles insertObject:self.roomCreationCellData atIndex:0];
            }
        }
        else
        {
            self.roomCreationCellData = nil;
        }
    }
}

- (NSUInteger)roomBubbleDataIndexWithTag:(RoomBubbleCellDataTag)tag
{
    @synchronized(bubbles)
    {
        return [bubbles indexOfObjectPassingTest:^BOOL(id<MXKRoomBubbleCellDataStoring>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:RoomBubbleCellData.class])
            {
                RoomBubbleCellData *roomBubbleCellData = (RoomBubbleCellData*)obj;
                if (roomBubbleCellData.tag == tag)
                {
                    return YES;
                }
            }
            return NO;
        }];
    }
}

@end
