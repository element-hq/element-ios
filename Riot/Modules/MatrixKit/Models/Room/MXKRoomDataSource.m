/*
Copyright 2024 New Vector Ltd.
Copyright 2019 The Matrix.org Foundation C.I.C
Copyright 2018 New Vector Ltd
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKRoomDataSource.h"

@import MatrixSDK;

#import "MXKQueuedEvent.h"
#import "MXKRoomBubbleTableViewCell.h"

#import "MXKRoomBubbleCellData.h"

#import "MXKTools.h"
#import "MXAggregatedReactions+MatrixKit.h"

#import "MXKAppSettings.h"

#import "GeneratedInterface-Swift.h"

const BOOL USE_THREAD_TIMELINE = YES;

#pragma mark - Constant definitions

NSString *const kMXKRoomBubbleCellDataIdentifier = @"kMXKRoomBubbleCellDataIdentifier";

NSString *const kMXKRoomDataSourceSyncStatusChanged = @"kMXKRoomDataSourceSyncStatusChanged";
NSString *const kMXKRoomDataSourceFailToLoadTimelinePosition = @"kMXKRoomDataSourceFailToLoadTimelinePosition";
NSString *const kMXKRoomDataSourceTimelineError = @"kMXKRoomDataSourceTimelineError";
NSString *const kMXKRoomDataSourceTimelineErrorErrorKey = @"kMXKRoomDataSourceTimelineErrorErrorKey";

NSString * const MXKRoomDataSourceErrorDomain = @"kMXKRoomDataSourceErrorDomain";

typedef NS_ENUM (NSUInteger, MXKRoomDataSourceError) {
    MXKRoomDataSourceErrorResendGeneric = 10001,
    MXKRoomDataSourceErrorResendInvalidMessageType = 10002,
    MXKRoomDataSourceErrorResendInvalidLocalFilePath = 10003,
};


@interface MXKRoomDataSource ()
{
    /**
     If the data is not from a live timeline, `initialEventId` is the event in the past
     where the timeline starts.
     */
    NSString *initialEventId;

    /**
     Current pagination request (if any)
     */
    MXHTTPOperation *paginationRequest;
    
    /**
     The actual listener related to the current pagination in the timeline.
     */
    id paginationListener;
    
    /**
     The listener to incoming events in the room.
     */
    id liveEventsListener;
    
    /**
     The listener to redaction events in the room.
     */
    id redactionListener;
    
    /**
     The listener to receipts events in the room.
     */
    id receiptsListener;

    /**
     The listener to reactions changed in the room.
     */
    id reactionsChangeListener;
    
    /**
     The listener to edits in the room.
     */
    id eventEditsListener;
    
    /**
     Current secondary pagination request (if any)
     */
    MXHTTPOperation *secondaryPaginationRequest;
    
    /**
     The listener to incoming events in the secondary room.
     */
    id secondaryLiveEventsListener;
    
    /**
     The listener to redaction events in the secondary room.
     */
    id secondaryRedactionListener;
    
    /**
     The actual listener related to the current pagination in the secondary timeline.
     */
    id secondaryPaginationListener;
    
    /**
     Mapping between events ids and bubbles.
     */
    NSMutableDictionary *eventIdToBubbleMap;
    
    /**
     Typing notifications listener.
     */
    id typingNotifListener;
    
    /**
     List of members who are typing in the room.
     */
    NSArray *currentTypingUsers;
    
    /**
     Snapshot of the queued events.
     */
    NSMutableArray *eventsToProcessSnapshot;
    
    /**
     Snapshot of the bubbles used during events processing.
     */
    NSMutableArray<id<MXKRoomBubbleCellDataStoring>> *bubblesSnapshot;
    
    /**
     The room being peeked, if any.
     */
    MXPeekingRoom *peekingRoom;

    /**
     If any, the non terminated series of collapsable events at the start of self.bubbles.
     (Such series is determined by the cell data of its oldest event).
     */
    id<MXKRoomBubbleCellDataStoring> collapsableSeriesAtStart;

    /**
     If any, the non terminated series of collapsable events at the end of self.bubbles.
     (Such series is determined by the cell data of its oldest event).
     */
    id<MXKRoomBubbleCellDataStoring> collapsableSeriesAtEnd;

    /**
     Observe UIApplicationSignificantTimeChangeNotification to trigger cell change on time formatting change.
     */
    id UIApplicationSignificantTimeChangeNotificationObserver;
    
    /**
     Observe NSCurrentLocaleDidChangeNotification to trigger cell change on time formatting change.
     */
    id NSCurrentLocaleDidChangeNotificationObserver;
    
    /**
     Observe kMXRoomDidFlushDataNotification to trigger cell change when existing room history has been flushed during server sync.
     */
    id roomDidFlushDataNotificationObserver;
    
    /**
     Observe kMXRoomDidUpdateUnreadNotification to refresh unread counters.
     */
    id roomDidUpdateUnreadNotificationObserver;
    
    /**
     Emote slash command prefix @"/me "
     */
    NSString *emoteMessageSlashCommandPrefix;
}

/**
 Indicate to stop back-paginating when finding an un-decryptable event as previous event.
 It is used to hide pre join UTD events before joining the room.
 */
@property (nonatomic, assign) BOOL shouldPreventBackPaginationOnPreviousUTDEvent;

/**
 Indicate to stop back-paginating.
 */
@property (nonatomic, assign) BOOL shouldStopBackPagination;

@property (nonatomic, readwrite) MXRoom *room;
@property (nonatomic, readwrite) MXThread *thread;

@property (nonatomic, readwrite) MXRoom *secondaryRoom;
@property (nonatomic, strong) id<MXEventTimeline> secondaryTimeline;
@property (nonatomic, readwrite) NSString *threadId;

@end

@implementation MXKRoomDataSource

+ (void)loadRoomDataSourceWithRoomId:(NSString*)roomId threadId:(NSString*)threadId andMatrixSession:(MXSession*)mxSession onComplete:(void (^)(id roomDataSource))onComplete
{
    MXKRoomDataSource *roomDataSource = [[self alloc] initWithRoomId:roomId andMatrixSession:mxSession threadId:threadId];
    [self ensureSessionStateForDataSource:roomDataSource initialEventId:nil andMatrixSession:mxSession onComplete:onComplete];
}

+ (void)loadRoomDataSourceWithRoomId:(NSString*)roomId initialEventId:(NSString*)initialEventId threadId:(NSString*)threadId andMatrixSession:(MXSession*)mxSession onComplete:(void (^)(id roomDataSource))onComplete
{
    MXKRoomDataSource *roomDataSource = [[self alloc] initWithRoomId:roomId initialEventId:initialEventId threadId:threadId andMatrixSession:mxSession];
    [self ensureSessionStateForDataSource:roomDataSource initialEventId:initialEventId andMatrixSession:mxSession onComplete:onComplete];
}

+ (void)loadRoomDataSourceWithPeekingRoom:(MXPeekingRoom*)peekingRoom andInitialEventId:(NSString*)initialEventId onComplete:(void (^)(id roomDataSource))onComplete
{
    MXKRoomDataSource *roomDataSource = [[self alloc] initWithPeekingRoom:peekingRoom andInitialEventId:initialEventId];
    [self finalizeRoomDataSource:roomDataSource onComplete:onComplete];
}

/// Ensure session state to be store data ready for the roomDataSource.
+ (void)ensureSessionStateForDataSource:(MXKRoomDataSource*)roomDataSource initialEventId:(NSString*)initialEventId andMatrixSession:(MXSession*)mxSession onComplete:(void (^)(id roomDataSource))onComplete
{
    //  if store is not ready, roomDataSource.room will be nil. So onComplete block will never be called.
    //  In order to successfully fetch the room, we should wait for store to be ready.
    if (mxSession.state >= MXSessionStateStoreDataReady)
    {
        [self finalizeRoomDataSource:roomDataSource onComplete:onComplete];
    }
    else
    {
        //  wait for session state to be store data ready
        __block id sessionStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXSessionStateDidChangeNotification object:mxSession queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if (mxSession.state >= MXSessionStateStoreDataReady)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:sessionStateObserver];
                [self finalizeRoomDataSource:roomDataSource onComplete:onComplete];
            }
        }];
    }
}

+ (void)finalizeRoomDataSource:(MXKRoomDataSource*)roomDataSource onComplete:(void (^)(id roomDataSource))onComplete
{
    if (roomDataSource)
    {
        [roomDataSource finalizeInitialization];

        // Asynchronously preload data here so that the data will be ready later
        // to synchronously respond to that request

        if (USE_THREAD_TIMELINE)
        {
            if (roomDataSource.threadId)
            {
                [roomDataSource.thread liveTimeline:^(id<MXEventTimeline> _Nonnull liveTimeline) {
                    [liveTimeline resetPagination];
                    onComplete(roomDataSource);
                }];
            }
            else
            {
                [roomDataSource.room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                    [liveTimeline resetPagination];
                    onComplete(roomDataSource);
                }];
            }
        }
        else
        {
            [roomDataSource.room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                [liveTimeline resetPagination];
                onComplete(roomDataSource);
            }];
        }
    }
}

- (instancetype)initWithRoomId:(NSString *)roomId andMatrixSession:(MXSession *)matrixSession threadId:(NSString *)threadId
{
    self = [super initWithMatrixSession:matrixSession];
    if (self)
    {
        MXLogVerbose(@"[MXKRoomDataSource][%p] initWithRoomId: %@", self, roomId);
        
        _roomId = roomId;
        _threadId = threadId;
        _secondaryRoomEventTypes = @[
            kMXEventTypeStringCallInvite,
            kMXEventTypeStringCallCandidates,
            kMXEventTypeStringCallAnswer,
            kMXEventTypeStringCallSelectAnswer,
            kMXEventTypeStringCallHangup,
            kMXEventTypeStringCallReject,
            kMXEventTypeStringCallNegotiate,
            kMXEventTypeStringCallReplaces,
            kMXEventTypeStringCallRejectReplacement
        ];
        NSString *virtualRoomId = [matrixSession virtualRoomOf:_roomId];
        if (virtualRoomId)
        {
            _secondaryRoomId = virtualRoomId;
        }
        _isLive = YES;
        bubbles = [NSMutableArray array];
        eventsToProcess = [NSMutableArray array];
        eventIdToBubbleMap = [NSMutableDictionary dictionary];
        
        _filterMessagesWithURL = NO;
        
        emoteMessageSlashCommandPrefix = [NSString stringWithFormat:@"%@ ", [MXKSlashCommandsHelper commandNameFor:MXKSlashCommandEmote]];

        // Set default data and view classes
        // Cell data
        [self registerCellDataClass:MXKRoomBubbleCellData.class forCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
        
        // Set default MXEvent -> NSString formatter
        self.eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:self.mxSession];
        // Apply here the event types filter to display only the wanted event types.
        self.eventFormatter.eventTypesFilterForMessages = [MXKAppSettings standardAppSettings].eventsFilterForMessages;
        
        // display the read receips by default
        self.showBubbleReceipts = YES;
        
        // show the read marker by default
        self.showReadMarker = YES;
        
        // Disable typing notification in cells by default.
        self.showTypingNotifications = NO;
        
        self.useCustomDateTimeLabel = NO;
        self.useCustomReceipts = NO;
        self.useCustomUnsentButton = NO;
        
        _maxBackgroundCachedBubblesCount = MXKROOMDATASOURCE_CACHED_BUBBLES_COUNT_THRESHOLD;
        _paginationLimitAroundInitialEvent = MXKROOMDATASOURCE_PAGINATION_LIMIT_AROUND_INITIAL_EVENT;

        // Observe UIApplicationSignificantTimeChangeNotification to refresh bubbles if date/time are shown.
        // UIApplicationSignificantTimeChangeNotification is posted if DST is updated, carrier time is updated
        UIApplicationSignificantTimeChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationSignificantTimeChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            [self onDateTimeFormatUpdate];
        }];
        
        // Observe NSCurrentLocaleDidChangeNotification to refresh bubbles if date/time are shown.
        // NSCurrentLocaleDidChangeNotification is triggered when the time swicthes to AM/PM to 24h time format
        NSCurrentLocaleDidChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSCurrentLocaleDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            [self onDateTimeFormatUpdate];
            
        }];

        // Listen to the event sent state changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidChangeSentState:) name:kMXEventDidChangeSentStateNotification object:nil];
        // Listen to events decrypted
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventDidDecrypt:) name:kMXEventDidDecryptNotification object:nil];
        // Listen to virtual rooms change
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(virtualRoomsDidChange:) name:kMXSessionVirtualRoomsDidChangeNotification object:matrixSession];
    }
    return self;
}

- (instancetype)initWithRoomId:(NSString*)roomId initialEventId:(NSString*)initialEventId2 threadId:(NSString*)threadId andMatrixSession:(MXSession*)mxSession
{
    self = [self initWithRoomId:roomId andMatrixSession:mxSession threadId:threadId];
    if (self)
    {
        if (initialEventId2)
        {
            initialEventId = initialEventId2;
            _isLive = NO;
        }
    }

    return self;
}

- (instancetype)initWithPeekingRoom:(MXPeekingRoom*)peekingRoom2 andInitialEventId:(NSString*)theInitialEventId
{
    self = [self initWithRoomId:peekingRoom2.roomId initialEventId:theInitialEventId threadId:nil andMatrixSession:peekingRoom2.mxSession];
    if (self)
    {
        peekingRoom = peekingRoom2;
        _isPeeking = YES;
    }
    return self;
}

- (void)dealloc
{
    [self unregisterEventEditsListener];
    [self unregisterScanManagerNotifications];
    [self unregisterReactionsChangeListener];
}

- (MXRoomState *)roomState
{
    // @TODO(async-state): Just here for dev
    NSAssert(_timeline.state, @"[MXKRoomDataSource] Room state must be preloaded before accessing to MXKRoomDataSource.roomState");
    return _timeline.state;
}

- (void)onDateTimeFormatUpdate
{
    // update the date and the time formatters
    [self.eventFormatter initDateTimeFormatters];
    
    // refresh the UI if it is required
    if (self.showBubblesDateTime && self.delegate)
    {
        // Reload all the table
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)markAllAsRead
{
    [_room.summary markAllAsRead];
}

- (void)limitMemoryUsage:(NSInteger)maxBubbleNb
{
    NSInteger bubbleCount;
    @synchronized(bubbles)
    {
        bubbleCount = bubbles.count;
    }
    
    if (bubbleCount > maxBubbleNb)
    {
        // Do nothing if some local echoes are in progress.
        NSArray<MXEvent*>* outgoingMessages = _room.outgoingMessages;
        
        for (NSInteger index = 0; index < outgoingMessages.count; index++)
        {
            MXEvent *outgoingMessage = [outgoingMessages objectAtIndex:index];
            
            if (outgoingMessage.sentState == MXEventSentStateSending ||
                outgoingMessage.sentState == MXEventSentStatePreparing ||
                outgoingMessage.sentState == MXEventSentStateEncrypting ||
                outgoingMessage.sentState == MXEventSentStateUploading)
            {
                MXLogDebug(@"[MXKRoomDataSource][%p] cancel limitMemoryUsage because some messages are being sent", self);
                return;
            }
        }

        // Reset the room data source (return in initial state: minimum memory usage).
        [self reload];
    }
}

- (void)reset
{
    if (roomDidFlushDataNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomDidFlushDataNotificationObserver];
        roomDidFlushDataNotificationObserver = nil;
    }
    
    if (roomDidUpdateUnreadNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomDidUpdateUnreadNotificationObserver];
        roomDidUpdateUnreadNotificationObserver = nil;
    }
    
    if (paginationRequest)
    {
        // We have to remove here the listener. A new pagination request may be triggered whereas the cancellation of this one is in progress
        [_timeline removeListener:paginationListener];
        paginationListener = nil;
        
        [paginationRequest cancel];
        paginationRequest = nil;
    }
    
    if (secondaryPaginationRequest)
    {
        // We have to remove here the listener. A new pagination request may be triggered whereas the cancellation of this one is in progress
        [_secondaryTimeline removeListener:secondaryPaginationListener];
        secondaryPaginationListener = nil;
        
        [secondaryPaginationRequest cancel];
        secondaryPaginationRequest = nil;
    }
    
    if (_room && liveEventsListener)
    {
        [_timeline removeListener:liveEventsListener];
        liveEventsListener = nil;
        
        [_timeline removeListener:redactionListener];
        redactionListener = nil;
        
        [_timeline removeListener:receiptsListener];
        receiptsListener = nil;
    }
    
    if (_secondaryRoom && secondaryLiveEventsListener)
    {
        [_secondaryTimeline removeListener:secondaryLiveEventsListener];
        secondaryLiveEventsListener = nil;
        
        [_secondaryTimeline removeListener:secondaryRedactionListener];
        secondaryRedactionListener = nil;
    }
    
    if (_room && typingNotifListener)
    {
        [_timeline removeListener:typingNotifListener];
        typingNotifListener = nil;
    }
    currentTypingUsers = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXRoomInitialSyncNotification object:nil];
    
    @synchronized(eventsToProcess)
    {
        MXLogVerbose(@"[MXKRoomDataSource][%p] Reset eventsToProcess", self);
        [eventsToProcess removeAllObjects];
    }
    
    // Suspend the reset operation if some events is under processing
    @synchronized(eventsToProcessSnapshot)
    {
        eventsToProcessSnapshot = nil;
        bubblesSnapshot = nil;
        
        @synchronized(bubbles)
        {
            for (id<MXKRoomBubbleCellDataStoring> bubble in bubbles) {
                bubble.prevCollapsableCellData = nil;
                bubble.nextCollapsableCellData = nil;
            }
            [bubbles removeAllObjects];
        }
        
        @synchronized(eventIdToBubbleMap)
        {
            [eventIdToBubbleMap removeAllObjects];
        }
        
        self.room = nil;
        self.thread = nil;
        self.secondaryRoom = nil;
    }
    
    _serverSyncEventCount = 0;
}

