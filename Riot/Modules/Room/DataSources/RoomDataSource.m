/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomDataSource.h"

#import "EventFormatter.h"
#import "RoomBubbleCellData.h"

#import "MXKRoomBubbleTableViewCell+Riot.h"
#import "AvatarGenerator.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

#import "MXRoom+Riot.h"

const CGFloat kTypingCellHeight = 24;

@interface RoomDataSource() <RoomReactionsViewModelDelegate, URLPreviewViewDelegate, ThreadSummaryViewDelegate, MXThreadingServiceDelegate>
{
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
    
    // The listener to the room retention changes.
    id retentionListener;
}

// Observe key verification request changes
@property (nonatomic, weak) id keyVerificationRequestDidChangeNotificationObserver;

// Observe key verification transaction changes
@property (nonatomic, weak) id keyVerificationTransactionDidChangeNotificationObserver;

// Listen to location beacon received
@property (nonatomic, weak) id beaconInfoSummaryListener;

// Listen to location beacon info deletion
@property (nonatomic, weak) id beaconInfoSummaryDeletionListener;

// Timer used to debounce cells refresh
@property (nonatomic, strong) NSTimer *refreshCellsTimer;

@property (nonatomic, weak, readonly) id<RoomDataSourceDelegate> roomDataSourceDelegate;

@property(nonatomic, readwrite) RoomEncryptionTrustLevel encryptionTrustLevel;

@property (nonatomic, strong) NSMutableSet *failedEventIds;

@property (nonatomic) RoomBubbleCellData *roomCreationCellData;

@property (nonatomic) BOOL showRoomCreationCell;

@property (nonatomic) NSInteger typingCellIndex;

@property(nonatomic, readwrite) BOOL isCurrentUserSharingActiveLocation;

@end

@implementation RoomDataSource