- (void)reload
{
    [self reloadNotifying:YES];
}

- (void)reloadNotifying:(BOOL)notify
{
    MXLogVerbose(@"[MXKRoomDataSource][%p] Reload - room id: %@", self, _roomId);
    
    [self setState:MXKDataSourceStatePreparing];
    
    [self reset];
    
    // Reload
    [self didMXSessionStateChange];
    
    // Notify the delegate to refresh the tableview
    if (notify && self.delegate)
    {
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)destroy
{
    MXLogDebug(@"[MXKRoomDataSource][%p] Destroy - room id: %@ - thread id: %@", self, _roomId, _threadId);
    
    [self unregisterScanManagerNotifications];
    [self unregisterReactionsChangeListener];
    [self unregisterEventEditsListener];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeSentStateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidDecryptNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionVirtualRoomsDidChangeNotification object:nil];

    if (NSCurrentLocaleDidChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:NSCurrentLocaleDidChangeNotificationObserver];
        NSCurrentLocaleDidChangeNotificationObserver = nil;
    }
    
    if (UIApplicationSignificantTimeChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationSignificantTimeChangeNotificationObserver];
        UIApplicationSignificantTimeChangeNotificationObserver = nil;
    }

    // If the room data source was used to peek into a room, stop the events stream on this room
    if (peekingRoom)
    {
        [_room.mxSession stopPeeking:peekingRoom];
    }

    [self reset];
    
    self.eventFormatter = nil;
    
    eventsToProcess = nil;
    bubbles = nil;
    eventIdToBubbleMap = nil;

    [_timeline destroy];
    [_secondaryTimeline destroy];
    
    [super destroy];
}

- (void)didMXSessionStateChange
{
    if (MXSessionStateStoreDataReady <= self.mxSession.state)
    {
        if (USE_THREAD_TIMELINE)
        {
            if (_threadId)
            {
                [self initializeTimelineForThread];
            }
            else
            {
                [self initializeTimelineForRoom];
            }
        }
        else
        {
            [self initializeTimelineForRoom];
        }
    }
}

- (void)initializeTimelineForRoom
{
    // Check whether the room is not already set
    if (!_room)
    {
        // Are we peeking into a random room or displaying a room the user is part of?
        if (peekingRoom)
        {
            self.room = peekingRoom;
        }
        else
        {
            self.room = [self.mxSession roomWithRoomId:_roomId];
        }

        if (_room)
        {
            // This is the time to set up the timeline according to the called init method
            if (_isLive)
            {
                // LIVE
                MXWeakify(self);
                [_room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                    MXStrongifyAndReturnIfNil(self);

                    self->_timeline = liveTimeline;

                    // Only one pagination process can be done at a time by an MXRoom object.
                    // This assumption is satisfied by MatrixKit. Only MXRoomDataSource does it.
                    [self.timeline resetPagination];

                    // Observe room history flush (sync with limited timeline, or state event redaction)
                    self->roomDidFlushDataNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomDidFlushDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {

                        MXRoom *room = notif.object;
                        if (self.mxSession == room.mxSession && ([self.roomId isEqualToString:room.roomId] ||
                                                                 ([self.secondaryRoomId isEqualToString:room.roomId])))
                        {
                            // The existing room history has been flushed during server sync because a gap has been observed between local and server storage.
                            [self reload];
                        }

                    }];

                    // Add the event listeners, by considering all the event types (the event filtering is applying by the event formatter),
                    // except if only the events with a url key in their content must be handled.
                    [self refreshEventListeners:(self.filterMessagesWithURL ? @[kMXEventTypeStringRoomMessage] : [MXKAppSettings standardAppSettings].allEventTypesForMessages)];

                    // display typing notifications is optional
                    // the inherited class can manage them by its own.
                    if (self.showTypingNotifications)
                    {
                        // Register on typing notif
                        [self listenTypingNotifications];
                    }

                    // Manage unsent messages
                    [self handleUnsentMessages];

                    // Update here data source state if it is not already ready
                    if (!self->_secondaryRoomId)
                    {
                        [self setState:MXKDataSourceStateReady];
                    }

                    // Check user membership in this room
                    MXMembership membership = self.room.summary.membership;
                    if (membership == MXMembershipUnknown || membership == MXMembershipInvite)
                    {
                        // Here the initial sync is not ended or the room is a pending invitation.
                        // Note: In case of invitation, a full sync will be triggered if the user joins this room.

                        // We have to observe here 'kMXRoomInitialSyncNotification' to reload room data when room sync is done.
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXRoomInitialSynced:) name:kMXRoomInitialSyncNotification object:self.room];
                    }
                }];
                
                if (!_secondaryRoom && _secondaryRoomId)
                {
                    _secondaryRoom = [self.mxSession roomWithRoomId:_secondaryRoomId];
                    
                    if (_secondaryRoom)
                    {
                        MXWeakify(self);
                        [_secondaryRoom liveTimeline:^(id<MXEventTimeline> liveTimeline) {
                            MXStrongifyAndReturnIfNil(self);

                            self->_secondaryTimeline = liveTimeline;

                            // Only one pagination process can be done at a time by an MXRoom object.
                            // This assumption is satisfied by MatrixKit. Only MXRoomDataSource does it.
                            [self.secondaryTimeline resetPagination];

                            // Add the secondary event listeners, by considering the event types in self.secondaryRoomEventTypes
                            [self refreshSecondaryEventListeners:self.secondaryRoomEventTypes];
                            
                            // Update here data source state if it is not already ready
                            [self setState:MXKDataSourceStateReady];

                            // Check user membership in the secondary room
                            MXMembership membership = self.secondaryRoom.summary.membership;
                            if (membership == MXMembershipUnknown || membership == MXMembershipInvite)
                            {
                                // Here the initial sync is not ended or the room is a pending invitation.
                                // Note: In case of invitation, a full sync will be triggered if the user joins this room.

                                // We have to observe here 'kMXRoomInitialSyncNotification' to reload room data when room sync is done.
                                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXRoomInitialSynced:) name:kMXRoomInitialSyncNotification object:self.secondaryRoom];
                            }
                        }];
                    }
                }
            }
            else
            {
                // Past timeline
                // Less things need to configured
                _timeline = [_room timelineOnEvent:initialEventId];

                // Refresh the event listeners. Note: events for past timelines come only from pagination request
                [self refreshEventListeners:nil];
                
                MXWeakify(self);

                // Preload the state and some messages around the initial event
                [_timeline resetPaginationAroundInitialEventWithLimit:_paginationLimitAroundInitialEvent success:^{

                    MXStrongifyAndReturnIfNil(self);
                    
                    // Do a "classic" reset. The room view controller will paginate
                    // from the events stored in the timeline store
                    [self.timeline resetPagination];
                    
                    // Update here data source state if it is not already ready
                    [self setState:MXKDataSourceStateReady];

                } failure:^(NSError *error) {
                    
                    MXStrongifyAndReturnIfNil(self);

                    MXLogDebug(@"[MXKRoomDataSource][%p] Failed to resetPaginationAroundInitialEventWithLimit", self);

                    // Notify the error
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKRoomDataSourceTimelineError
                                                                        object:self
                                                                      userInfo:@{
                                                                                 kMXKRoomDataSourceTimelineErrorErrorKey: error
                                                                                 }];
                }];
            }
        }
        else
        {
            MXLogDebug(@"[MXKRoomDataSource][%p] Warning: The user does not know the room %@", self, _roomId);
            
            // Update here data source state if it is not already ready
            [self setState:MXKDataSourceStateFailed];
        }
    }
}

- (void)initializeTimelineForThread
{
    // Check whether the thread is not already set
    if (_thread && self.state == MXKDataSourceStateReady)
    {
        return;
    }
    
    _thread = [self.mxSession.threadingService threadWithId:_threadId];
    
    if (!_thread)
    {
        //  there is not a thread yet available, this will be a new thread
        _thread = [self.mxSession.threadingService createTempThreadWithId:_threadId roomId:_roomId];
    }
    
    if (!_room)
    {
        //  also hold a reference to the room
        _room = [self.mxSession roomWithRoomId:_roomId];
    }
    
    if (_thread)
    {
        if (_isLive)
        {
            [_thread liveTimeline:^(id<MXEventTimeline> _Nonnull liveTimeline) {
                self->_timeline = liveTimeline;
                
                // Only one pagination process can be done at a time by an MXThread object.
                // This assumption is satisfied by MXRoomDataSource.
                [self.timeline resetPagination];
                
                // Add the event listeners, by considering all the event types (the event filtering is applying by the event formatter),
                // except if only the events with a url key in their content must be handled.
                [self refreshEventListeners:(self.filterMessagesWithURL ? @[kMXEventTypeStringRoomMessage] : [MXKAppSettings standardAppSettings].allEventTypesForMessages)];
                
                // Manage unsent messages
                [self handleUnsentMessages];
                
                [self setState:MXKDataSourceStateReady];
            }];
        }
        else
        {
            // Past timeline
            // Less things need to configured
            _timeline = [_thread timelineOnEvent:initialEventId];
            
            // Refresh the event listeners. Note: events for past timelines come only from pagination request
            [self refreshEventListeners:nil];
            
            MXWeakify(self);

            // Preload the state and some messages around the initial event
            [_timeline resetPaginationAroundInitialEventWithLimit:_paginationLimitAroundInitialEvent success:^{

                MXStrongifyAndReturnIfNil(self);
                
                // Do a "classic" reset. The room view controller will paginate
                // from the events stored in the timeline store
                [self.timeline resetPagination];
                
                // Update here data source state if it is not already ready
                [self setState:MXKDataSourceStateReady];

            } failure:^(NSError *error) {
                
                MXStrongifyAndReturnIfNil(self);

                MXLogDebug(@"[MXKRoomDataSource][%p] Failed to resetPaginationAroundInitialEventWithLimit", self);

                // Notify the error
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKRoomDataSourceTimelineError
                                                                    object:self
                                                                  userInfo:@{
                                                                      kMXKRoomDataSourceTimelineErrorErrorKey: error
                                                                  }];
            }];
        }
    }
    else
    {
        MXLogDebug(@"[MXKRoomDataSource][%p] Warning: The user does not know the thread %@", self, _threadId);
        
        // Update here data source state if it is not already ready
        [self setState:MXKDataSourceStateFailed];
    }
}

- (NSArray *)attachmentsWithThumbnail
{
    NSMutableArray *attachments = [NSMutableArray array];
    
    @synchronized(bubbles)
    {
        for (id<MXKRoomBubbleCellDataStoring> bubbleData in bubbles)
        {
            if (bubbleData.isAttachmentWithThumbnail && bubbleData.attachment.type != MXKAttachmentTypeSticker && !bubbleData.showAntivirusScanStatus)
            {
                [attachments addObject:bubbleData.attachment];
            }
        }
    }
    
    return attachments;
}

- (NSAttributedString *)partialAttributedTextMessage
{
    return _room.partialAttributedTextMessage;
}

- (void)setPartialAttributedTextMessage:(NSAttributedString *)partialAttributedTextMessage
{
    _room.partialAttributedTextMessage = partialAttributedTextMessage;
}

- (void)refreshEventListeners:(NSArray *)liveEventTypesFilterForMessages
{
    // Remove the existing listeners
    if (liveEventsListener)
    {
        [_timeline removeListener:liveEventsListener];
        [_timeline removeListener:redactionListener];
        [_timeline removeListener:receiptsListener];
    }

    // Listen to live events only for live timeline
    // Events for past timelines come only from pagination request
    if (_isLive)
    {
        // Register a new one with the requested filter
        MXWeakify(self);
        liveEventsListener = [_timeline listenToEventsOfTypes:liveEventTypesFilterForMessages onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            
            MXStrongifyAndReturnIfNil(self);

            if (MXTimelineDirectionForwards == direction)
            {
                if (event.eventType == MXEventTypeRoomMember && event.isUserProfileChange)
                {
                    [self refreshProfilesIfNeeded];
                }

                // Check for local echo suppression
                MXEvent *localEcho;
                if (self.room.outgoingMessages.count && [event.sender isEqualToString:self.mxSession.myUser.userId])
                {
                    localEcho = [self.room pendingLocalEchoRelatedToEvent:event];
                    if (localEcho)
                    {
                        // Check whether the local echo has a timestamp (in this case, it is replaced with the actual event).
                        if (localEcho.originServerTs != kMXUndefinedTimestamp)
                        {
                            // Replace the local echo by the true event sent by the homeserver
                            [self replaceEvent:localEcho withEvent:event];
                        }
                        else
                        {
                            // Remove the local echo, and process independently the true event.
                            [self replaceEvent:localEcho withEvent:nil];
                            localEcho = nil;
                        }
                    }
                }

                if (self.secondaryRoom)
                {
                    [self reloadNotifying:NO];
                }
                else if (nil == localEcho)
                {
                    // Process here incoming events, and outgoing events sent from another device.
                    if (self.threadId == nil && event.isInThread)
                    {
                        NSInteger index = [self indexOfCellDataWithEventId:event.relatesTo.eventId];
                        if (index != NSNotFound)
                        {
                            [self reloadNotifying:NO];
                        }
                    }
                    else
                    {
                        [self queueEventForProcessing:event withRoomState:roomState direction:MXTimelineDirectionForwards];
                        [self processQueuedEvents:nil];
                    }
                }
            }
        }];

        receiptsListener = [_timeline listenToEventsOfTypes:@[kMXEventTypeStringReceipt] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {

            if (MXTimelineDirectionForwards == direction)
            {
                // Handle this read receipt
                [self didReceiveReceiptEvent:event roomState:roomState];
            }
        }];
    }

    // Register a listener to handle redaction which can affect live and past timelines
    MXWeakify(self);
    redactionListener = [_timeline listenToEventsOfTypes:@[kMXEventTypeStringRoomRedaction] onEvent:^(MXEvent *redactionEvent, MXTimelineDirection direction, MXRoomState *roomState) {

        MXStrongifyAndReturnIfNil(self);

        // Consider only live redaction events
        if (direction == MXTimelineDirectionForwards)
        {
            // Do the processing on the processing queue
            dispatch_async(MXKRoomDataSource.processingQueue, ^{

                // Check whether a message contains the redacted event
                id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:redactionEvent.redacts];
                if (bubbleData)
                {
                    BOOL shouldRemoveBubbleData = NO;
                    BOOL hasChanged = NO;
                    MXEvent *redactedEvent = nil;

                    @synchronized (bubbleData)
                    {
                        // Retrieve the original event to redact it
                        NSArray *events = bubbleData.events;

                        for (MXEvent *event in events)
                        {
                            if ([event.eventId isEqualToString:redactionEvent.redacts])
                            {
                                // Check whether the event was not already redacted (Redaction may be handled by event timeline too).
                                if (!event.isRedactedEvent)
                                {
                                    redactedEvent = [event prune];
                                    redactedEvent.redactedBecause = redactionEvent.JSONDictionary;
                                }

                                break;
                            }
                        }

                        if (redactedEvent)
                        {
                            // Update bubble data
                            NSUInteger remainingEvents = [bubbleData updateEvent:redactionEvent.redacts withEvent:redactedEvent];

                            [self refreshRepliesWithUpdatedEventId:redactedEvent.eventId];

                            hasChanged = YES;

                            // Remove the bubble if there is no more events
                            shouldRemoveBubbleData = (remainingEvents == 0);
                        }
                    }

                    // Check whether the bubble should be removed
                    if (shouldRemoveBubbleData)
                    {
                        [self removeCellData:bubbleData];
                    }

                    if (hasChanged)
                    {
                        // Update the delegate on main thread
                        dispatch_async(dispatch_get_main_queue(), ^{

                            if (self.delegate)
                            {
                                [self.delegate dataSource:self didCellChange:nil];
                            }

                        });
                    }
                }

            });
        }
    }];
}