- (instancetype)initWithRoomId:(NSString *)roomId andMatrixSession:(MXSession *)matrixSession threadId:(NSString *)threadId
{
    self = [super initWithRoomId:roomId andMatrixSession:matrixSession threadId:threadId];
    if (self)
    {
        // Replace default Cell data class
        [self registerCellDataClass:RoomBubbleCellData.class forCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
        
        // Replace the event formatter
        [self updateEventFormatter];

        // Handle timestamp and read receipts display at Vector app level (see [tableView: cellForRowAtIndexPath:])
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

        [matrixSession.threadingService addDelegate:self];

        [self registerKeyVerificationRequestNotification];
        [self registerKeyVerificationTransactionNotification];
        [self registerTrustLevelDidChangeNotifications];
        [self registerBeaconInfoSummaryListner];
        
        self.encryptionTrustLevel = RoomEncryptionTrustLevelUnknown;
    }
    return self;
}

- (void)finalizeInitialization
{
    [super finalizeInitialization];

    // Sadly, we need to make sure we have fetched all room members from the HS
    // to be able to display read receipts
    if (!self.isPeeking && ![self.mxSession.store hasLoadedAllRoomMembersForRoom:self.roomId])
    {
        [self.room members:^(MXRoomMembers *roomMembers) {
            MXLogDebug(@"[MXKRoomDataSource] finalizeRoomDataSource: All room members have been retrieved");

            // Refresh the full table
            [self.delegate dataSource:self didCellChange:nil];

        } failure:^(NSError *error) {
            MXLogDebug(@"[MXKRoomDataSource] finalizeRoomDataSource: Cannot retrieve all room members");
        }];
    }

    if (self.room.summary.isEncrypted)
    {
        // Make sure we have the trust shield value
        [self.room.summary enableTrustTracking:YES];
        [self fetchEncryptionTrustedLevel];
    }
    
    self.showTypingRow = YES;
    
    [self updateCurrentUserLocationSharingStatus];
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
    
    // Apply the event types filter to display only the wanted event types.
    self.eventFormatter.eventTypesFilterForMessages = [MXKAppSettings standardAppSettings].eventsFilterForMessages;
}

- (void)setDelegate:(id<MXKDataSourceDelegate>)delegate
{
    [self unregisterRoomSummaryDidRemoveExpiredDataFromStoreNotifications];
    [self removeRoomRetentionEventListener];

    if (delegate && self.isLive)
    {
        if (self.room)
        {
            // Remove the potential expired messages from the store
            if ([self.room.summary removeExpiredRoomContentsFromStore])
            {
                [self.mxSession.store commit];
            }
            [self addRoomRetentionEventListener];
        }

        // Observe room history flush (expired content data)
        [self registerRoomSummaryDidRemoveExpiredDataFromStoreNotifications];
        [self roomSummaryDidRemoveExpiredDataFromStore];
    }

    [super setDelegate:delegate];
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
    
    [self.mxSession.threadingService removeDelegate:self];
    
    if (self.beaconInfoSummaryListener)
    {
        [self.mxSession.aggregations.beaconAggregations removeListener:self.beaconInfoSummaryListener];
    }
    
    if (self.beaconInfoSummaryDeletionListener)
    {
        [self.mxSession.aggregations.beaconAggregations removeListener:self.beaconInfoSummaryDeletionListener];
    }
    
    [self unregisterRoomSummaryDidRemoveExpiredDataFromStoreNotifications];
    [self removeRoomRetentionEventListener];
    
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
    if (RiotSettings.shared.enableLiveLocationSharing)
    {
        [self updateCurrentUserLocationSharingStatus];
    }
    
    if (!self.room.summary.isEncrypted)
    {
        return;
    }
    
    [self fetchEncryptionTrustedLevel];
}

- (void)fetchEncryptionTrustedLevel
{
    self.encryptionTrustLevel = self.room.summary.roomEncryptionTrustLevel;
    [self.roomDataSourceDelegate roomDataSourceDidUpdateEncryptionTrustLevel:self];
}

- (BOOL)shouldQueueEventForProcessing:(MXEvent *)event roomState:(MXRoomState *)roomState direction:(MXTimelineDirection)direction
{
    if (self.threadId)
    {
        //  if in a thread, ignore non-root event or events from other threads
        if (![event.eventId isEqualToString:self.threadId] && ![event.threadId isEqualToString:self.threadId])
        {
            //  Ignore the event
            return NO;
        }
        //  also ignore events related to un-threaded or events from other threads
        if (!event.isInThread && event.relatesTo.eventId)
        {
            MXEvent *relatedEvent = [self.mxSession.store eventWithEventId:event.relatesTo.eventId
                                                                    inRoom:event.roomId];
            if (![relatedEvent.threadId isEqualToString:self.threadId])
            {
                //  ignore the event
                return NO;
            }
        }
    }
    else if (RiotSettings.shared.enableThreads)
    {
        //  if not in a thread, ignore all threaded events
        if (event.isInThread)
        {
            //  ignore the event
            return NO;
        }
        //  also ignore events related to threaded events
        if (event.relatesTo.eventId)
        {
            MXEvent *relatedEvent = [self.mxSession.store eventWithEventId:event.relatesTo.eventId
                                                                    inRoom:event.roomId];
            if (relatedEvent.isInThread)
            {
                //  ignore the event
                return NO;
            }
        }
    }
    
    return [super shouldQueueEventForProcessing:event roomState:roomState direction:direction];
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
        
        if (self.showTypingRow && self.currentTypingUsers)
        {
            self.typingCellIndex = bubbles.count;
            return bubbles.count + 1;
        }
        else
        {
            self.typingCellIndex = -1;
            return bubbles.count;
        }
    }
    
    if (self.showTypingRow && self.currentTypingUsers)
    {
        self.typingCellIndex = count;
        return count + 1;
    }
    else
    {
        self.typingCellIndex = -1;
        
        //  leave it as is, if coming as 0 from super
        return count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.typingCellIndex)
    {
        MessageTypingCell *cell = [tableView dequeueReusableCellWithIdentifier:MessageTypingCell.defaultReuseIdentifier forIndexPath:indexPath];
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
    
    id<RoomTimelineCellDecorator> cellDecorator = [RoomTimelineConfiguration shared].currentStyle.cellDecorator;
    
    // Finalize cell view customization here
    if ([cell isKindOfClass:MXKRoomBubbleTableViewCell.class] && ![cell isKindOfClass:MXKRoomEmptyBubbleTableViewCell.class])
    {
        MXKRoomBubbleTableViewCell *bubbleCell = (MXKRoomBubbleTableViewCell*)cell;
        [self resetAccessibilityForCell:bubbleCell];

        RoomBubbleCellData *cellData = (RoomBubbleCellData*)bubbleCell.bubbleData;
        NSArray *bubbleComponents = cellData.bubbleComponents;

        BOOL isCollapsableCellCollapsed = cellData.collapsable && cellData.collapsed;
        
        // Display timestamp of the message if needed
        [cellDecorator addTimestampLabelIfNeededToCell:bubbleCell cellData:cellData];
        
        NSMutableArray *temporaryViews = [NSMutableArray new];
        
        // Handle read receipts and read marker display.
        // Ignore the read receipts on the bubble without actual display.
        // Ignore the read receipts on collapsed bubbles
        if ((((self.showBubbleReceipts && cellData.readReceipts.count) || cellData.reactions.count || cellData.hasLink || cellData.hasThreadRoot) && !isCollapsableCellCollapsed) || self.showReadMarker)
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
                    
                    URLPreviewView *urlPreviewView;
                    
                    // Show a URL preview if the component has a link that should be previewed.
                    if (component.showURLPreview)
                    {
                        urlPreviewView = [URLPreviewView instantiate];
                        urlPreviewView.preview = component.urlPreviewData;
                        urlPreviewView.delegate = self;
                        urlPreviewView.tag = index;
                        
                        [temporaryViews addObject:urlPreviewView];
                        [cellDecorator addURLPreviewView:urlPreviewView
                                                  toCell:bubbleCell cellData:cellData contentViewPositionY:bottomPositionY];
                    }
                    
                    MXAggregatedReactions* reactions = cellData.reactions[componentEventId].aggregatedReactionsWithNonZeroCount;
                    
                    RoomReactionsView *reactionsView;
                    
                    if (!component.event.isRedactedEvent && reactions && !isCollapsableCellCollapsed)
                    {
                        BOOL showAllReactions = [cellData showAllReactionsForEvent:componentEventId];
                        RoomReactionsViewModel *roomReactionsViewModel = [[RoomReactionsViewModel alloc] initWithAggregatedReactions:reactions
                                                                                                                                   eventId:componentEventId
                                                                                                                                   showAll:showAllReactions];
                        
                        reactionsView = [RoomReactionsView new];
                        reactionsView.viewModel = roomReactionsViewModel;
                        reactionsView.tag = index;
                        [reactionsView updateWithTheme:ThemeService.shared.theme];
                        
                        roomReactionsViewModel.viewModelDelegate = self;
                        
                        [temporaryViews addObject:reactionsView];
                        [cellDecorator addReactionView:reactionsView toCell:bubbleCell
                                              cellData:cellData contentViewPositionY:bottomPositionY upperDecorationView:urlPreviewView];
                    }
                    
                    ThreadSummaryView *threadSummaryView;
                    
                    //  display thread summary view if the component has a thread in the room timeline
                    if (RiotSettings.shared.enableThreads && component.thread && !self.threadId)
                    {
                        threadSummaryView = [[ThreadSummaryView alloc] initWithThread:component.thread
                                                                              session:self.mxSession];
                        threadSummaryView.delegate = self;
                        threadSummaryView.tag = index;
                        
                        [temporaryViews addObject:threadSummaryView];
                        UIView *upperDecorationView = reactionsView ?: urlPreviewView;

                        [cellDecorator addThreadSummaryView:threadSummaryView
                                                     toCell:bubbleCell
                                                   cellData:cellData
                                       contentViewPositionY:bottomPositionY
                                        upperDecorationView:upperDecorationView];
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
                            avatarsContainer = [[MXKReceiptSendersContainer alloc] initWithFrame:CGRectMake(bubbleCell.frame.size.width - PlainRoomCellLayoutConstants.readReceiptsViewWidth + PlainRoomCellLayoutConstants.readReceiptsViewRightMargin, bottomPositionY + PlainRoomCellLayoutConstants.readReceiptsViewTopMargin, PlainRoomCellLayoutConstants.readReceiptsViewWidth, PlainRoomCellLayoutConstants.readReceiptsViewHeight) andMediaManager:self.mxSession.mediaManager];
                            
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
                            UIView *upperDecorationView = threadSummaryView ?: (reactionsView ?: urlPreviewView);
                            
                            [cellDecorator addReadReceiptsView:avatarsContainer
                                                        toCell:bubbleCell
                                                      cellData:cellData
                                          contentViewPositionY:bottomPositionY
                                           upperDecorationView:upperDecorationView];
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
                            UIView *readMarkerView = [[UIView alloc] initWithFrame:CGRectMake(0, bottomPositionY - PlainRoomCellLayoutConstants.readMarkerViewHeight, bubbleCell.bubbleOverlayContainer.frame.size.width, PlainRoomCellLayoutConstants.readMarkerViewHeight)];
                            readMarkerView.backgroundColor = ThemeService.shared.theme.tintColor;
                            // Hide by default the marker, it will be shown and animated when the cell will be rendered.
                            readMarkerView.hidden = YES;
                            readMarkerView.tag = index;
                            readMarkerView.accessibilityIdentifier = @"readMarker";
                            
                            [cellDecorator addReadMarkerView:readMarkerView
                                                      toCell:bubbleCell
                                                    cellData:cellData
                                        contentViewPositionY:bottomPositionY];
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
            [[RoomTimelineConfiguration shared].currentStyle applySelectedStyleIfNeededToCell:bubbleCell cellData:cellData];
        }

        // Reset the marker if any
        if (bubbleCell.markerView)
        {
            [bubbleCell.markerView removeFromSuperview];
        }

        // Manage initial event (case of permalink or search result)
        if ((self.timeline.initialEventId && self.markTimelineInitialEvent) || self.highlightedEventId)
        {
            // Check if the cell contains this initial event
            for (NSUInteger index = 0; index < bubbleComponents.count; index++)
            {
                MXKRoomBubbleComponent *component = bubbleComponents[index];

                if ([component.event.eventId isEqualToString:self.timeline.initialEventId]
                    || [component.event.eventId isEqualToString:self.highlightedEventId])
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
            [cellDecorator addSendStatusViewToCell:bubbleCell
                                withFailedEventIds:self.failedEventIds];
        }
        
        // Make extra cell layout updates if needed
        [self updateCellLayoutIfNeeded:bubbleCell withCellData:cellData];
    }
    
    if ([cell conformsToProtocol:@protocol(Themable)])
    {
        id<Themable> cellThemable = (id<Themable>)cell;

        [cellThemable updateWithTheme:ThemeService.shared.theme];
    }

    return cell;
}

- (void)updateCellLayoutIfNeeded:(MXKRoomBubbleTableViewCell*)cell withCellData:(MXKRoomBubbleCellData*)cellData {
    
    RoomTimelineConfiguration *timelineConfiguration = [RoomTimelineConfiguration shared];
    
    [timelineConfiguration.currentStyle.cellLayoutUpdater updateLayoutIfNeededFor:cell andCellData:cellData];
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

- (id<MXKeyVerificationRequest>)keyVerificationRequestFromEventId:(NSString*)eventId
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
                                                                    
                                                                    if ([notificationObject conformsToProtocol:@protocol(MXKeyVerificationRequest)])
                                                                    {
                                                                        id<MXKeyVerificationRequest> keyVerificationRequest = (id<MXKeyVerificationRequest>)notificationObject;
                                                                        
                                                                        if (keyVerificationRequest.transport == MXKeyVerificationTransportDirectMessage && [keyVerificationRequest.roomId isEqualToString:self.roomId])
                                                                        {
                                                                            RoomBubbleCellData *roomBubbleCellData = [self roomBubbleCellDataForEventId:keyVerificationRequest.requestId];
                                                                            
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
                                                                           id<MXKeyVerificationTransaction> keyVerificationTransaction = (id<MXKeyVerificationTransaction>)notification.object;
                                                                           
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

- (void)registerBeaconInfoSummaryListner
{
    MXWeakify(self);
    self.beaconInfoSummaryListener = [self.mxSession.aggregations.beaconAggregations listenToBeaconInfoSummaryUpdateInRoomWithId:self.roomId handler:^(id<MXBeaconInfoSummaryProtocol> beaconInfoSummary) {
        MXStrongifyAndReturnIfNil(self);
        [self updateCurrentUserLocationSharingStatus];
        [self refreshFirstCellWithBeaconInfoSummary:beaconInfoSummary];
    }];
    
    self.beaconInfoSummaryDeletionListener = [self.mxSession.aggregations.beaconAggregations listenToBeaconInfoSummaryDeletionInRoomWithId:self.roomId handler:^(NSString * _Nonnull beaconInfoEventId) {
        MXStrongifyAndReturnIfNil(self);
        [self updateCurrentUserLocationSharingStatus];
        [self refreshFirstCellWithBeaconInfoSummaryIdentifier:beaconInfoEventId updatedBeaconInfoSummary:nil];
    }];
}

- (void)refreshFirstCellWithBeaconInfoSummary:(id<MXBeaconInfoSummaryProtocol>)beaconInfoSummary
{
    [self refreshFirstCellWithBeaconInfoSummaryIdentifier:beaconInfoSummary.id updatedBeaconInfoSummary:beaconInfoSummary];
}

- (void)refreshFirstCellWithBeaconInfoSummaryIdentifier:(NSString*)beaconInfoEventId updatedBeaconInfoSummary:(nullable id<MXBeaconInfoSummaryProtocol>)beaconInfoSummary
{
    NSUInteger cellIndex;
    __block RoomBubbleCellData *roomBubbleCellData;
    
    @synchronized (bubbles)
    {
        cellIndex = [bubbles indexOfObjectPassingTest:^BOOL(id<MXKRoomBubbleCellDataStoring>  _Nonnull cellData, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([cellData isKindOfClass:[RoomBubbleCellData class]])
            {
                roomBubbleCellData = (RoomBubbleCellData*)cellData;
                if ([roomBubbleCellData.beaconInfoSummary.id isEqualToString:beaconInfoEventId])
                {
                    *stop = YES;
                    return YES;
                }
            }
            return NO;
        }];
    }
    
    if (cellIndex != NSNotFound)
    {
        roomBubbleCellData.beaconInfoSummary = beaconInfoSummary;
        [self refreshCells];
    }
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
            NSString *msgType = event.content[kMXMessageTypeKey];
            
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
                                                                                                                        roomId:self.roomId
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
                                              
                                              MXLogDebug(@"[RoomDataSource] updateKeyVerificationIfNeededForRoomBubbleCellData; keyVerificationFromKeyVerificationEvent fails with error: %@", error);
                                              
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

        if (cellData.collapsed
            && cellData.nextCollapsableCellData
            && cellData.tag != RoomBubbleCellDataTagCall)
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

- (void)sendVideo:(NSURL *)videoLocalURL
          success:(void (^)(NSString * _Nonnull))success
          failure:(void (^)(NSError * _Nullable))failure
{
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoLocalURL];
    UIImage *videoThumbnail = [MXKVideoThumbnailGenerator.shared generateThumbnailFrom:videoLocalURL];
    
    [self sendVideoAsset:videoAsset withThumbnail:videoThumbnail success:success failure:failure];
}

- (void)acceptVerificationRequestForEventId:(NSString*)eventId success:(void(^)(void))success failure:(void(^)(NSError*))failure
{
    id<MXKeyVerificationRequest> keyVerificationRequest = [self keyVerificationRequestFromEventId:eventId];
    
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
    id<MXKeyVerificationRequest> keyVerificationRequest = [self keyVerificationRequestFromEventId:eventId];
    
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

#pragma mark - MXThreadingServiceDelegate

- (void)threadingService:(MXThreadingService *)service didCreateNewThread:(MXThread *)thread direction:(MXTimelineDirection)direction
{
    if (direction == MXTimelineDirectionBackwards)
    {
        //  no need to reload when paginating back
        return;
    }

    BOOL notify = YES;
    if (self.threadId)
    {
        //  no need to notify the thread screen, it'll cause a flickering
        notify = NO;
    }
    NSUInteger count = 0;
    @synchronized (bubbles)
    {
        count = bubbles.count;
    }
    if (count > 0)
    {
        [self reloadNotifying:notify];
    }
}

#pragma mark - RoomReactionsViewModelDelegate

- (void)roomReactionsViewModel:(RoomReactionsViewModel *)viewModel didAddReaction:(MXReactionCount *)reactionCount forEventId:(NSString *)eventId
{
    [self addReaction:reactionCount.reaction forEventId:eventId success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)roomReactionsViewModel:(RoomReactionsViewModel *)viewModel didRemoveReaction:(MXReactionCount * _Nonnull)reactionCount forEventId:(NSString * _Nonnull)eventId
{
    [self removeReaction:reactionCount.reaction forEventId:eventId success:^{
        
    } failure:^(NSError *error) {
        
    }];
}

- (void)roomReactionsViewModel:(RoomReactionsViewModel *)viewModel didShowAllTappedForEventId:(NSString * _Nonnull)eventId
{
    [self setShowAllReactions:YES forEvent:eventId];
}

- (void)roomReactionsViewModel:(RoomReactionsViewModel *)viewModel didShowLessTappedForEventId:(NSString * _Nonnull)eventId
{
    [self setShowAllReactions:NO forEvent:eventId];
}

- (void)roomReactionsViewModel:(RoomReactionsViewModel *)viewModel didTapAddReactionForEventId:(NSString * _Nonnull)eventId
{
    [self.delegate dataSource:self didRecognizeAction:kMXKRoomBubbleCellTapOnAddReaction inCell:nil userInfo:@{ kMXKRoomBubbleCellEventIdKey: eventId }];
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

- (void)roomReactionsViewModel:(RoomReactionsViewModel *)viewModel didLongPressForEventId:(NSString *)eventId
{
    [self.delegate dataSource:self didRecognizeAction:kMXKRoomBubbleCellLongPressOnReactionView inCell:nil userInfo:@{ kMXKRoomBubbleCellEventIdKey: eventId }];
}

- (void)applyMaskToAttachmentViewOfBubbleCell:(MXKRoomBubbleTableViewCell *)cell
{
    if (cell.attachmentView)
    {
        cell.attachmentView.layer.cornerRadius = 6;
        cell.attachmentView.layer.masksToBounds = YES;
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

#pragma mark - URLPreviewViewDelegate

- (void)didOpenURLFromPreviewView:(URLPreviewView *)previewView for:(NSString *)eventID in:(NSString *)roomID
{
    // Use the link stored in the bubble component when opening the URL as we only
    // store the sanitized URL in the preview data which may differ to the message content.
    RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:eventID];
    MXKRoomBubbleComponent *component = [cellData bubbleComponentWithLinkForEventId:eventID];
    if (!component)
    {
        MXLogError(@"[RoomDataSource] Failed to open link: Unable to find bubble component.")
        return;
    }
    
    [UIApplication.sharedApplication vc_open:component.link completionHandler:nil];
}

- (void)didCloseURLPreviewView:(URLPreviewView *)previewView for:(NSString *)eventID in:(NSString *)roomID
{
    // Remember that the user closed the preview so it isn't shown again.
    [URLPreviewService.shared closePreviewFor:eventID in:roomID];
    
    // Get the component to remove the URL preview from.
    RoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:eventID];
    MXKRoomBubbleComponent *component = [cellData bubbleComponentWithLinkForEventId:eventID];
    if (!component)
    {
        MXLogError(@"[RoomDataSource] Failed to close URL preview: Unable to find bubble component.")
        return;
    }
    
    // Hide the preview, remove its data and refresh the cells.
    component.showURLPreview = NO;
    component.urlPreviewData = nil;
    
    [cellData invalidateLayout];
    
    [self refreshCells];
}

#pragma mark - ThreadSummaryViewDelegate

- (void)threadSummaryViewTapped:(ThreadSummaryView *)summaryView
{
    [self.roomDataSourceDelegate roomDataSource:self
                                   didTapThread:summaryView.thread];
}

#pragma mark - Location sharing

- (void)updateCurrentUserLocationSharingStatus
{
    MXLocationService *locationService = self.mxSession.locationService;
    
    NSString *roomId = self.roomId;
    
    if (!locationService || !roomId)
    {
        return;
    }
    
    BOOL isUserSharingActiveLocation = [locationService isCurrentUserSharingActiveLocationInRoomWithId:roomId];
    
    if (isUserSharingActiveLocation != self.isCurrentUserSharingActiveLocation)
    {
        self.isCurrentUserSharingActiveLocation = isUserSharingActiveLocation;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.roomDataSourceDelegate roomDataSourceDidUpdateCurrentUserSharingLocationStatus:self];
        });
    }
}

#pragma mark - roomSummaryDidRemoveExpiredDataFromStore notifications

- (void)registerRoomSummaryDidRemoveExpiredDataFromStoreNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomSummaryDidRemoveExpiredDataFromStore:) name:MXRoomSummary.roomSummaryDidRemoveExpiredDataFromStore object:nil];
}

- (void)unregisterRoomSummaryDidRemoveExpiredDataFromStoreNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MXRoomSummary.roomSummaryDidRemoveExpiredDataFromStore object:nil];
}