- (void)refreshSecondaryEventListeners:(NSArray *)liveEventTypesFilterForMessages
{
    // Remove the existing listeners
    if (secondaryLiveEventsListener)
    {
        [_secondaryTimeline removeListener:secondaryLiveEventsListener];
        [_secondaryTimeline removeListener:secondaryRedactionListener];
    }

    // Listen to live events only for live timeline
    // Events for past timelines come only from pagination request
    if (_isLive)
    {
        // Register a new one with the requested filter
        MXWeakify(self);
        secondaryLiveEventsListener = [_secondaryTimeline listenToEventsOfTypes:liveEventTypesFilterForMessages onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            
            MXStrongifyAndReturnIfNil(self);
            
            if (MXTimelineDirectionForwards == direction)
            {
                // Check for local echo suppression
                MXEvent *localEcho;
                if (self.secondaryRoom.outgoingMessages.count && [event.sender isEqualToString:self.mxSession.myUserId])
                {
                    localEcho = [self.secondaryRoom pendingLocalEchoRelatedToEvent:event];
                    if (localEcho)
                    {
                        // Check whether the local echo has a timestamp (in this case, it is replaced with the actual event).
                        if (localEcho.originServerTs != kMXUndefinedTimestamp)
                        {
                            // Replace the local echo by the true event sent by the homeserver
                            [self replaceEvent:localEcho withEvent:event];
                        }
                        else
                        {
                            // Remove the local echo, and process independently the true event.
                            [self replaceEvent:localEcho withEvent:nil];
                            localEcho = nil;
                        }
                    }
                }

                if (nil == localEcho)
                {
                    // Process here incoming events, and outgoing events sent from another device.
                    [self queueEventForProcessing:event withRoomState:roomState direction:MXTimelineDirectionForwards];
                    [self processQueuedEvents:nil];
                }
            }
        }];

    }

    // Register a listener to handle redaction which can affect live and past timelines
    secondaryRedactionListener = [_secondaryTimeline listenToEventsOfTypes:@[kMXEventTypeStringRoomRedaction] onEvent:^(MXEvent *redactionEvent, MXTimelineDirection direction, MXRoomState *roomState) {

        // Consider only live redaction events
        if (direction == MXTimelineDirectionForwards)
        {
            // Do the processing on the processing queue
            dispatch_async(MXKRoomDataSource.processingQueue, ^{

                // Check whether a message contains the redacted event
                id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:redactionEvent.redacts];
                if (bubbleData)
                {
                    BOOL shouldRemoveBubbleData = NO;
                    BOOL hasChanged = NO;
                    MXEvent *redactedEvent = nil;

                    @synchronized (bubbleData)
                    {
                        // Retrieve the original event to redact it
                        NSArray *events = bubbleData.events;

                        for (MXEvent *event in events)
                        {
                            if ([event.eventId isEqualToString:redactionEvent.redacts])
                            {
                                // Check whether the event was not already redacted (Redaction may be handled by event timeline too).
                                if (!event.isRedactedEvent)
                                {
                                    redactedEvent = [event prune];
                                    redactedEvent.redactedBecause = redactionEvent.JSONDictionary;
                                }

                                break;
                            }
                        }

                        if (redactedEvent)
                        {
                            // Update bubble data
                            NSUInteger remainingEvents = [bubbleData updateEvent:redactionEvent.redacts withEvent:redactedEvent];

                            hasChanged = YES;

                            // Remove the bubble if there is no more events
                            shouldRemoveBubbleData = (remainingEvents == 0);
                        }
                    }

                    // Check whether the bubble should be removed
                    if (shouldRemoveBubbleData)
                    {
                        [self removeCellData:bubbleData];
                    }

                    if (hasChanged)
                    {
                        // Update the delegate on main thread
                        dispatch_async(dispatch_get_main_queue(), ^{

                            if (self.delegate)
                            {
                                [self.delegate dataSource:self didCellChange:nil];
                            }

                        });
                    }
                }

            });
        }
    }];
}

- (void)setFilterMessagesWithURL:(BOOL)filterMessagesWithURL
{
    _filterMessagesWithURL = filterMessagesWithURL;
    
    if (_isLive && _room)
    {
        // Update the event listeners by considering the right types for the live events.
        [self refreshEventListeners:(_filterMessagesWithURL ? @[kMXEventTypeStringRoomMessage] : [MXKAppSettings standardAppSettings].allEventTypesForMessages)];
    }
}

- (void)setEventFormatter:(MXKEventFormatter *)eventFormatter
{
    if (_eventFormatter)
    {
        // Remove observers on previous event formatter settings
        [_eventFormatter.settings removeObserver:self forKeyPath:@"showRedactionsInRoomHistory"];
        [_eventFormatter.settings removeObserver:self forKeyPath:@"showUnsupportedEventsInRoomHistory"];
    }
    
    _eventFormatter = eventFormatter;
    
    if (_eventFormatter)
    {
        // Add observer to flush stored data on settings changes
        [_eventFormatter.settings  addObserver:self forKeyPath:@"showRedactionsInRoomHistory" options:0 context:nil];
        [_eventFormatter.settings  addObserver:self forKeyPath:@"showUnsupportedEventsInRoomHistory" options:0 context:nil];
    }
}

- (void)setShowBubblesDateTime:(BOOL)showBubblesDateTime
{
    _showBubblesDateTime = showBubblesDateTime;
    
    if (self.delegate)
    {
        // Reload all the table
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (void)setShowTypingNotifications:(BOOL)shouldShowTypingNotifications
{
    _showTypingNotifications = shouldShowTypingNotifications;
    
    if (shouldShowTypingNotifications)
    {
        // Register on typing notif
        [self listenTypingNotifications];
    }
    else
    {
        // Remove the live listener
        if (typingNotifListener)
        {
            [_timeline removeListener:typingNotifListener];
            currentTypingUsers = nil;
            typingNotifListener = nil;
        }
    }
}

- (void)listenTypingNotifications
{
    // Remove the previous live listener
    if (typingNotifListener)
    {
        [_timeline removeListener:typingNotifListener];
        currentTypingUsers = nil;
    }
    
    // Add typing notification listener
    MXWeakify(self);
    
    typingNotifListener = [_timeline listenToEventsOfTypes:@[kMXEventTypeStringTypingNotification] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState)
    {
        MXStrongifyAndReturnIfNil(self);
        
        // Handle only live events
        if (direction == MXTimelineDirectionForwards)
        {
            // Retrieve typing users list
            NSMutableArray *typingUsers = [NSMutableArray arrayWithArray:self.room.typingUsers];

            // Remove typing info for the current user
            NSUInteger index = [typingUsers indexOfObject:self.mxSession.myUser.userId];
            if (index != NSNotFound)
            {
                [typingUsers removeObjectAtIndex:index];
            }
            // Ignore this notification if both arrays are empty
            if (self->currentTypingUsers.count || typingUsers.count)
            {
                self->currentTypingUsers = typingUsers;
                
                if (self.delegate)
                {
                    // refresh all the table
                    [self.delegate dataSource:self didCellChange:nil];
                }
            }
        }
    }];
    
    currentTypingUsers = _room.typingUsers;
}

- (void)cancelAllRequests
{
    if (paginationRequest)
    {
        // We have to remove here the listener. A new pagination request may be triggered whereas the cancellation of this one is in progress
        [_timeline removeListener:paginationListener];
        paginationListener = nil;
        
        [paginationRequest cancel];
        paginationRequest = nil;
    }
    
    [super cancelAllRequests];
}

- (void)setDelegate:(id<MXKDataSourceDelegate>)delegate
{
    super.delegate = delegate;
    
    // Register to MXScanManager notification only when a delegate is set
    if (delegate && self.mxSession.scanManager)
    {
        [self registerScanManagerNotifications];
    }

    // Register to reaction notification only when a delegate is set
    if (delegate)
    {
        [self registerReactionsChangeListener];
        [self registerEventEditsListener];
    }
}

- (void)setRoom:(MXRoom *)room
{
    if (![_room isEqual:room])
    {
        _room = room;
        
        [self roomDidSet];
    }
}

- (void)roomDidSet
{
    
}

- (BOOL)shouldQueueEventForProcessing:(MXEvent*)event roomState:(MXRoomState*)roomState direction:(MXTimelineDirection)direction
{
    if (self.filterMessagesWithURL)
    {
        // Check whether the event has a value for the 'url' key in its content.
        if (!event.getMediaURLs.count)
        {
            // ignore the event
            return NO;
        }
        
        // Ignore voice message related to an actual voice broadcast.
        if (event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil) {
            return NO;
        }
    }
    
    // Check for undecryptable messages that were sent while the user was not in the room and hide them
    if ([MXKAppSettings standardAppSettings].hidePreJoinedUndecryptableEvents
        && direction == MXTimelineDirectionBackwards)
    {
        [self checkForPreJoinUTDWithEvent:event roomState:roomState];
        
        // Hide pre joint UTD events
        if (self.shouldStopBackPagination)
        {
            return NO;
        }
    }

    if (!USE_THREAD_TIMELINE && direction == MXTimelineDirectionBackwards && self.threadId)
    {
        //  when not using a thread timeline, data source will desperately fill the screen  with events by filtering them locally.
        //  we can stop when we see the thread root event when paginating backwards
        if ([event.eventId isEqualToString:self.threadId])
        {
            self.shouldStopBackPagination = YES;
        }
    }
    
    return YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"showRedactionsInRoomHistory" isEqualToString:keyPath] || [@"showUnsupportedEventsInRoomHistory" isEqualToString:keyPath])
    {
        // Flush the current bubble data and rebuild them
        [self reload];
    }
}

#pragma mark - Public methods
- (id<MXKRoomBubbleCellDataStoring>)cellDataAtIndex:(NSInteger)index
{
    id<MXKRoomBubbleCellDataStoring> bubbleData;
    @synchronized(bubbles)
    {
        if (index < bubbles.count)
        {
            bubbleData = bubbles[index];
        }
    }
    return bubbleData;
}

- (id<MXKRoomBubbleCellDataStoring>)cellDataOfEventWithEventId:(NSString *)eventId
{
    id<MXKRoomBubbleCellDataStoring> bubbleData;
    @synchronized(eventIdToBubbleMap)
    {
        bubbleData = eventIdToBubbleMap[eventId];
    }
    return bubbleData;
}

- (NSInteger)indexOfCellDataWithEventId:(NSString *)eventId
{
    NSInteger index = NSNotFound;
    
    id<MXKRoomBubbleCellDataStoring> bubbleData;
    @synchronized(eventIdToBubbleMap)
    {
        bubbleData = eventIdToBubbleMap[eventId];
    }
    
    if (bubbleData)
    {
        @synchronized(bubbles)
        {
            index = [bubbles indexOfObject:bubbleData];
        }
    }
    
    return index;
}

- (CGFloat)cellHeightAtIndex:(NSInteger)index withMaximumWidth:(CGFloat)maxWidth
{
    id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataAtIndex:index];
    
    // Sanity check
    if (bubbleData && self.delegate)
    {
        // Compute here height of bubble cell
        Class<MXKCellRendering> cellViewClass = [self.delegate cellViewClassForCellData:bubbleData];
        return [cellViewClass heightForCellData:bubbleData withMaximumWidth:maxWidth];
    }
    
    return 0;
}

- (void)invalidateBubblesCellDataCache
{
    @synchronized(bubbles)
    {
        for (id<MXKRoomBubbleCellDataStoring> bubble in bubbles)
        {
            [bubble invalidateTextLayout];
        }
    }
}

#pragma mark - Pagination
- (void)paginate:(NSUInteger)numItems direction:(MXTimelineDirection)direction onlyFromStore:(BOOL)onlyFromStore success:(void (^)(NSUInteger addedCellNumber))success failure:(void (^)(NSError *error))failure
{
    // Check the current data source state, and the actual user membership for this room.
    if (state != MXKDataSourceStateReady || ((self.room.summary.membership == MXMembershipUnknown || self.room.summary.membership == MXMembershipInvite) && ![self.roomState.historyVisibility isEqualToString:kMXRoomHistoryVisibilityWorldReadable]))
    {
        // Back pagination is not available here.
        if (failure)
        {
            failure(nil);
        }
        return;
    }
    
    if (paginationRequest || secondaryPaginationRequest)
    {
        MXLogDebug(@"[MXKRoomDataSource][%p] paginate: a pagination is already in progress", self);
        if (failure)
        {
            failure(nil);
        }
        return;
    }
    
    if (NO == [self canPaginate:direction])
    {
        MXLogDebug(@"[MXKRoomDataSource][%p] paginate: No more events to paginate", self);
        if (success)
        {
            success(0);
        }
    }
    
    __block NSUInteger addedCellNb = 0;
    __block NSMutableArray<NSError*> *operationErrors = [NSMutableArray arrayWithCapacity:2];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    
    // Define a new listener for this pagination
    paginationListener = [_timeline listenToEventsOfTypes:(_filterMessagesWithURL ? @[kMXEventTypeStringRoomMessage] : [MXKAppSettings standardAppSettings].allEventTypesForMessages) onEvent:^(MXEvent *event, MXTimelineDirection direction2, MXRoomState *roomState) {
        
        if (direction2 == direction)
        {
            [self queueEventForProcessing:event withRoomState:roomState direction:direction];
        }
        
    }];
    
    // Keep a local reference to this listener.
    id localPaginationListenerRef = paginationListener;
    
    dispatch_group_enter(dispatchGroup);
    // Launch the pagination
    
    MXWeakify(self);
    paginationRequest = [_timeline paginate:numItems
                                  direction:direction
                              onlyFromStore:onlyFromStore
                                   complete:^{
        
        MXStrongifyAndReturnIfNil(self);
        
        // Everything went well, remove the listener
        self->paginationRequest = nil;
        [self.timeline removeListener:self->paginationListener];
        self->paginationListener = nil;
        
        // Once done, process retrieved events
        [self processQueuedEvents:^(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb) {
            
            addedCellNb += (direction == MXTimelineDirectionBackwards) ? addedHistoryCellNb : addedLiveCellNb;
            dispatch_group_leave(dispatchGroup);
            
        }];
        
    } failure:^(NSError *error) {
        
        MXLogDebug(@"[MXKRoomDataSource][%p] paginateBackMessages fails", self);
        
        MXStrongifyAndReturnIfNil(self);
        
        // Something wrong happened or the request was cancelled.
        // Check whether the request is the actual one before removing listener and handling the retrieved events.
        if (localPaginationListenerRef == self->paginationListener)
        {
            self->paginationRequest = nil;
            [self.timeline removeListener:self->paginationListener];
            self->paginationListener = nil;
            
            // Process at least events retrieved from store
            [self processQueuedEvents:^(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb) {
                
                [operationErrors addObject:error];
                if (addedHistoryCellNb)
                {
                    addedCellNb += addedHistoryCellNb;
                }
                dispatch_group_leave(dispatchGroup);

            }];
        }
        
    }];
    
    if (_secondaryTimeline)
    {
        // Define a new listener for this pagination
        secondaryPaginationListener = [_secondaryTimeline listenToEventsOfTypes:_secondaryRoomEventTypes onEvent:^(MXEvent *event, MXTimelineDirection direction2, MXRoomState *roomState) {
            
            if (direction2 == direction)
            {
                [self queueEventForProcessing:event withRoomState:roomState direction:direction];
            }
            
        }];
        
        // Keep a local reference to this listener.
        id localPaginationListenerRef = secondaryPaginationListener;
        
        dispatch_group_enter(dispatchGroup);
        // Launch the pagination
        MXWeakify(self);
        secondaryPaginationRequest = [_secondaryTimeline paginate:numItems
                                                        direction:direction
                                                    onlyFromStore:onlyFromStore
                                                         complete:^{
            
            MXStrongifyAndReturnIfNil(self);
            
            // Everything went well, remove the listener
            self->secondaryPaginationRequest = nil;
            [self.secondaryTimeline removeListener:self->secondaryPaginationListener];
            self->secondaryPaginationListener = nil;
            
            // Once done, process retrieved events
            [self processQueuedEvents:^(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb) {
                
                addedCellNb += (direction == MXTimelineDirectionBackwards) ? addedHistoryCellNb : addedLiveCellNb;
                dispatch_group_leave(dispatchGroup);

            }];
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[MXKRoomDataSource][%p] paginateBackMessages fails", self);
            
            MXStrongifyAndReturnIfNil(self);
            
            // Something wrong happened or the request was cancelled.
            // Check whether the request is the actual one before removing listener and handling the retrieved events.
            if (localPaginationListenerRef == self->secondaryPaginationListener)
            {
                self->secondaryPaginationRequest = nil;
                [self.secondaryTimeline removeListener:self->secondaryPaginationListener];
                self->secondaryPaginationListener = nil;
                
                // Process at least events retrieved from store
                [self processQueuedEvents:^(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb) {
                    
                    [operationErrors addObject:error];
                    if (addedHistoryCellNb)
                    {
                        addedCellNb += addedHistoryCellNb;
                    }
                    dispatch_group_leave(dispatchGroup);

                }];
            }
            
        }];
    }
    
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        if (operationErrors.count)
        {
            if (failure)
            {
                failure(operationErrors.firstObject);
            }
        }
        else
        {
            if (success)
            {
                success(addedCellNb);
            }
        }
    });
}

- (void)paginateToFillRect:(CGRect)rect direction:(MXTimelineDirection)direction withMinRequestMessagesCount:(NSUInteger)minRequestMessagesCount success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    MXLogDebug(@"[MXKRoomDataSource][%p] paginateToFillRect: %@", self, NSStringFromCGRect(rect));
    
    // During the first call of this method, the delegate is supposed defined.
    // This delegate may be removed whereas this method is called by itself after a pagination request.
    // The delegate is required here to be able to compute cell height (and prevent infinite loop in case of reentrancy).
    if (!self.delegate)
    {
        MXLogDebug(@"[MXKRoomDataSource][%p] paginateToFillRect ignored (delegate is undefined)", self);
        if (failure)
        {
            failure(nil);
        }
        return;
    }

    // Get the total height of cells already loaded in memory
    CGFloat minMessageHeight = CGFLOAT_MAX;
    CGFloat bubblesTotalHeight = 0;

    @synchronized(bubbles)
    {
        // Check whether data has been aldready loaded
        if (bubbles.count)
        {
            NSUInteger eventsCount = 0;
            for (NSInteger i = bubbles.count - 1; i >= 0; i--)
            {
                id<MXKRoomBubbleCellDataStoring> bubbleData = bubbles[i];
                eventsCount += bubbleData.events.count;
                
                CGFloat bubbleHeight = [self cellHeightAtIndex:i withMaximumWidth:rect.size.width];
                // Sanity check
                if (bubbleHeight)
                {
                    bubblesTotalHeight += bubbleHeight;

                    if (bubblesTotalHeight > rect.size.height)
                    {
                        // No need to compute more cells heights, there are enough to fill the rect
                        MXLogDebug(@"[MXKRoomDataSource][%p] -> %tu already loaded bubbles (%tu events) are enough to fill the screen", self, bubbles.count - i, eventsCount);
                        break;
                    }
                    
                    // Compute the minimal height an event takes
                    minMessageHeight = MIN(minMessageHeight, bubbleHeight / bubbleData.events.count);
                }
            }
        }
        else if (minRequestMessagesCount && [self canPaginate:direction])
        {
            MXLogDebug(@"[MXKRoomDataSource][%p] paginateToFillRect: Prefill with data from the store", self);
            // Give a chance to load data from the store before doing homeserver requests
            // Reuse minRequestMessagesCount because we need to provide a number.
            [self paginate:minRequestMessagesCount direction:direction onlyFromStore:YES success:^(NSUInteger addedCellNumber) {

                // Then retry
                [self paginateToFillRect:rect direction:direction withMinRequestMessagesCount:minRequestMessagesCount success:success failure:failure];

            } failure:failure];
            return;
        }
    }
    
    // Is there enough cells to cover all the requested height?
    if (bubblesTotalHeight < rect.size.height)
    {
        // No. Paginate to get more messages
        if ([self canPaginate:direction])
        {
            // Bound the minimal height to 44
            minMessageHeight = MIN(minMessageHeight, 44);
            
            // Load messages to cover the remaining height
            // Use an extra of 50% to manage unsupported/unexpected/redated events
            NSUInteger messagesToLoad = ceil((rect.size.height - bubblesTotalHeight) / minMessageHeight * 1.5);

            // It does not worth to make a pagination request for only 1 message.
            // So, use minRequestMessagesCount
            messagesToLoad = MAX(messagesToLoad, minRequestMessagesCount);
            
            MXLogDebug(@"[MXKRoomDataSource][%p] paginateToFillRect: need to paginate %tu events to cover %fpx", self, messagesToLoad, rect.size.height - bubblesTotalHeight);
            [self paginate:messagesToLoad direction:direction onlyFromStore:NO success:^(NSUInteger addedCellNumber) {
                
                [self paginateToFillRect:rect direction:direction withMinRequestMessagesCount:minRequestMessagesCount success:success failure:failure];
                
            } failure:failure];
        }
        else
        {
            
            MXLogDebug(@"[MXKRoomDataSource][%p] paginateToFillRect: No more events to paginate", self);
            if (success)
            {
                success();
            }
        }
    }
    else
    {
        // Yes. Nothing to do
        if (success)
        {
            success();
        }
    }
}