- (void)roomSummaryDidRemoveExpiredDataFromStore:(NSNotification*)notification
{
    MXRoomSummary *roomSummary = notification.object;
    if (self.mxSession == roomSummary.mxSession && [self.roomId isEqualToString:roomSummary.roomId])
    {
        [self roomSummaryDidRemoveExpiredDataFromStore];
    }
}

- (void)roomSummaryDidRemoveExpiredDataFromStore
{
    // Check whether the first cell data refers to an expired event (this may be a state event
    MXEvent *firstMessageEvent;
    for (id<MXKRoomBubbleCellDataStoring> cellData in bubbles)
    {
        for (MXEvent *event in cellData.events)
        {
            if (!event.isState) {
                firstMessageEvent = event;
                break;
            }
        }

        if (firstMessageEvent)
        {
            break;
        }
    }

    if (firstMessageEvent && firstMessageEvent.originServerTs < self.room.summary.minimumTimestamp)
    {
        [self reload];
    }
}

#pragma mark - room retention event listener

- (void)addRoomRetentionEventListener
{
    // Register a listener to handle the room retention in live timelines
    retentionListener = [self.timeline listenToEventsOfTypes:@[MXRoomSummary.roomRetentionStateEventType] onEvent:^(MXEvent *redactionEvent, MXTimelineDirection direction, MXRoomState *roomState) {

        // Consider only live events
        if (direction == MXTimelineDirectionForwards)
        {
            // Remove the potential expired messages from the store
            if ([self.room.summary removeExpiredRoomContentsFromStore])
            {
                [self.mxSession.store commit];
            }
        }
    }];
}

- (void)removeRoomRetentionEventListener
{
    if (retentionListener)
    {
        [self.timeline removeListener:retentionListener];
        retentionListener = nil;
    }
}

@end