#pragma mark - Sending
- (void)sendTextMessage:(NSString *)text success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    BOOL isEmote = [self isMessageAnEmote:text];
    NSString *sanitizedText = [self sanitizedMessageText:text];
    NSString *html = [self htmlMessageFromSanitizedText:sanitizedText];
    
    // Make the request to the homeserver
    if (isEmote)
    {
        [_room sendEmote:sanitizedText formattedText:html threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    }    
    else
    {
        [_room sendTextMessage:sanitizedText formattedText:html threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    }
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendReplyToEvent:(MXEvent*)eventToReply
         withTextMessage:(NSString *)text
                 success:(void (^)(NSString *))success
                 failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    NSString *sanitizedText = [self sanitizedMessageText:text];
    NSString *html = [self htmlMessageFromSanitizedText:sanitizedText];
    
    id<MXSendReplyEventStringLocalizerProtocol> stringLocalizer = [MXKSendReplyEventStringLocalizer new];
    
    [_room sendReplyToEvent:eventToReply withTextMessage:sanitizedText formattedTextMessage:html stringLocalizer:stringLocalizer threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (BOOL)isMessageAnEmote:(NSString*)text
{
    return [text hasPrefix:emoteMessageSlashCommandPrefix];
}

- (NSString*)sanitizedMessageText:(NSString*)rawText
{
    NSString *text;
    
    //Remove NULL bytes from the string, as they are likely to trip up many things later,
    //including our own C-based Markdown-to-HTML convertor.
    //
    //Normally, we don't expect people to be entering NULL bytes in messages,
    //but because of a bug in iOS 11, it's easy to have it happen.
    //
    //iOS 11's Smart Punctuation feature "conveniently" converts double hyphens (`--`) to longer en-dashes (`—`).
    //However, when adding any kind of dash/hyphen after such an en-dash,
    //iOS would also insert a NULL byte inbetween the dashes (`<en-dash>NULL<some other dash>`).
    //
    //Even if a future iOS update fixes this,
    //we'd better be defensive and always remove occurrences of NULL bytes from text messages.
    text = [rawText stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%C", 0x00000000] withString:@""];
    
    // Check whether the message is an emote
    if ([self isMessageAnEmote:text])
    {
        // Remove "/me " string
        text = [text substringFromIndex:emoteMessageSlashCommandPrefix.length];
    }
    
    return text;
}

- (NSString*)htmlMessageFromSanitizedText:(NSString*)sanitizedText
{
    NSString *html;
    
    // Did user use Markdown text?
    NSString *htmlStringFromMarkdown = [_eventFormatter htmlStringFromMarkdownString:sanitizedText];
    
    if ([htmlStringFromMarkdown isEqualToString:sanitizedText])
    {
        // No formatted string
        html = nil;
    }
    else
    {
        html = htmlStringFromMarkdown;
    }
    
    return html;
}

- (void)sendImage:(UIImage *)image success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    // Make sure the uploaded image orientation is up
    image = [MXKTools forceImageOrientationUp:image];
    
    // Only jpeg image is supported here
    NSString *mimetype = @"image/jpeg";
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    
    // Shall we need to consider a thumbnail?
    UIImage *thumbnail = nil;
    if (_room.summary.isEncrypted)
    {
        // Thumbnail is useful only in case of encrypted room
        thumbnail = [MXKTools reduceImage:image toFitInSize:CGSizeMake(800, 600)];
        if (thumbnail == image)
        {
            thumbnail = nil;
        }
    }
    
    [self sendImageData:imageData withImageSize:image.size mimeType:mimetype andThumbnail:thumbnail success:success failure:failure];
}

- (BOOL)canReplyToEventWithId:(NSString*)eventIdToReply
{
    MXEvent *eventToReply = [self eventWithEventId:eventIdToReply];
    return [self.room canReplyToEvent:eventToReply];
}

- (void)sendImage:(NSData *)imageData mimeType:(NSString *)mimetype success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    UIImage *image = [UIImage imageWithData:imageData];
    
    // Shall we need to consider a thumbnail?
    UIImage *thumbnail = nil;
    if (_room.summary.isEncrypted)
    {
        // Thumbnail is useful only in case of encrypted room
        thumbnail = [MXKTools reduceImage:image toFitInSize:CGSizeMake(800, 600)];
        if (thumbnail == image)
        {
            thumbnail = nil;
        }
    }
    
    [self sendImageData:imageData withImageSize:image.size mimeType:mimetype andThumbnail:thumbnail success:success failure:failure];
}

- (void)sendImageData:(NSData*)imageData withImageSize:(CGSize)imageSize mimeType:(NSString*)mimetype andThumbnail:(UIImage*)thumbnail success:(void (^)(NSString *eventId))success failure:(void (^)(NSError *error))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    [_room sendImage:imageData withImageSize:imageSize mimeType:mimetype andThumbnail:thumbnail threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendVideo:(NSURL *)videoLocalURL withThumbnail:(UIImage *)videoThumbnail success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoLocalURL];
    [self sendVideoAsset:videoAsset withThumbnail:videoThumbnail success:success failure:failure];
}

- (void)sendVideoAsset:(AVAsset *)videoAsset withThumbnail:(UIImage *)videoThumbnail success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    [_room sendVideoAsset:videoAsset withThumbnail:videoThumbnail threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendAudioFile:(NSURL *)audioFileLocalURL mimeType:mimeType success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    [_room sendAudioFile:audioFileLocalURL mimeType:mimeType threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure keepActualFilename:YES];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendVoiceMessage:(NSURL *)audioFileLocalURL
 additionalContentParams:(NSDictionary *)additionalContentParams
                mimeType:mimeType
                duration:(NSUInteger)duration
                 samples:(NSArray<NSNumber *> *)samples
                 success:(void (^)(NSString *))success
                 failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    [_room sendVoiceMessage:audioFileLocalURL additionalContentParams:additionalContentParams mimeType:mimeType duration:duration samples:samples threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure keepActualFilename:YES];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}


- (void)sendFile:(NSURL *)fileLocalURL mimeType:(NSString*)mimeType success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    [_room sendFile:fileLocalURL mimeType:mimeType threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendMessageWithContent:(NSDictionary *)msgContent success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    // Make the request to the homeserver
    [_room sendMessageWithContent:msgContent threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendLocationWithLatitude:(double)latitude
                       longitude:(double)longitude
                     description:(NSString *)description
                  coordinateType:(MXEventAssetType)coordinateType
                         success:(void (^)(NSString *))success
                         failure:(void (^)(NSError *))failure
{
    __block MXEvent *localEchoEvent = nil;
    
    // Make the request to the homeserver
    [_room sendLocationWithLatitude:latitude
                          longitude:longitude
                        description:description
                           threadId:self.threadId
                          localEcho:&localEchoEvent
                          assetType:coordinateType
                            success:success failure:failure];
    
    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)sendEventOfType:(MXEventTypeString)eventTypeString content:(NSDictionary<NSString*, id>*)msgContent success:(void (^)(NSString *eventId))success failure:(void (^)(NSError *error))failure
{
    __block MXEvent *localEchoEvent = nil;

    // Make the request to the homeserver
    [_room sendEventOfType:eventTypeString content:msgContent threadId:self.threadId localEcho:&localEchoEvent success:success failure:failure];

    if (localEchoEvent)
    {
        // Make the data source digest this fake local echo message
        [self queueEventForProcessing:localEchoEvent withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        [self processQueuedEvents:nil];
    }
}

- (void)resendEventWithEventId:(NSString *)eventId success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure
{
    MXEvent *event = [self eventWithEventId:eventId];
    
    // Sanity check
    if (!event)
    {
        return;
    }
    
    MXLogInfo(@"[MXKRoomDataSource][%p] resendEventWithEventId. EventId: %@", self, event.eventId);
    
    // Check first whether the event is encrypted
    if ([event.wireType isEqualToString:kMXEventTypeStringRoomEncrypted])
    {
        // We try here to resent an encrypted event
        // Note: we keep the existing local echo.
        [_room sendEventOfType:kMXEventTypeStringRoomEncrypted content:event.wireContent threadId:self.threadId localEcho:&event success:success failure:failure];
    }
    else if ([event.type isEqualToString:kMXEventTypeStringRoomMessage])
    {
        // And retry the send the message according to its type
        NSString *msgType = event.content[kMXMessageTypeKey];
        if ([msgType isEqualToString:kMXMessageTypeText] || [msgType isEqualToString:kMXMessageTypeEmote])
        {
            // Resend the Matrix event by reusing the existing echo
            [_room sendMessageWithContent:event.content threadId:self.threadId localEcho:&event success:success failure:failure];
        }
        else if ([msgType isEqualToString:kMXMessageTypeImage])
        {
            // Check whether the sending failed while uploading the data.
            // If the content url corresponds to a upload id, the upload was not complete.
            NSString *contentURL = event.content[@"url"];
            if (contentURL && [contentURL hasPrefix:kMXMediaUploadIdPrefix])
            {
                NSString *mimetype = nil;
                if (event.content[@"info"])
                {
                    mimetype = event.content[@"info"][@"mimetype"];
                }
                
                NSString *localImagePath = [MXMediaManager cachePathForMatrixContentURI:contentURL andType:mimetype inFolder:_roomId];
                UIImage* image = [MXMediaManager loadPictureFromFilePath:localImagePath];
                if (image)
                {
                    // Restart sending the image from the beginning.
                    
                    // Remove the local echo.
                    [self removeEventWithEventId:eventId];
                    
                    if (mimetype)
                    {
                        NSData *imageData = [NSData dataWithContentsOfFile:localImagePath];
                        [self sendImage:imageData mimeType:mimetype success:success failure:failure];
                    }
                    else
                    {
                        [self sendImage:image success:success failure:failure];
                    }
                }
                else
                {
                    if (failure)
                    {
                        failure([NSError errorWithDomain:MXKRoomDataSourceErrorDomain code:MXKRoomDataSourceErrorResendGeneric userInfo:nil]);
                    }
                    MXLogWarning(@"[MXKRoomDataSource][%p] resendEventWithEventId: Warning - Unable to resend room message of type: %@", self, msgType);
                }
            }
            else
            {
                // Resend the Matrix event by reusing the existing echo
                [_room sendMessageWithContent:event.content threadId:self.threadId localEcho:&event success:success failure:failure];
            }
        }
        else if ([msgType isEqualToString:kMXMessageTypeAudio])
        {
            // Check whether the sending failed while uploading the data.
            // If the content url corresponds to a upload id, the upload was not complete.
            NSString *contentURL = event.content[@"url"];
            if (!contentURL || ![contentURL hasPrefix:kMXMediaUploadIdPrefix])
            {
                // Resend the Matrix event by reusing the existing echo
                [_room sendMessageWithContent:event.content threadId:self.threadId localEcho:&event success:success failure:failure];
                return;
            }
            
            NSString *mimetype = event.content[@"info"][@"mimetype"];
            NSString *localFilePath = [MXMediaManager cachePathForMatrixContentURI:contentURL andType:mimetype inFolder:_roomId];
            NSURL *localFileURL = [NSURL URLWithString:localFilePath];
            
            if (![NSFileManager.defaultManager fileExistsAtPath:localFilePath]) {
                if (failure)
                {
                    failure([NSError errorWithDomain:MXKRoomDataSourceErrorDomain code:MXKRoomDataSourceErrorResendInvalidLocalFilePath userInfo:nil]);
                }
                MXLogWarning(@"[MXKRoomDataSource][%p] resendEventWithEventId: Warning - Unable to resend voice message, invalid file path.", self);
                return;
            }
            
            // Remove the local echo.
            [self removeEventWithEventId:eventId];
            
            if (event.isVoiceMessage) {
                // Voice message
                NSNumber *duration = event.content[kMXMessageContentKeyExtensibleAudioMSC1767][kMXMessageContentKeyExtensibleAudioDuration];
                NSArray<NSNumber *> *samples = event.content[kMXMessageContentKeyExtensibleAudioMSC1767][kMXMessageContentKeyExtensibleAudioWaveform];

                // Additional content params in case it is a voicebroacast chunk
                NSDictionary* additionalContentParams = nil;
                if (event.content[kMXEventRelationRelatesToKey] != nil && event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] != nil) {
                    additionalContentParams = @{
                        kMXEventRelationRelatesToKey: event.content[kMXEventRelationRelatesToKey],
                        VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType: event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType]
                    };
                }

                [self sendVoiceMessage:localFileURL additionalContentParams:additionalContentParams mimeType:mimetype duration:duration.doubleValue samples:samples success:success failure:failure];
            } else {
                [self sendAudioFile:localFileURL mimeType:mimetype success:success failure:failure];
            }
        }
        else if ([msgType isEqualToString:kMXMessageTypeVideo])
        {
            // Check whether the sending failed while uploading the data.
            // If the content url corresponds to a upload id, the upload was not complete.
            NSString *contentURL = event.content[@"url"];
            if (contentURL && [contentURL hasPrefix:kMXMediaUploadIdPrefix])
            {
                // TODO: Support resend on attached video when upload has been failed.
                MXLogDebug(@"[MXKRoomDataSource][%p] resendEventWithEventId: Warning - Unable to resend attached video (upload was not complete)", self);
                failure([NSError errorWithDomain:MXKRoomDataSourceErrorDomain code:MXKRoomDataSourceErrorResendInvalidMessageType userInfo:nil]);
            }
            else
            {
                // Resend the Matrix event by reusing the existing echo
                [_room sendMessageWithContent:event.content threadId:self.threadId localEcho:&event success:success failure:failure];
            }
        }
        else if ([msgType isEqualToString:kMXMessageTypeFile])
        {
            // Check whether the sending failed while uploading the data.
            // If the content url corresponds to a upload id, the upload was not complete.
            NSString *contentURL = event.content[@"url"];
            if (contentURL && [contentURL hasPrefix:kMXMediaUploadIdPrefix])
            {
                NSString *mimetype = nil;
                if (event.content[@"info"])
                {
                    mimetype = event.content[@"info"][@"mimetype"];
                }
                
                if (mimetype)
                {
                    // Restart sending the image from the beginning.
                    
                    // Remove the local echo
                    [self removeEventWithEventId:eventId];
                    
                    NSString *localFilePath = [MXMediaManager cachePathForMatrixContentURI:contentURL andType:mimetype inFolder:_roomId];
                    
                    [self sendFile:[NSURL fileURLWithPath:localFilePath isDirectory:NO] mimeType:mimetype success:success failure:failure];
                }
                else
                {
                    if (failure)
                    {
                        failure([NSError errorWithDomain:MXKRoomDataSourceErrorDomain code:MXKRoomDataSourceErrorResendGeneric userInfo:nil]);
                    }
                    MXLogWarning(@"[MXKRoomDataSource][%p] resendEventWithEventId: Warning - Unable to resend room message of type: %@", self, msgType);
                }
            }
            else
            {
                // Resend the Matrix event by reusing the existing echo
                [_room sendMessageWithContent:event.content threadId:self.threadId localEcho:&event success:success failure:failure];
            }
        }
        else
        {
            if (failure)
            {
                failure([NSError errorWithDomain:MXKRoomDataSourceErrorDomain code:MXKRoomDataSourceErrorResendInvalidMessageType userInfo:nil]);
            }
            MXLogWarning(@"[MXKRoomDataSource][%p] resendEventWithEventId: Warning - Unable to resend room message of type: %@", self, msgType);
        }
    }
    else
    {
        if (failure)
        {
            failure([NSError errorWithDomain:MXKRoomDataSourceErrorDomain code:MXKRoomDataSourceErrorResendInvalidMessageType userInfo:nil]);
        }
        MXLogWarning(@"[MXKRoomDataSource][%p] MXKRoomDataSource: Warning - Only resend of MXEventTypeRoomMessage is allowed. Event.type: %@", self, event.type);
    }
}


#pragma mark - Events management
- (MXEvent *)eventWithEventId:(NSString *)eventId
{
    MXEvent *theEvent;
    
    // First, retrieve the cell data hosting the event
    id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:eventId];
    if (bubbleData)
    {
        // Then look into the events in this cell
        for (MXEvent *event in bubbleData.events)
        {
            if ([event.eventId isEqualToString:eventId])
            {
                theEvent = event;
                break;
            }
        }
    }
    return theEvent;
}

- (void)removeEventWithEventId:(NSString *)eventId
{
    MXLogVerbose(@"[MXKRoomDataSource][%p] removeEventWithEventId: %@", self, eventId);
    
    // First, retrieve the cell data hosting the event
    id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:eventId];
    if (bubbleData)
    {
        NSUInteger remainingEvents;
        @synchronized (bubbleData)
        {
            remainingEvents = [bubbleData removeEvent:eventId];
        }
        
        // If there is no more events in the bubble, remove it
        if (0 == remainingEvents)
        {
            [self removeCellData:bubbleData];
        }

        // Remove the event from the outgoing messages storage
        [_room removeOutgoingMessage:eventId];
    
        // Update the delegate
        if (self.delegate)
        {
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
}

- (void)didReceiveReceiptEvent:(MXEvent *)receiptEvent roomState:(MXRoomState *)roomState
{
    // Do the processing on the same processing queue
    MXWeakify(self);
    dispatch_async(MXKRoomDataSource.processingQueue, ^{
        MXStrongifyAndReturnIfNil(self);

        // Remove the previous displayed read receipt for each user who sent a
        // new read receipt.
        // To implement it, we need to find the sender id of each new read receipt
        // among the read receipts array of all events in all bubbles.
        NSArray *readReceiptSenders = receiptEvent.readReceiptSenders;

        @synchronized(self->bubbles)
        {
            for (MXKRoomBubbleCellData *cellData in self->bubbles)
            {
                NSMutableDictionary<NSString* /* eventId */, NSArray<MXReceiptData*> *> *updatedCellDataReadReceipts = [NSMutableDictionary dictionary];

                NSDictionary<NSString*, NSArray<MXReceiptData*>*> *readReceiptsCopy = [cellData.readReceipts mutableDeepCopy];
                for (NSString *eventId in readReceiptsCopy)
                {
                    for (MXReceiptData *receiptData in readReceiptsCopy[eventId])
                    {
                        for (NSString *senderId in readReceiptSenders)
                        {
                            if ([receiptData.userId isEqualToString:senderId])
                            {
                                if (!updatedCellDataReadReceipts[eventId])
                                {
                                    updatedCellDataReadReceipts[eventId] = readReceiptsCopy[eventId];
                                }

                                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId!=%@", receiptData.userId];
                                updatedCellDataReadReceipts[eventId] = [updatedCellDataReadReceipts[eventId] filteredArrayUsingPredicate:predicate];
                                break;
                            }
                        }

                    }
                }

                // Flush found changed to the cell data
                for (NSString *eventId in updatedCellDataReadReceipts)
                {
                    if (updatedCellDataReadReceipts[eventId].count)
                    {
                        [self updateCellData:cellData withReadReceipts:updatedCellDataReadReceipts[eventId] forEventId:eventId];
                    }
                    else
                    {
                        [self updateCellData:cellData withReadReceipts:nil forEventId:eventId];
                    }
                }
            }
        }
        
        dispatch_group_t dispatchGroup = dispatch_group_create();

        // Update cell data we have received a read receipt for
        NSArray *readEventIds = receiptEvent.readReceiptEventIds;
        if (RiotSettings.shared.enableThreads)
        {
            NSArray *readThreadIds = receiptEvent.readReceiptThreadIds;
            for (int i = 0 ; i < readEventIds.count ; i++)
            {
                NSString *eventId = readEventIds[i];
                MXKRoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:eventId];
                if (cellData)
                {
                    if ([readThreadIds[i] isEqualToString:kMXEventUnthreaded])
                    {
                        // Unthreaded RR must be propagated through all threads.
                        [self.mxSession.threadingService allThreadsInRoomWithId:self.roomId onlyParticipated:NO completion:^(NSArray<id<MXThreadProtocol>> *threads) {
                            NSMutableArray *threadIds = [NSMutableArray arrayWithObject:kMXEventTimelineMain];
                            for (id<MXThreadProtocol> thread in threads)
                            {
                                [threadIds addObject:thread.id];
                            }
                            
                            for (NSString *threadId in threadIds)
                            {
                                @synchronized(self->bubbles)
                                {
                                    dispatch_group_enter(dispatchGroup);
                                    [self addReadReceiptsForEvent:eventId threadId:threadId inCellDatas:self->bubbles startingAtCellData:cellData completion:^{
                                        dispatch_group_leave(dispatchGroup);
                                    }];
                                }
                            }
                        }];
                    }
                    else
                    {
                        NSString *threadId = readThreadIds[i];
                        @synchronized(self->bubbles)
                        {
                            dispatch_group_enter(dispatchGroup);
                            [self addReadReceiptsForEvent:eventId threadId:threadId inCellDatas:self->bubbles startingAtCellData:cellData completion:^{
                                dispatch_group_leave(dispatchGroup);
                            }];
                        }
                    }
                }
            }
        }
        else
        {
            // If
            for (NSString *eventId in readEventIds)
            {
                MXKRoomBubbleCellData *cellData = [self cellDataOfEventWithEventId:eventId];
                @synchronized(self->bubbles)
                {
                    dispatch_group_enter(dispatchGroup);
                    [self addReadReceiptsForEvent:eventId threadId:kMXEventTimelineMain inCellDatas:self->bubbles startingAtCellData:cellData completion:^{
                        dispatch_group_leave(dispatchGroup);
                    }];
                }
            }
        }

        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (self.delegate)
            {
                [self.delegate dataSource:self didCellChange:nil];
            }
        });
    });
}

- (void)updateCellData:(MXKRoomBubbleCellData*)cellData withReadReceipts:(NSArray<MXReceiptData*>*)readReceipts forEventId:(NSString*)eventId
{
    cellData.readReceipts[eventId] = readReceipts;
    
    // Indicate that the text message layout should be recomputed.
    [cellData invalidateTextLayout];
}

- (void)handleUnsentMessages
{
    // Add the unsent messages at the end of the conversation
    NSArray<MXEvent*>* outgoingMessages = _room.outgoingMessages;
    
    [self.mxSession decryptEvents:outgoingMessages inTimeline:nil onComplete:^(NSArray<MXEvent *> *failedEvents) {
        
        for (MXEvent *outgoingMessage in outgoingMessages)
        {
            [self queueEventForProcessing:outgoingMessage withRoomState:self.roomState direction:MXTimelineDirectionForwards];
        }
        
        MXLogVerbose(@"[MXKRoomDataSource][%p] handleUnsentMessages: queued %tu events", self, outgoingMessages.count);
        
        [self processQueuedEvents:nil];
    }];
}

#pragma mark - Bubble collapsing

- (void)collapseRoomBubble:(id<MXKRoomBubbleCellDataStoring>)bubbleData collapsed:(BOOL)collapsed
{
    if (bubbleData.collapsed != collapsed)
    {
        id<MXKRoomBubbleCellDataStoring> nextBubbleData = bubbleData;
        do
        {
            nextBubbleData.collapsed = collapsed;
        }
        while ((nextBubbleData = nextBubbleData.nextCollapsableCellData));

        if (self.delegate)
        {
            // Reload all the table
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
}

#pragma mark - Private methods

- (void)replaceEvent:(MXEvent*)eventToReplace withEvent:(MXEvent*)event
{
    MXLogVerbose(@"[MXKRoomDataSource][%p] replaceEvent: %@ with: %@", self, eventToReplace.eventId, event.eventId);
    
    if (eventToReplace.isLocalEvent)
    {
        // Stop listening to the identifier change for the replaced event.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:eventToReplace];
    }
    
    // Retrieve the cell data hosting the replaced event
    id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:eventToReplace.eventId];
    if (!bubbleData)
    {
        return;
    }
    
    NSUInteger remainingEvents;
    @synchronized (bubbleData)
    {
        // Check whether the local echo is replaced or removed
        if (event)
        {
            remainingEvents = [bubbleData updateEvent:eventToReplace.eventId withEvent:event];
        }
        else
        {
            remainingEvents = [bubbleData removeEvent:eventToReplace.eventId];
        }
    }
    
    // Update bubbles mapping
    @synchronized (eventIdToBubbleMap)
    {
        // Remove the broken link from the map
        [eventIdToBubbleMap removeObjectForKey:eventToReplace.eventId];
        
        if (event && remainingEvents)
        {
            eventIdToBubbleMap[event.eventId] = bubbleData;
            
            if (event.isLocalEvent)
            {
                // Listen to the identifier change for the local events.
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localEventDidChangeIdentifier:) name:kMXEventDidChangeIdentifierNotification object:event];
            }
        }
    }
    
    // If there is no more events in the bubble, remove it
    if (0 == remainingEvents)
    {
        [self removeCellData:bubbleData];
    }

    // Update the delegate
    if (self.delegate)
    {
        [self.delegate dataSource:self didCellChange:nil];
    }
}

- (NSArray<NSIndexPath *> *)removeCellData:(id<MXKRoomBubbleCellDataStoring>)cellData
{
    NSMutableArray *deletedRows = [NSMutableArray array];
    
    MXLogVerbose(@"[MXKRoomDataSource][%p] removeCellData: %@", self, [cellData.events valueForKey:@"eventId"]);
    
    // Remove potential occurrences in bubble map
    @synchronized (eventIdToBubbleMap)
    {
        for (MXEvent *event in cellData.events)
        {
            [eventIdToBubbleMap removeObjectForKey:event.eventId];
            
            if (event.isLocalEvent)
            {
                // Stop listening to the identifier change for this event.
                [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:event];
            }
        }
    }
    
    // Check whether the adjacent bubbles can merge together
    @synchronized(bubbles)
    {
        NSUInteger index = [bubbles indexOfObject:cellData];
        if (index != NSNotFound)
        {
            [bubbles removeObjectAtIndex:index];
            [deletedRows addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            
            if (bubbles.count)
            {
                // Update flag in remaining data
                if (index == 0)
                {
                    // We removed here the first bubble.
                    // We have to update the 'isPaginationFirstBubble' and 'shouldHideSenderInformation' flags of the new first bubble.
                    id<MXKRoomBubbleCellDataStoring> firstCellData = bubbles.firstObject;
                    
                    firstCellData.isPaginationFirstBubble = ((self.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay) && firstCellData.date);
                    
                    // Keep visible the sender information by default,
                    // except if the bubble has no display (composed only by ignored events).
                    firstCellData.shouldHideSenderInformation = firstCellData.hasNoDisplay;
                }
                else if (index < bubbles.count)
                {
                    // We removed here a bubble which is not the before last.
                    id<MXKRoomBubbleCellDataStoring> cellData1 = bubbles[index-1];
                    id<MXKRoomBubbleCellDataStoring> cellData2 = bubbles[index];
                    
                    // Check first whether the neighbor bubbles can merge
                    Class class = [self cellDataClassForCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
                    if ([class instancesRespondToSelector:@selector(mergeWithBubbleCellData:)])
                    {
                        if ([cellData1 mergeWithBubbleCellData:cellData2])
                        {
                            [bubbles removeObjectAtIndex:index];
                            [deletedRows addObject:[NSIndexPath indexPathForRow:(index + 1) inSection:0]];
                            
                            cellData2 = nil;
                        }
                    }
                    
                    if (cellData2)
                    {
                        // Update its 'isPaginationFirstBubble' and 'shouldHideSenderInformation' flags
                        
                        // Pagination handling
                        if (self.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay && !cellData2.isPaginationFirstBubble)
                        {
                            // Check whether a new pagination starts on the second cellData
                            NSString *cellData1DateString = [self.eventFormatter dateStringFromDate:cellData1.date withTime:NO];
                            NSString *cellData2DateString = [self.eventFormatter dateStringFromDate:cellData2.date withTime:NO];
                            
                            if (!cellData1DateString)
                            {
                                cellData2.isPaginationFirstBubble = (cellData2DateString && cellData.isPaginationFirstBubble);
                            }
                            else
                            {
                                cellData2.isPaginationFirstBubble = (cellData2DateString && ![cellData2DateString isEqualToString:cellData1DateString]);
                            }
                        }
                        
                        // Check whether the sender information is relevant for this bubble.
                        // Check first if the bubble is not composed only by ignored events.
                        cellData2.shouldHideSenderInformation = cellData2.hasNoDisplay;
                        if (!cellData2.shouldHideSenderInformation && cellData2.isPaginationFirstBubble == NO)
                        {
                            // Check whether the neighbor bubbles have been sent by the same user.
                            cellData2.shouldHideSenderInformation = [cellData2 hasSameSenderAsBubbleCellData:cellData1];
                        }
                    }

                }
            }
        }
    }
    
    return deletedRows;
}

- (void)didMXRoomInitialSynced:(NSNotification *)notif
{
    // Refresh the room data source when the room has been initialSync'ed
    MXRoom *room = notif.object;
    if (self.mxSession == room.mxSession &&
        ([self.roomId isEqualToString:room.roomId] || [self.secondaryRoomId isEqualToString:room.roomId]))
    { 
        MXLogDebug(@"[MXKRoomDataSource][%p] didMXRoomInitialSynced for room: %@", self, room.roomId);
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXRoomInitialSyncNotification object:room];
        
        [self reload];
    }
}

- (void)eventDidChangeSentState:(NSNotification *)notif
{
    MXEvent *event = notif.object;
    if ([event.roomId isEqualToString:_roomId])
    {
        MXLogVerbose(@"[MXKRoomDataSource][%p] eventDidChangeSentState: %@, to: %tu", self, event.eventId, event.sentState);
        
        // Retrieve the cell data hosting the local echo
        id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:event.eventId];
        if (!bubbleData)
        {
            //  Initial state for local echos
            BOOL isInitial = event.isLocalEvent &&
                (event.sentState == MXEventSentStateSending || event.sentState == MXEventSentStateEncrypting);
            if (!isInitial)
            {
                MXLogWarning(@"[MXKRoomDataSource][%p] eventDidChangeSentState: Cannot find bubble data for event: %@", self, event.eventId);
            }
            return;
        }
        
        @synchronized (bubbleData)
        {
            [bubbleData updateEvent:event.eventId withEvent:event];
        }
        
        // Inform the delegate
        if (self.delegate && (self.secondaryRoom ? bubbles.count > 0 : YES))
        {
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
}

- (void)localEventDidChangeIdentifier:(NSNotification *)notif
{
    MXEvent *event = notif.object;
    NSString *previousId = notif.userInfo[kMXEventIdentifierKey];
    
    MXLogVerbose(@"[MXKRoomDataSource][%p] localEventDidChangeIdentifier from: %@ to: %@", self, previousId, event.eventId);
    
    if (event && previousId)
    {
        // Update bubbles mapping
        @synchronized (eventIdToBubbleMap)
        {
            id<MXKRoomBubbleCellDataStoring> bubbleData = eventIdToBubbleMap[previousId];
            if (bubbleData && event.eventId)
            {
                eventIdToBubbleMap[event.eventId] = bubbleData;
                [eventIdToBubbleMap removeObjectForKey:previousId];

                // The bubble data must use the final event id too
                [bubbleData updateEvent:previousId withEvent:event];
            }
        }
        
        if (!event.isLocalEvent)
        {
            // Stop listening to the identifier change when the event becomes an actual event.
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXEventDidChangeIdentifierNotification object:event];
        }
    }
}

- (void)eventDidDecrypt:(NSNotification *)notif
{
    MXEvent *event = notif.object;
    if ([event.roomId isEqualToString:_roomId] ||
        ([event.roomId isEqualToString:_secondaryRoomId] && [_secondaryRoomEventTypes containsObject:event.type]))
    {
        // Retrieve the cell data hosting the event
        id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:event.eventId];
        if (!bubbleData)
        {
            return;
        }

        // We need to update the data of the cell that displays the event.
        // The trickiest update is when the cell contains several events and the event
        // to update turns out to be an attachment.
        // In this case, we need to split the cell into several cells so that the attachment
        // has its own cell.
        if (bubbleData.events.count == 1 || ![_eventFormatter isSupportedAttachment:event])
        {
            // If the event is still a text, a simple update is enough
            // If the event is an attachment, it has already its own cell. Let the bubble
            // data handle the type change.
            @synchronized (bubbleData)
            {
                [bubbleData updateEvent:event.eventId withEvent:event];
            }
        }
        else
        {
            @synchronized (bubbleData)
            {
                BOOL eventIsFirstInBubble = NO;
                NSInteger bubbleDataIndex =  [bubbles indexOfObject:bubbleData];
                
                if (NSNotFound == bubbleDataIndex)
                {
                    // If bubbleData is not in bubbles there is nothing to update for this event, its not displayed.
                    return;
                }

                // We need to create a dedicated cell for the event attachment.
                // From the current bubble, remove the updated event and all events after.
                NSMutableArray<MXEvent*> *removedEvents;
                NSUInteger remainingEvents = [bubbleData removeEventsFromEvent:event.eventId removedEvents:&removedEvents];

                // If there is no more events in this bubble, remove it
                if (0 == remainingEvents)
                {
                    eventIsFirstInBubble = YES;
                    @synchronized (eventsToProcessSnapshot)
                    {
                        [bubbles removeObjectAtIndex:bubbleDataIndex];
                        bubbleDataIndex--;
                    }
                }

                // Create a dedicated bubble for the attachment
                if (removedEvents.count)
                {
                    Class class = [self cellDataClassForCellIdentifier:kMXKRoomBubbleCellDataIdentifier];

                    id<MXKRoomBubbleCellDataStoring> newBubbleData = [[class alloc] initWithEvent:removedEvents[0] andRoomState:self.roomState andRoomDataSource:self];

                    if (eventIsFirstInBubble)
                    {
                        // Apply same config as before
                        newBubbleData.isPaginationFirstBubble = bubbleData.isPaginationFirstBubble;
                        newBubbleData.shouldHideSenderInformation = bubbleData.shouldHideSenderInformation;
                    }
                    else
                    {
                        // This new bubble is not the first. Show nothing
                        newBubbleData.isPaginationFirstBubble = NO;
                        newBubbleData.shouldHideSenderInformation = YES;
                    }

                    // Update bubbles mapping
                    @synchronized (eventIdToBubbleMap)
                    {
                        eventIdToBubbleMap[event.eventId] = newBubbleData;
                    }

                    @synchronized (eventsToProcessSnapshot)
                    {
                        [bubbles insertObject:newBubbleData atIndex:bubbleDataIndex + 1];
                    }
                }

                // And put other cutted events in another bubble
                if (removedEvents.count > 1)
                {
                    Class class = [self cellDataClassForCellIdentifier:kMXKRoomBubbleCellDataIdentifier];

                    id<MXKRoomBubbleCellDataStoring> newBubbleData;
                    for (NSUInteger i = 1; i < removedEvents.count; i++)
                    {
                        MXEvent *removedEvent = removedEvents[i];
                        if (i == 1)
                        {
                            newBubbleData = [[class alloc] initWithEvent:removedEvent andRoomState:self.roomState andRoomDataSource:self];
                        }
                        else
                        {
                            [newBubbleData addEvent:removedEvent andRoomState:self.roomState];
                        }

                        // Update bubbles mapping
                        @synchronized (eventIdToBubbleMap)
                        {
                            eventIdToBubbleMap[removedEvent.eventId] = newBubbleData;
                        }
                    }

                    // Do not show the
                    newBubbleData.isPaginationFirstBubble = NO;
                    newBubbleData.shouldHideSenderInformation = YES;

                    @synchronized (eventsToProcessSnapshot)
                    {
                        [bubbles insertObject:newBubbleData atIndex:bubbleDataIndex + 2];
                    }
                }
            }
        }

        // Update the delegate
        if (self.delegate)
        {
            [self.delegate dataSource:self didCellChange:nil];
        }
    }
}

// Indicates whether an event has base requirements to allow actions (like reply, reactions, edit, etc.)
- (BOOL)canPerformActionOnEvent:(MXEvent*)event
{
    BOOL isSent = event.sentState == MXEventSentStateSent;
    
    if (!isSent) {
        return NO;
    }
    
    if (event.isTimelinePollEvent) {
        return YES;
    }
    
    // Specific case for voice broadcast event
    if (event.eventType == MXEventTypeCustom &&
        [event.type isEqualToString:VoiceBroadcastSettings.voiceBroadcastInfoContentKeyType]) {
        
        // Ensures that we only support reactions for a start event
        VoiceBroadcastInfo* voiceBroadcastInfo = [VoiceBroadcastInfo modelFromJSON: event.content];
        if ([VoiceBroadcastInfo isStartedFor: voiceBroadcastInfo.state]) {
            return YES;
        }
    }
    
    BOOL isRoomMessage = (event.eventType == MXEventTypeRoomMessage);
    
    if (!isRoomMessage) {
        return NO;
    }
    
    NSString *messageType = event.content[kMXMessageTypeKey];
    if (messageType == nil || [messageType isEqualToString:@"m.bad.encrypted"]) {
        return NO;
    }
    
    return YES;
}

- (void)setState:(MXKDataSourceState)newState
{
    if (self->state != newState)
    {
        self->state = newState;

        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSource:didStateChange:)])
        {
            [self.delegate dataSource:self didStateChange:self->state];
        }
    }
}

- (void)setSecondaryRoomId:(NSString *)secondaryRoomId
{
    if (_secondaryRoomId != secondaryRoomId)
    {
        _secondaryRoomId = secondaryRoomId;
        
        if (self.state == MXKDataSourceStateReady)
        {
            [self reload];
        }
    }
}

- (void)setSecondaryRoomEventTypes:(NSArray<MXEventTypeString> *)secondaryRoomEventTypes
{
    if (_secondaryRoomEventTypes != secondaryRoomEventTypes)
    {
        _secondaryRoomEventTypes = secondaryRoomEventTypes;
        
        if (self.state == MXKDataSourceStateReady)
        {
            [self reload];
        }
    }
}

#pragma mark - Asynchronous events processing
 + (dispatch_queue_t)processingQueue
{
    static dispatch_queue_t processingQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processingQueue = dispatch_queue_create("MXKRoomDataSource", DISPATCH_QUEUE_SERIAL);
    });

    return processingQueue;
}

- (void)queueEventForProcessing:(MXEvent*)event withRoomState:(MXRoomState*)roomState direction:(MXTimelineDirection)direction
{
    if (event.isLocalEvent)
    {
        MXLogVerbose(@"[MXKRoomDataSource][%p] queueEventForProcessing: %@", self, event.eventId);
    }
    
    if (![self shouldQueueEventForProcessing:event roomState:roomState direction:direction])
    {
        return;
    }
    
    MXKQueuedEvent *queuedEvent = [[MXKQueuedEvent alloc] initWithEvent:event andRoomState:roomState direction:direction];
    
    // Count queued events when the server sync is in progress
    if (self.mxSession.state == MXSessionStateSyncInProgress)
    {
        queuedEvent.serverSyncEvent = YES;
        _serverSyncEventCount++;
        
        if (_serverSyncEventCount == 1)
        {
            // Notify that sync process starts
            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKRoomDataSourceSyncStatusChanged object:self userInfo:nil];
        }
    }
    
    @synchronized(eventsToProcess)
    {
        [eventsToProcess addObject:queuedEvent];
        
        if (self.secondaryRoom)
        {
            //  use a stable sorting here, which means it won't change the order of events unless it has to.
            [eventsToProcess sortWithOptions:NSSortStable
                             usingComparator:^NSComparisonResult(MXKQueuedEvent * _Nonnull event1, MXKQueuedEvent * _Nonnull event2) {
                return [event2.eventDate compare:event1.eventDate];
            }];
        }
    }
}

- (BOOL)canPaginate:(MXTimelineDirection)direction
{
    if (_secondaryTimeline)
    {
        if (![_timeline canPaginate:direction] && ![_secondaryTimeline canPaginate:direction])
        {
            return NO;
        }
    }
    else
    {
        if (![_timeline canPaginate:direction])
        {
            return NO;
        }
    }
    
    if (direction == MXTimelineDirectionBackwards && self.shouldStopBackPagination)
    {
        return NO;
    }
    
    return YES;
}

// Check for undecryptable messages that were sent while the user was not in the room.
- (void)checkForPreJoinUTDWithEvent:(MXEvent*)event roomState:(MXRoomState*)roomState
{
    // Only check for encrypted rooms
    if (!self.room.summary.isEncrypted)
    {
        return;
    }
    
    // Back pagination is stopped do not check for other pre join events
    if (self.shouldStopBackPagination)
    {
        return;
    }
    
    // if we reach a UTD and flag is set, hide previous encrypted messages and stop back-paginating
    if (event.eventType == MXEventTypeRoomEncrypted
        && [event.decryptionError.domain isEqualToString:MXDecryptingErrorDomain]
        && self.shouldPreventBackPaginationOnPreviousUTDEvent)
    {
        self.shouldStopBackPagination = YES;
        return;
    }
    
    self.shouldStopBackPagination = NO;
    
    if (event.eventType != MXEventTypeRoomMember)
    {
        return;
    }
    
    NSString *userId = event.stateKey;
    
    // Only check "m.room.member" event for current user
    if (![userId isEqualToString:self.mxSession.myUserId])
    {
        return;
    }
    
    BOOL shouldPreventBackPaginationOnPreviousUTDEvent = NO;
    
    MXRoomMember *member = [roomState.members memberWithUserId:userId];
    
    if (member)
    {
        switch (member.membership) {
            case MXMembershipJoin:
            {
                // if we reach a join event for the user:
                //  - if prev-content is invite, continue back-paginating
                //  - if prev-content is join (was just an avatar or displayname change), continue back-paginating
                //  - otherwise, set a flag and continue back-paginating
                
                NSString *previousMemberhsip = event.prevContent[@"membership"];
                
                BOOL isPrevContentAnInvite = [previousMemberhsip isEqualToString:@"invite"];
                BOOL isPrevContentAJoin = [previousMemberhsip isEqualToString:@"join"];
                
                if (!(isPrevContentAnInvite || isPrevContentAJoin))
                {
                    shouldPreventBackPaginationOnPreviousUTDEvent = YES;
                }
            }
                break;
            case MXMembershipInvite:
                // if we reach an invite event for the user, set flag and continue back-paginating
                shouldPreventBackPaginationOnPreviousUTDEvent = YES;
                break;
            default:
                break;
        }
    }
    
    self.shouldPreventBackPaginationOnPreviousUTDEvent = shouldPreventBackPaginationOnPreviousUTDEvent;
}

- (BOOL)checkBing:(MXEvent*)event
{
    BOOL isHighlighted = NO;
    
    // read receipts have no rule
    if (![event.type isEqualToString:kMXEventTypeStringReceipt]) {
        // Check if we should bing this event
        MXPushRule *rule = [self.mxSession.notificationCenter ruleMatchingEvent:event roomState:self.roomState];
        if (rule)
        {
            // Check whether is there an highlight tweak on it
            for (MXPushRuleAction *ruleAction in rule.actions)
            {
                if (ruleAction.actionType == MXPushRuleActionTypeSetTweak)
                {
                    if ([ruleAction.parameters[@"set_tweak"] isEqualToString:@"highlight"])
                    {
                        // Check the highlight tweak "value"
                        // If not present, highlight. Else check its value before highlighting
                        if (nil == ruleAction.parameters[@"value"] || YES == [ruleAction.parameters[@"value"] boolValue])
                        {
                            isHighlighted = YES;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    event.mxkIsHighlighted = isHighlighted;
    return isHighlighted;
}

- (void)processQueuedEvents:(void (^)(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb))onComplete
{
    MXWeakify(self);
    
    // Do the processing on the processing queue
    dispatch_async(MXKRoomDataSource.processingQueue, ^{
        
        MXStrongifyAndReturnIfNil(self);
        
        // Note: As this block is always called from the same processing queue,
        // only one batch process is done at a time. Thus, an event cannot be
        // processed twice
        
        // Snapshot queued events to avoid too long lock.
        @synchronized(self->eventsToProcess)
        {
            if (self->eventsToProcess.count)
            {
                self->eventsToProcessSnapshot = self->eventsToProcess;
                if (self.secondaryRoom)
                {
                    @synchronized(self->bubbles)
                    {
                        [self->bubblesSnapshot removeAllObjects];
                    }
                }
                else
                {
                    self->eventsToProcess = [NSMutableArray array];
                }
            }
        }

        NSUInteger serverSyncEventCount = 0;
        NSUInteger addedHistoryCellCount = 0;
        NSUInteger addedLiveCellCount = 0;
        
        dispatch_group_t dispatchGroup = dispatch_group_create();

        // Lock on `eventsToProcessSnapshot` to suspend reload or destroy during the process.
        @synchronized(self->eventsToProcessSnapshot)
        {
            // Is there events to process?
            // The list can be empty because several calls of processQueuedEvents may be processed
            // in one pass in the processingQueue
            if (self->eventsToProcessSnapshot.count)
            {
                // Make a quick copy of changing data to avoid to lock it too long time
                @synchronized(self->bubbles)
                {
                    self->bubblesSnapshot = [self->bubbles mutableCopy];
                }

                NSMutableSet<id<MXKRoomBubbleCellDataStoring>> *collapsingCellDataSeriess = [NSMutableSet set];

                for (MXKQueuedEvent *queuedEvent in self->eventsToProcessSnapshot)
                {
                    @synchronized (self->eventIdToBubbleMap)
                    {
                        //  Check whether the event processed before
                        if (self->eventIdToBubbleMap[queuedEvent.event.eventId])
                        {
                            MXLogVerbose(@"[MXKRoomDataSource][%p] processQueuedEvents: Skip event: %@, state: %tu", self, queuedEvent.event.eventId, queuedEvent.event.sentState);
                            continue;
                        }
                    }
                    
                    @autoreleasepool
                    {
                        // Count events received while the server sync was in progress
                        if (queuedEvent.serverSyncEvent)
                        {
                            serverSyncEventCount ++;
                        }

                        // Check whether the event must be highlighted
                        [self checkBing:queuedEvent.event];

                        // Retrieve the MXKCellData class to manage the data
                        Class class = [self cellDataClassForCellIdentifier:kMXKRoomBubbleCellDataIdentifier];
                        NSAssert([class conformsToProtocol:@protocol(MXKRoomBubbleCellDataStoring)], @"MXKRoomDataSource only manages MXKCellData that conforms to MXKRoomBubbleCellDataStoring protocol");

                        BOOL eventManaged = NO;
                        BOOL updatedBubbleDataHadNoDisplay = NO;
                        id<MXKRoomBubbleCellDataStoring> bubbleData;
                        if ([class instancesRespondToSelector:@selector(addEvent:andRoomState:)] && 0 < self->bubblesSnapshot.count)
                        {
                            // Try to concatenate the event to the last or the oldest bubble?
                            if (queuedEvent.direction == MXTimelineDirectionBackwards)
                            {
                                bubbleData = self->bubblesSnapshot.firstObject;
                            }
                            else
                            {
                                bubbleData = self->bubblesSnapshot.lastObject;
                            }

                            @synchronized (bubbleData)
                            {
                                updatedBubbleDataHadNoDisplay = bubbleData.hasNoDisplay;
                                eventManaged = [bubbleData addEvent:queuedEvent.event andRoomState:queuedEvent.state];
                            }
                        }

                        if (NO == eventManaged)
                        {
                            // The event has not been concatenated to an existing cell, create a new bubble for this event
                            bubbleData = [[class alloc] initWithEvent:queuedEvent.event andRoomState:queuedEvent.state andRoomDataSource:self];
                            if (!bubbleData)
                            {
                                // The event is ignored
                                continue;
                            }

                            // Check cells collapsing
                            if (bubbleData.hasAttributedTextMessage)
                            {
                                if (bubbleData.collapsable)
                                {
                                    if (queuedEvent.direction == MXTimelineDirectionBackwards)
                                    {
                                        // Try to collapse it with the series at the start of self.bubbles
                                        if (self->collapsableSeriesAtStart && [self->collapsableSeriesAtStart collapseWith:bubbleData])
                                        {
                                            // bubbleData becomes the oldest cell data of the current series
                                            self->collapsableSeriesAtStart.prevCollapsableCellData = bubbleData;
                                            bubbleData.nextCollapsableCellData = self->collapsableSeriesAtStart;

                                            // The new cell must have the collapsed state as the series
                                            bubbleData.collapsed = self->collapsableSeriesAtStart.collapsed;

                                            // Release data of the previous header
                                            self->collapsableSeriesAtStart.collapseState = nil;
                                            self->collapsableSeriesAtStart.collapsedAttributedTextMessage = nil;
                                            [collapsingCellDataSeriess removeObject:self->collapsableSeriesAtStart];

                                            // And keep a ref of data for the new start of the series
                                            self->collapsableSeriesAtStart = bubbleData;
                                            self->collapsableSeriesAtStart.collapseState = queuedEvent.state;
                                            [collapsingCellDataSeriess addObject:self->collapsableSeriesAtStart];
                                        }
                                        else
                                        {
                                            // This is a ending point for a new collapsable series of cells
                                            self->collapsableSeriesAtStart = bubbleData;
                                            self->collapsableSeriesAtStart.collapseState = queuedEvent.state;
                                            [collapsingCellDataSeriess addObject:self->collapsableSeriesAtStart];
                                        }
                                    }
                                    else
                                    {
                                        // Try to collapse it with the series at the end of self.bubbles
                                        if (self->collapsableSeriesAtEnd && [self->collapsableSeriesAtEnd collapseWith:bubbleData])
                                        {
                                            // Put bubbleData at the series tail
                                            // Find the tail
                                            id<MXKRoomBubbleCellDataStoring> tailBubbleData = self->collapsableSeriesAtEnd;
                                            while (tailBubbleData.nextCollapsableCellData)
                                            {
                                                tailBubbleData = tailBubbleData.nextCollapsableCellData;
                                            }

                                            tailBubbleData.nextCollapsableCellData = bubbleData;
                                            bubbleData.prevCollapsableCellData = tailBubbleData;

                                            // The new cell must have the collapsed state as the series
                                            bubbleData.collapsed = tailBubbleData.collapsed;

                                            // If the start of the collapsible series stems from an event in a different processing
                                            // batch, we need to track it here so that we can update the summary string later
                                            if (![collapsingCellDataSeriess containsObject:self->collapsableSeriesAtEnd]) {
                                                [collapsingCellDataSeriess addObject:self->collapsableSeriesAtEnd];
                                            }
                                        }
                                        else
                                        {
                                            // This is a starting point for a new collapsable series of cells
                                            self->collapsableSeriesAtEnd = bubbleData;
                                            self->collapsableSeriesAtEnd.collapseState = queuedEvent.state;
                                            [collapsingCellDataSeriess addObject:self->collapsableSeriesAtEnd];
                                        }
                                    }
                                }
                                else
                                {
                                    // The new bubble is not collapsable.
                                    // We can close one border of the current series being built (if any)
                                    if (queuedEvent.direction == MXTimelineDirectionBackwards && self->collapsableSeriesAtStart)
                                    {
                                        // This is the begin border of the series
                                        self->collapsableSeriesAtStart = nil;
                                    }
                                    else if (queuedEvent.direction == MXTimelineDirectionForwards && self->collapsableSeriesAtEnd)
                                    {
                                        // This is the end border of the series
                                        self->collapsableSeriesAtEnd = nil;
                                    }
                                }
                            }

                            if (queuedEvent.direction == MXTimelineDirectionBackwards)
                            {
                                // The new bubble data will be inserted at first position.
                                // We have to update the 'isPaginationFirstBubble' and 'shouldHideSenderInformation' flags of the current first bubble.

                                // Pagination handling
                                if ((self.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay) && bubbleData.date)
                                {
                                    // A new pagination starts with this new bubble data
                                    bubbleData.isPaginationFirstBubble = YES;

                                    // Check whether the current first displayed pagination title is still relevant.
                                    if (self->bubblesSnapshot.count)
                                    {
                                        NSInteger index = 0;
                                        id<MXKRoomBubbleCellDataStoring> previousFirstBubbleDataWithDate;
                                        NSString *firstBubbleDateString;
                                        while (index < self->bubblesSnapshot.count)
                                        {
                                            previousFirstBubbleDataWithDate = self->bubblesSnapshot[index++];
                                            firstBubbleDateString = [self.eventFormatter dateStringFromDate:previousFirstBubbleDataWithDate.date withTime:NO];
                                            
                                            if (firstBubbleDateString)
                                            {
                                                break;
                                            }
                                        }
                                        
                                        if (firstBubbleDateString)
                                        {
                                            NSString *bubbleDateString = [self.eventFormatter dateStringFromDate:bubbleData.date withTime:NO];
                                            previousFirstBubbleDataWithDate.isPaginationFirstBubble = (bubbleDateString && ![firstBubbleDateString isEqualToString:bubbleDateString]);
                                        }
                                    }
                                }
                                else
                                {
                                    bubbleData.isPaginationFirstBubble = NO;
                                }

                                // Sender information are required for this new first bubble data,
                                // except if the bubble has no display (composed only by ignored events).
                                bubbleData.shouldHideSenderInformation = bubbleData.hasNoDisplay;

                                // Check whether this information is relevant for the current first bubble.
                                if (!bubbleData.shouldHideSenderInformation && self->bubblesSnapshot.count)
                                {
                                    id<MXKRoomBubbleCellDataStoring> previousFirstBubbleData = self->bubblesSnapshot.firstObject;

                                    if (previousFirstBubbleData.isPaginationFirstBubble == NO)
                                    {
                                        // Check whether the current first bubble has been sent by the same user.
                                        previousFirstBubbleData.shouldHideSenderInformation |= [previousFirstBubbleData hasSameSenderAsBubbleCellData:bubbleData];
                                    }
                                }

                                // Insert the new bubble data in first position
                                [self->bubblesSnapshot insertObject:bubbleData atIndex:0];
                                
                                addedHistoryCellCount++;
                            }
                            else
                            {
                                // The new bubble data will be added at the last position
                                // We have to update its 'isPaginationFirstBubble' and 'shouldHideSenderInformation' flags according to the previous last bubble.

                                // Pagination handling
                                if (self.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay)
                                {
                                    // Check whether a new pagination starts at this bubble
                                    NSString *bubbleDateString = [self.eventFormatter dateStringFromDate:bubbleData.date withTime:NO];
                                    
                                    // Look for the current last bubble with date
                                    NSInteger index = self->bubblesSnapshot.count;
                                    NSString *lastBubbleDateString;
                                    while (index--)
                                    {
                                        id<MXKRoomBubbleCellDataStoring> previousLastBubbleData = self->bubblesSnapshot[index];
                                        lastBubbleDateString = [self.eventFormatter dateStringFromDate:previousLastBubbleData.date withTime:NO];
                                        
                                        if (lastBubbleDateString)
                                        {
                                            break;
                                        }
                                    }
                                    
                                    if (lastBubbleDateString)
                                    {
                                        bubbleData.isPaginationFirstBubble = (bubbleDateString && ![bubbleDateString isEqualToString:lastBubbleDateString]);
                                    }
                                    else
                                    {
                                        bubbleData.isPaginationFirstBubble = (bubbleDateString != nil);
                                    }
                                }
                                else
                                {
                                    bubbleData.isPaginationFirstBubble = NO;
                                }

                                // Check whether the sender information is relevant for this new bubble.
                                bubbleData.shouldHideSenderInformation = bubbleData.hasNoDisplay;
                                if (!bubbleData.shouldHideSenderInformation && self->bubblesSnapshot.count && (bubbleData.isPaginationFirstBubble == NO))
                                {
                                    // Check whether the previous bubble has been sent by the same user.
                                    id<MXKRoomBubbleCellDataStoring> previousLastBubbleData = self->bubblesSnapshot.lastObject;
                                    bubbleData.shouldHideSenderInformation = [bubbleData hasSameSenderAsBubbleCellData:previousLastBubbleData];
                                }

                                // Insert the new bubble in last position
                                [self->bubblesSnapshot addObject:bubbleData];
                                
                                addedLiveCellCount++;
                            }
                        }
                        else if (updatedBubbleDataHadNoDisplay && !bubbleData.hasNoDisplay)
                        {
                            // Here the event has been added in an existing bubble data which had no display,
                            // and the added event provides a display to this bubble data.
                            if (queuedEvent.direction == MXTimelineDirectionBackwards)
                            {
                                // The bubble is the first one.
                                
                                // Pagination handling
                                if ((self.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay) && bubbleData.date)
                                {
                                    // A new pagination starts with this bubble data
                                    bubbleData.isPaginationFirstBubble = YES;
                                    
                                    // Look for the first next bubble with date to check whether its pagination title is still relevant.
                                    if (self->bubblesSnapshot.count)
                                    {
                                        NSInteger index = 1;
                                        id<MXKRoomBubbleCellDataStoring> nextBubbleDataWithDate;
                                        NSString *firstNextBubbleDateString;
                                        while (index < self->bubblesSnapshot.count)
                                        {
                                            nextBubbleDataWithDate = self->bubblesSnapshot[index++];
                                            firstNextBubbleDateString = [self.eventFormatter dateStringFromDate:nextBubbleDataWithDate.date withTime:NO];
                                            
                                            if (firstNextBubbleDateString)
                                            {
                                                break;
                                            }
                                        }
                                        
                                        if (firstNextBubbleDateString)
                                        {
                                            NSString *bubbleDateString = [self.eventFormatter dateStringFromDate:bubbleData.date withTime:NO];
                                            nextBubbleDataWithDate.isPaginationFirstBubble = (bubbleDateString && ![firstNextBubbleDateString isEqualToString:bubbleDateString]);
                                        }
                                    }
                                }
                                else
                                {
                                    bubbleData.isPaginationFirstBubble = NO;
                                }
                                
                                // Sender information are required for this new first bubble data
                                bubbleData.shouldHideSenderInformation = NO;
                                
                                // Check whether this information is still relevant for the next bubble.
                                if (self->bubblesSnapshot.count > 1)
                                {
                                    id<MXKRoomBubbleCellDataStoring> nextBubbleData = self->bubblesSnapshot[1];
                                    
                                    if (nextBubbleData.isPaginationFirstBubble == NO)
                                    {
                                        // Check whether the current first bubble has been sent by the same user.
                                        nextBubbleData.shouldHideSenderInformation |= [nextBubbleData hasSameSenderAsBubbleCellData:bubbleData];
                                    }
                                }
                            }
                            else
                            {
                                // The bubble data is the last one
                                
                                // Pagination handling
                                if (self.bubblesPagination == MXKRoomDataSourceBubblesPaginationPerDay)
                                {
                                    // Check whether a new pagination starts at this bubble
                                    NSString *bubbleDateString = [self.eventFormatter dateStringFromDate:bubbleData.date withTime:NO];
                                    
                                    // Look for the first previous bubble with date
                                    NSInteger index = self->bubblesSnapshot.count - 1;
                                    NSString *firstPreviousBubbleDateString;
                                    while (index--)
                                    {
                                        id<MXKRoomBubbleCellDataStoring> previousBubbleData = self->bubblesSnapshot[index];
                                        firstPreviousBubbleDateString = [self.eventFormatter dateStringFromDate:previousBubbleData.date withTime:NO];
                                        
                                        if (firstPreviousBubbleDateString)
                                        {
                                            break;
                                        }
                                    }
                                    
                                    if (firstPreviousBubbleDateString)
                                    {
                                        bubbleData.isPaginationFirstBubble = (bubbleDateString && ![bubbleDateString isEqualToString:firstPreviousBubbleDateString]);
                                    }
                                    else
                                    {
                                        bubbleData.isPaginationFirstBubble = (bubbleDateString != nil);
                                    }
                                }
                                else
                                {
                                    bubbleData.isPaginationFirstBubble = NO;
                                }
                                
                                // Check whether the sender information is relevant for this new bubble.
                                bubbleData.shouldHideSenderInformation = NO;
                                if (self->bubblesSnapshot.count && (bubbleData.isPaginationFirstBubble == NO))
                                {
                                    // Check whether the previous bubble has been sent by the same user.
                                    NSInteger index = self->bubblesSnapshot.count - 1;
                                    if (index--)
                                    {
                                        id<MXKRoomBubbleCellDataStoring> previousBubbleData = self->bubblesSnapshot[index];
                                        bubbleData.shouldHideSenderInformation = [bubbleData hasSameSenderAsBubbleCellData:previousBubbleData];
                                    }
                                }
                            }
                        }

                        [self updateCellDataReactions:bubbleData forEventId:queuedEvent.event.eventId];

                        // Store event-bubble link to the map
                        @synchronized (self->eventIdToBubbleMap)
                        {
                            self->eventIdToBubbleMap[queuedEvent.event.eventId] = bubbleData;
                        }
                        
                        if (queuedEvent.event.isLocalEvent)
                        {
                            // Listen to the identifier change for the local events.
                            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localEventDidChangeIdentifier:) name:kMXEventDidChangeIdentifierNotification object:queuedEvent.event];
                        }
                    }
                }

                for (MXKQueuedEvent *queuedEvent in self->eventsToProcessSnapshot)
                {
                    @autoreleasepool
                    {
                        dispatch_group_enter(dispatchGroup);
                        [self addReadReceiptsForEvent:queuedEvent.event.eventId
                                             threadId:queuedEvent.event.threadId
                                          inCellDatas:self->bubblesSnapshot
                                   startingAtCellData:self->eventIdToBubbleMap[queuedEvent.event.eventId] completion:^{
                            dispatch_group_leave(dispatchGroup);
                        }];
                    }
                }

                // Check if all cells of self.bubbles belongs to a single collapse series.
                // In this case, collapsableSeriesAtStart and collapsableSeriesAtEnd must be equal
                // in order to handle next forward or backward pagination.
                if (self->collapsableSeriesAtStart && self->collapsableSeriesAtStart == self->bubbles.firstObject)
                {
                    // Find the tail
                    id<MXKRoomBubbleCellDataStoring> tailBubbleData = self->collapsableSeriesAtStart;
                    while (tailBubbleData.nextCollapsableCellData)
                    {
                        tailBubbleData = tailBubbleData.nextCollapsableCellData;
                    }

                    if (tailBubbleData == self->bubbles.lastObject)
                    {
                        self->collapsableSeriesAtEnd = self->collapsableSeriesAtStart;
                    }
                }
                else if (self->collapsableSeriesAtEnd)
                {
                    // Find the start
                    id<MXKRoomBubbleCellDataStoring> startBubbleData = self->collapsableSeriesAtEnd;
                    while (startBubbleData.prevCollapsableCellData)
                    {
                        startBubbleData = startBubbleData.prevCollapsableCellData;
                    }

                    if (startBubbleData == self->bubbles.firstObject)
                    {
                        self->collapsableSeriesAtStart = self->collapsableSeriesAtEnd;
                    }
                }

                // Compose (= compute collapsedAttributedTextMessage) of collapsable seriess
                for (id<MXKRoomBubbleCellDataStoring> bubbleData in collapsingCellDataSeriess)
                {
                    // Get all events of the series
                    NSMutableArray<MXEvent*> *events = [NSMutableArray array];
                    id<MXKRoomBubbleCellDataStoring> nextBubbleData = bubbleData;
                    do
                    {
                        [events addObjectsFromArray:nextBubbleData.events];
                    }
                    while ((nextBubbleData = nextBubbleData.nextCollapsableCellData));

                    // Build the summary string for the series
                    bubbleData.collapsedAttributedTextMessage = [self.eventFormatter attributedStringFromEvents:events
                                                                                                  withRoomState:bubbleData.collapseState
                                                                                             andLatestRoomState:self.roomState
                                                                                                          error:nil];

                    // Release collapseState objects, even the one of collapsableSeriesAtStart.
                    // We do not need to keep its state because if an collapsable event comes before collapsableSeriesAtStart,
                    // we will take the room state of this event.
                    if (bubbleData != self->collapsableSeriesAtEnd)
                    {
                        bubbleData.collapseState = nil;
                    }
                }
            }
            self->eventsToProcessSnapshot = nil;
        }
        
        // Check whether some events have been processed
        if (self->bubblesSnapshot)
        {
            // Updated data can be displayed now
            // Block MXKRoomDataSource.processingQueue while the processing is finalised on the main thread
            dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                // Check whether self has not been reloaded or destroyed
                if (self.state == MXKDataSourceStateReady && self->bubblesSnapshot)
                {
                    if (self.serverSyncEventCount)
                    {
                        self->_serverSyncEventCount -= serverSyncEventCount;
                        if (!self.serverSyncEventCount)
                        {
                            // Notify that sync process ends
                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKRoomDataSourceSyncStatusChanged object:self userInfo:nil];
                        }
                    }
                    if (self.secondaryRoom) {
                        [self->bubblesSnapshot sortWithOptions:NSSortStable
                                               usingComparator:^NSComparisonResult(MXKRoomBubbleCellData * _Nonnull bubbleData1, MXKRoomBubbleCellData * _Nonnull bubbleData2) {
                            if (bubbleData1.date)
                            {
                                if (bubbleData2.date)
                                {
                                    return [bubbleData1.date compare:bubbleData2.date];
                                }
                                else
                                {
                                    return NSOrderedDescending;
                                }
                            }
                            else
                            {
                                if (bubbleData2.date)
                                {
                                    return NSOrderedAscending;
                                }
                                else
                                {
                                    return NSOrderedSame;
                                }
                            }
                        }];
                    }
                    self->bubbles = self->bubblesSnapshot;
                    self->bubblesSnapshot = nil;
                    
                    if (self.delegate)
                    {
                        [self.delegate dataSource:self didCellChange:nil];
                    }
                    else
                    {
                        // Check the memory usage of the data source. Reload it if the cache is too huge.
                        [self limitMemoryUsage:self.maxBackgroundCachedBubblesCount];
                    }
                }
                
                // Inform about the end if requested
                if (onComplete)
                {
                    onComplete(addedHistoryCellCount, addedLiveCellCount);
                }
            });
        }
        else
        {
            // No new event has been added, we just inform about the end if requested.
            if (onComplete)
            {
                dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
                    onComplete(0, 0);
                });
            }
        }
    });
}

/**
 Add the read receipts of an event into the timeline (which is in array of cell datas)

 If the event is not displayed, read receipts will be added to a previous displayed message.

 @param eventId the id of the event.
 @param threadId the Id of the thread related of the event.
 @param cellDatas the working array of cell datas.
 @param cellData the original cell data the event belongs to.
 @param completion completion block
 */
- (void)addReadReceiptsForEvent:(NSString*)eventId
                       threadId:(NSString *)threadId
                    inCellDatas:(NSArray<id<MXKRoomBubbleCellDataStoring>>*)cellDatas
             startingAtCellData:(id<MXKRoomBubbleCellDataStoring>)cellData
                     completion:(void (^)(void))completion
{
    if (self.showBubbleReceipts)
    {
        if (self.room)
        {
            [self.room getEventReceipts:eventId threadId:threadId sorted:YES completion:^(NSArray<MXReceiptData *> * _Nonnull readReceipts) {
                if (readReceipts.count)
                {
                    NSInteger cellDataIndex = [cellDatas indexOfObject:cellData];
                    if (cellDataIndex != NSNotFound)
                    {
                        [self addReadReceipts:readReceipts forEvent:eventId inCellDatas:cellDatas atCellDataIndex:cellDataIndex];
                    }
                }
                
                if (!RiotSettings.shared.enableThreads)
                {
                    // If threads are disabled, we may have several threaded RR with same userId
                    // but different threadId within the same timeline.
                    // We just need to keep the latest one.
                    [self clearDuplicatedReadReceiptsInCellDatas:cellDatas];
                }

                if (completion)
                {
                    completion();
                }
            }];
        }
        else if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }
    else if (completion)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    }
}

- (void)addReadReceipts:(NSArray<MXReceiptData*> *)readReceipts forEvent:(NSString*)eventId inCellDatas:(NSArray<id<MXKRoomBubbleCellDataStoring>>*)cellDatas atCellDataIndex:(NSInteger)cellDataIndex
{
    id<MXKRoomBubbleCellDataStoring> cellData = cellDatas[cellDataIndex];

    if ([cellData isKindOfClass:MXKRoomBubbleCellData.class])
    {
        MXKRoomBubbleCellData *roomBubbleCellData = (MXKRoomBubbleCellData*)cellData;

        BOOL areReadReceiptsAssigned = NO;
        for (MXKRoomBubbleComponent *component in roomBubbleCellData.bubbleComponents.reverseObjectEnumerator)
        {
            if (component.attributedTextMessage)
            {
                if (roomBubbleCellData.readReceipts[component.event.eventId])
                {
                    NSArray<MXReceiptData*> *currentReadReceipts = roomBubbleCellData.readReceipts[component.event.eventId];
                    NSMutableArray<MXReceiptData*> *newReadReceipts = [NSMutableArray arrayWithArray:currentReadReceipts];
                    for (MXReceiptData *readReceipt in readReceipts)
                    {
                        BOOL alreadyHere = NO;
                        for (MXReceiptData *currentReadReceipt in currentReadReceipts)
                        {
                            if ([readReceipt.userId isEqualToString:currentReadReceipt.userId])
                            {
                                alreadyHere = YES;
                                break;
                            }
                        }

                        if (!alreadyHere)
                        {
                            [newReadReceipts addObject:readReceipt];
                        }
                    }
                    [self updateCellData:roomBubbleCellData withReadReceipts:newReadReceipts forEventId:component.event.eventId];
                }
                else
                {
                    [self updateCellData:roomBubbleCellData withReadReceipts:readReceipts forEventId:component.event.eventId];
                }
                areReadReceiptsAssigned = YES;
                break;
            }

            MXLogDebug(@"[MXKRoomDataSource][%p] addReadReceipts: Read receipts for an event(%@) that is not displayed", self, eventId);
        }

        if (!areReadReceiptsAssigned)
        {
            MXLogDebug(@"[MXKRoomDataSource][%p] addReadReceipts: Try to attach read receipts to an older message: %@", self, eventId);

            // Try to assign RRs to a previous cell data
            if (cellDataIndex >= 1)
            {
                [self addReadReceipts:readReceipts forEvent:eventId inCellDatas:cellDatas atCellDataIndex:cellDataIndex - 1];
            }
            else
            {
                MXLogDebug(@"[MXKRoomDataSource][%p] addReadReceipts: Fail to attach read receipts for an event(%@)", self, eventId);
            }
        }
    }
}

/**
 Clear all potential duplicated RR with same user ID within a given list of cell data.
 
 This is needed for client with threads disabled in order to clean threaded RRs.
 
 @param cellDatas the working array of cell datas.
 */
- (void)clearDuplicatedReadReceiptsInCellDatas:(NSArray<id<MXKRoomBubbleCellDataStoring>>*)cellDatas
{
    NSMutableSet<NSString *> *seenUserIds = [NSMutableSet set];
    for (id<MXKRoomBubbleCellDataStoring> cellData in cellDatas.reverseObjectEnumerator)
    {
        if ([cellData isKindOfClass:MXKRoomBubbleCellData.class])
        {
            MXKRoomBubbleCellData *roomBubbleCellData = (MXKRoomBubbleCellData*)cellData;

            for (MXKRoomBubbleComponent *component in roomBubbleCellData.bubbleComponents)
            {
                if (component.attributedTextMessage)
                {
                    if (roomBubbleCellData.readReceipts[component.event.eventId])
                    {
                        NSArray<MXReceiptData*> *currentReadReceipts = roomBubbleCellData.readReceipts[component.event.eventId];
                        NSMutableArray<MXReceiptData*> *newReadReceipts = [NSMutableArray array];
                        for (MXReceiptData *readReceipt in currentReadReceipts)
                        {
                            if (![seenUserIds containsObject:readReceipt.userId])
                            {
                                [newReadReceipts addObject:readReceipt];
                                [seenUserIds addObject:readReceipt.userId];
                            }
                        }
                        [self updateCellData:roomBubbleCellData withReadReceipts:newReadReceipts forEventId:component.event.eventId];
                    }
                }
            }
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // PATCH: Presently no bubble must be displayed until the user joins the room.
    // FIXME: Handle room data source in case of room preview
    if (self.room.summary.membership == MXMembershipInvite)
    {
        return 0;
    }
    
    NSInteger count;
    @synchronized(bubbles)
    {
        count = bubbles.count;
    }
    return count;
}

- (void)scanBubbleDataIfNeeded:(id<MXKRoomBubbleCellDataStoring>)bubbleData
{
    MXScanManager *scanManager = self.mxSession.scanManager;
    
    if (!scanManager && ![bubbleData isKindOfClass:MXKRoomBubbleCellData.class])
    {
        return;
    }

    MXKRoomBubbleCellData *roomBubbleCellData = (MXKRoomBubbleCellData*)bubbleData;
    
    NSString *contentURL = roomBubbleCellData.attachment.contentURL;

    // If the content url corresponds to an upload id, the upload is in progress or not complete.
    // Create a fake event scan with in progress status when uploading media.
    // Since there is no event scan in database it will be overriden by MXScanManager on media upload complete.
    if (contentURL && [contentURL hasPrefix:kMXMediaUploadIdPrefix])
    {
        MXKRoomBubbleComponent *firstBubbleComponent = roomBubbleCellData.bubbleComponents.firstObject;
        MXEvent *firstBubbleComponentEvent = firstBubbleComponent.event;
        
        if (firstBubbleComponent && firstBubbleComponent.eventScan.antivirusScanStatus != MXAntivirusScanStatusInProgress && firstBubbleComponentEvent)
        {
            MXEventScan *uploadEventScan = [MXEventScan new];
            uploadEventScan.eventId = firstBubbleComponentEvent.eventId;
            uploadEventScan.antivirusScanStatus = MXAntivirusScanStatusInProgress;
            uploadEventScan.antivirusScanDate = nil;
            uploadEventScan.mediaScans = @[];
            
            firstBubbleComponent.eventScan = uploadEventScan;
        }
    }
    else
    {
        for (MXKRoomBubbleComponent *bubbleComponent in roomBubbleCellData.bubbleComponents)
        {
            MXEvent *event = bubbleComponent.event;
            
            if ([event isContentScannable])
            {
                [scanManager scanEventIfNeeded:event];
                // NOTE: - [MXScanManager scanEventIfNeeded:] perform modification in background, so - [MXScanManager eventScanWithId:] do not retrieve the last state of event scan.
                // It is noticeable when eventScan should be created for the first time. It would be better to return an eventScan with an in progress scan status instead of nil.
                MXEventScan *eventScan = [scanManager eventScanWithId:event.eventId];
                bubbleComponent.eventScan = eventScan;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell<MXKCellRendering> *cell;
    
    id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataAtIndex:indexPath.row];
    
    // Launch an antivirus scan on events contained in bubble data if needed
    [self scanBubbleDataIfNeeded:bubbleData];
    
    if (bubbleData && self.delegate)
    {
        // Retrieve the cell identifier according to cell data.
        NSString *identifier = [self.delegate cellReuseIdentifierForCellData:bubbleData];
        if (identifier)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
            
            // Make sure we listen to user actions on the cell
            cell.delegate = self;
            
            // Update typing flag before rendering
            bubbleData.isTyping = _showTypingNotifications && currentTypingUsers && ([currentTypingUsers indexOfObject:bubbleData.senderId] != NSNotFound);
            // Report the current timestamp display option
            bubbleData.showBubbleDateTime = self.showBubblesDateTime;
            // display the read receipts
            bubbleData.showBubbleReceipts = self.showBubbleReceipts;
            // let the caller application manages the time label?
            bubbleData.useCustomDateTimeLabel = self.useCustomDateTimeLabel;
            // let the caller application manages the receipt?
            bubbleData.useCustomReceipts = self.useCustomReceipts;
            // let the caller application manages the unsent button?
            bubbleData.useCustomUnsentButton = self.useCustomUnsentButton;
            
            // Make the bubble display the data
            [cell render:bubbleData];
        }
    }
    
    // Sanity check: this method may be called during a layout refresh while room data have been modified.
    if (!cell)
    {
        // Return an empty cell
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fakeCell"];
    }
    
    return cell;
}

#pragma mark - MXScanManager notifications

- (void)registerScanManagerNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MXScanManagerEventScanDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventScansDidChange:) name:MXScanManagerEventScanDidChangeNotification object:nil];
}

- (void)unregisterScanManagerNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MXScanManagerEventScanDidChangeNotification object:nil];
}
     
- (void)eventScansDidChange:(NSNotification*)notification
{
    // TODO: Avoid to call the delegate to often. Set a minimum time interval to avoid table view flickering.
    [self.delegate dataSource:self didCellChange:nil];
}


#pragma mark - Reactions

- (void)registerReactionsChangeListener
{
    if (!self.showReactions || reactionsChangeListener)
    {
        return;
    }

    MXWeakify(self);
    reactionsChangeListener = [self.mxSession.aggregations listenToReactionCountUpdateInRoom:self.roomId block:^(NSDictionary<NSString *,MXReactionCountChange *> * _Nonnull changes) {
        MXStrongifyAndReturnIfNil(self);

        BOOL updated = NO;
        for (NSString *eventId in changes)
        {
            id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:eventId];
            if (bubbleData)
            {
                // TODO: Be smarted and use changes[eventId]
                [self updateCellDataReactions:bubbleData forEventId:eventId];
                updated = YES;
            }
        }

        if (updated)
        {
            [self.delegate dataSource:self didCellChange:nil];
        }
    }];
}

- (void)unregisterReactionsChangeListener
{
    if (reactionsChangeListener)
    {
        [self.mxSession.aggregations removeListener:reactionsChangeListener];
        reactionsChangeListener = nil;
    }
}

- (void)updateCellDataReactions:(id<MXKRoomBubbleCellDataStoring>)cellData forEventId:(NSString*)eventId
{
    if (!self.showReactions || ![cellData isKindOfClass:MXKRoomBubbleCellData.class])
    {
        return;
    }

    MXKRoomBubbleCellData *roomBubbleCellData = (MXKRoomBubbleCellData*)cellData;

    MXAggregatedReactions *aggregatedReactions = [self.mxSession.aggregations aggregatedReactionsOnEvent:eventId inRoom:self.roomId].aggregatedReactionsWithNonZeroCount;
    
    if (self.showOnlySingleEmojiReactions)
    {
        aggregatedReactions = aggregatedReactions.aggregatedReactionsWithSingleEmoji;
    }
    
    if (aggregatedReactions)
    {
        if (!roomBubbleCellData.reactions)
        {
            roomBubbleCellData.reactions = [NSMutableDictionary dictionary];
        }

        roomBubbleCellData.reactions[eventId] = aggregatedReactions;
    }
    else
    {
        // unreaction
        roomBubbleCellData.reactions[eventId] = nil;
    }

    // Indicate that the text message layout should be recomputed.
    [roomBubbleCellData invalidateTextLayout];
}

- (BOOL)canReactToEventWithId:(NSString*)eventId
{
    BOOL canReact = NO;
    
    MXEvent *event = [self eventWithEventId:eventId];
    
    if ([self canPerformActionOnEvent:event])
    {
        NSString *messageType = event.content[kMXMessageTypeKey];
        
        if ([messageType isEqualToString:kMXMessageTypeKeyVerificationRequest])
        {
            canReact = NO;
        }
        else
        {
            canReact = YES;
        }
    }
    
    return canReact;
}

- (void)addReaction:(NSString *)reaction forEventId:(NSString *)eventId success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self.mxSession.aggregations addReaction:reaction forEvent:eventId inRoom:self.roomId success:success failure:^(NSError * _Nonnull error) {
        MXLogDebug(@"[MXKRoomDataSource][%p] Fail to send reaction on eventId: %@", self, eventId);
        if (failure)
        {
            failure(error);
        }
    }];
}

- (void)removeReaction:(NSString *)reaction forEventId:(NSString *)eventId success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    [self.mxSession.aggregations removeReaction:reaction forEvent:eventId inRoom:self.roomId success:success failure:^(NSError * _Nonnull error) {
        MXLogDebug(@"[MXKRoomDataSource][%p] Fail to unreact on eventId: %@", self, eventId);
        if (failure)
        {
            failure(error);
        }
    }];
}

#pragma mark - Editions

- (BOOL)canEditEventWithId:(NSString*)eventId
{
    MXEvent *event = [self eventWithEventId:eventId];
    BOOL isRoomMessage = event.eventType == MXEventTypeRoomMessage;
    NSString *messageType = event.content[kMXMessageTypeKey];
    
    return isRoomMessage
    && ([messageType isEqualToString:kMXMessageTypeText] || [messageType isEqualToString:kMXMessageTypeEmote])
    && [event.sender isEqualToString:self.mxSession.myUserId]
    && [event.roomId isEqualToString:self.roomId];
}

- (NSString*)editableTextMessageForEvent:(MXEvent*)event
{
    NSString *editableTextMessage;
    
    if (event.isReplyEvent)
    {
        MXReplyEventParser *replyEventParser = [MXReplyEventParser new];
        MXReplyEventParts *replyEventParts = [replyEventParser parse:event];
        
        editableTextMessage = replyEventParts.bodyParts.replyText;
    }
    else
    {
        editableTextMessage = event.content[kMXMessageBodyKey];
    }
    
    return editableTextMessage;
}

- (void)registerEventEditsListener
{
    if (eventEditsListener)
    {
        return;
    }
    
    MXWeakify(self);
    eventEditsListener = [self.mxSession.aggregations listenToEditsUpdateInRoom:self.roomId block:^(MXEvent * _Nonnull replaceEvent) {
        MXStrongifyAndReturnIfNil(self);

        [self updateEventWithReplaceEvent:replaceEvent];
    }];
}

- (void)updateEventWithReplaceEvent:(MXEvent*)replaceEvent
{
    NSString *editedEventId = replaceEvent.relatesTo.eventId;

    dispatch_async(MXKRoomDataSource.processingQueue, ^{

        // Check whether a message contains the edited event
        id<MXKRoomBubbleCellDataStoring> bubbleData = [self cellDataOfEventWithEventId:editedEventId];
        if (bubbleData)
        {
            BOOL hasChanged = [self updateCellData:bubbleData forEditionWithReplaceEvent:replaceEvent andEventId:editedEventId];

            if (hasChanged)
            {
                // Update the delegate on main thread
                dispatch_async(dispatch_get_main_queue(), ^{

                    if (self.delegate)
                    {
                        [self.delegate dataSource:self didCellChange:nil];
                    }

                });
            }
        }
    });
}

- (void)unregisterEventEditsListener
{
    if (eventEditsListener)
    {
        [self.mxSession.aggregations removeListener:eventEditsListener];
        eventEditsListener = nil;
    }
}

- (BOOL)refreshRepliesWithUpdatedEventId:(NSString*)updatedEventId
{
    BOOL hasChanged = NO;

    @synchronized (bubbles) {
        for (id<MXKRoomBubbleCellDataStoring> bubbleCellData in bubbles)
        {
            for (MXEvent *event in bubbleCellData.events)
            {
                if ([event.relatesTo.inReplyTo.eventId isEqual:updatedEventId])
                {
                    [bubbleCellData updateEvent:event.eventId withEvent:event];
                    [bubbleCellData invalidateTextLayout];
                    hasChanged = YES;
                }
            }
        }
    }

    return hasChanged;
}

- (BOOL)updateCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData forEditionWithReplaceEvent:(MXEvent*)replaceEvent andEventId:(NSString*)eventId
{
    BOOL hasChanged = NO;

    hasChanged = [self refreshRepliesWithUpdatedEventId:eventId];

    @synchronized (bubbleCellData)
    {
        // Retrieve the original event to edit it
        NSArray *events = bubbleCellData.events;
        MXEvent *editedEvent = nil;
        
        // If not already done, update edited event content in-place
        // This is required for:
        //   - local echo
        //   - non live timeline in memory store (permalink)
        for (MXEvent *event in events)
        {
            if ([event.eventId isEqualToString:eventId])
            {
                // Check whether the event was not already edited
                if (![event.unsignedData.relations.replace.eventId isEqualToString:replaceEvent.eventId])
                {
                    editedEvent = [event editedEventFromReplacementEvent:replaceEvent];
                }
                break;
            }
        }
        
        if (editedEvent)
        {
            if (editedEvent.sentState != replaceEvent.sentState)
            {
                // Relay the replace event state to the edited event so that the display
                // of the edited will rerun the classic sending color flow.
                // Note: this must be done on the main thread (this operation triggers
                // the call of [self eventDidChangeSentState])
                dispatch_async(dispatch_get_main_queue(), ^{
                    editedEvent.sentState = replaceEvent.sentState;
                });
            }

            [bubbleCellData updateEvent:eventId withEvent:editedEvent];
            [bubbleCellData invalidateTextLayout];
            hasChanged = YES;
        }
    }
    
    return hasChanged;
}

- (void)replaceTextMessageForEvent:(MXEvent*)event
                   withTextMessage:(NSString *)text
                           success:(void (^)(NSString *))success
                           failure:(void (^)(NSError *))failure
{
    NSString *sanitizedText = [self sanitizedMessageText:text];
    NSString *formattedText = [self htmlMessageFromSanitizedText:sanitizedText];
    
    NSString *eventBody = event.content[kMXMessageBodyKey];
    NSString *eventFormattedBody = event.content[@"formatted_body"];
    
    if (![sanitizedText isEqualToString:eventBody] && (!eventFormattedBody || ![formattedText isEqualToString:eventFormattedBody]))
    {
        [self.mxSession.aggregations replaceTextMessageEvent:event withTextMessage:sanitizedText formattedText:formattedText localEchoBlock:^(MXEvent * _Nonnull replaceEventLocalEcho) {

            // Apply the local echo to the timeline
            [self updateEventWithReplaceEvent:replaceEventLocalEcho];

            // Integrate the replace local event into the timeline like when sending a message
            // This also allows to manage read receipt on this replace event
            [self queueEventForProcessing:replaceEventLocalEcho withRoomState:self.roomState direction:MXTimelineDirectionForwards];
            [self processQueuedEvents:nil];

        } success:success failure:failure];
    }
    else
    {
        failure(nil);
    }
}

#pragma mark - Virtual Rooms

- (void)virtualRoomsDidChange:(NSNotification *)notification
{
    //  update secondary room id
    self.secondaryRoomId = [self.mxSession virtualRoomOf:self.roomId];
}

#pragma mark - Use Only Latest Profiles

/**
 Refresh avatars and display names (AKA profiles) if needed.
 */
- (void)refreshProfilesIfNeeded
{
   @synchronized (bubbles) {
        for (id<MXKRoomBubbleCellDataStoring> bubble in bubbles)
        {
            [bubble refreshProfilesIfNeeded:self.roomState];
        }
    }
}

@end
