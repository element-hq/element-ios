/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd

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

#import <UIKit/UIKit.h>

#import "MXKDataSource.h"
#import "MXKRoomBubbleCellDataStoring.h"
#import "MXKEventFormatter.h"
#import "MXEventContentLocation.h"

@class MXKQueuedEvent;

/**
 Define the threshold which triggers a bubbles count flush.
 */
#define MXKROOMDATASOURCE_CACHED_BUBBLES_COUNT_THRESHOLD 30

/**
 Define the number of messages to preload around the initial event.
 */
#define MXKROOMDATASOURCE_PAGINATION_LIMIT_AROUND_INITIAL_EVENT 30

/**
 List the supported pagination of the rendered room bubble cells
 */
typedef enum : NSUInteger
{
    /**
     No pagination
     */
    MXKRoomDataSourceBubblesPaginationNone,
    /**
     The rendered room bubble cells are paginated per day
     */
    MXKRoomDataSourceBubblesPaginationPerDay
    
} MXKRoomDataSourceBubblesPagination;


#pragma mark - Cells identifiers

/**
 String identifying the object used to store and prepare room bubble data.
 */
extern NSString *const kMXKRoomBubbleCellDataIdentifier;


#pragma mark - Notifications

/**
 Posted when a server sync starts or ends (depend on 'serverSyncEventCount').
 The notification object is the `MXKRoomDataSource` instance.
 */
extern NSString *const kMXKRoomDataSourceSyncStatusChanged;

/**
 Posted when the data source has failed to paginate around an event.
 The notification object is the `MXKRoomDataSource` instance. The `userInfo` dictionary contains the following key:
     - kMXKRoomDataTimelineErrorErrorKey: The NSError.
 */
extern NSString *const kMXKRoomDataSourceTimelineError;

/**
 Notifications `userInfo` keys
 */
extern NSString *const kMXKRoomDataSourceTimelineErrorErrorKey;

#pragma mark - MXKRoomDataSource
@protocol MXKRoomBubbleCellDataStoring;
@class MXKRoomBubbleCellData;

/**
 The data source for `MXKRoomViewController`.
 */
@interface MXKRoomDataSource : MXKDataSource <UITableViewDataSource>
{
@protected

    /**
     The data for the cells served by `MXKRoomDataSource`.
     */
    NSMutableArray<id<MXKRoomBubbleCellDataStoring>> *bubbles;

    /**
     The queue of events that need to be processed in order to compute their display.
     */
    NSMutableArray<MXKQueuedEvent*> *eventsToProcess;
}

/**
 The id of the room managed by the data source.
 */
@property (nonatomic, readonly) NSString *roomId;

/**
 The id of the secondary room managed by the data source. Events with specified types from the secondary room will be provided from the data source.
 @see `secondaryRoomEventTypes`.
 Can be nil.
 */
@property (nonatomic, copy) NSString *secondaryRoomId;

/**
 Types of events to include from the secondary room. Default is all call events.
 */
@property (nonatomic, copy) NSArray<MXEventTypeString> *secondaryRoomEventTypes;

/**
 The room the data comes from.
 The object is defined when the MXSession has data for the room
 */
@property (nonatomic, readonly) MXRoom *room;

/**
 The preloaded room.state.
 */
@property (nonatomic, readonly) MXRoomState *roomState;

/**
 The timeline being managed. It can be the live timeline of the room
 or a timeline from a past event, initialEventId.
 */
@property (nonatomic, readonly) id<MXEventTimeline> timeline;

/**
 Flag indicating if the data source manages, or will manage, a live timeline.
 */
@property (nonatomic, readonly) BOOL isLive;

/**
 Flag indicating if the data source is used to peek into a room, ie it gets data from
 a room the user has not joined yet.
 */
@property (nonatomic, readonly) BOOL isPeeking;

/**
 The list of the attachments with thumbnail in the current available bubbles (MXKAttachment instances).
 Note: the stickers are excluded from the returned list.
 Note2: the attachments for which the antivirus scan status is not available are excluded too.
 */
@property (nonatomic, readonly) NSArray *attachmentsWithThumbnail;

/**
 The events are processed asynchronously. This property counts the number of queued events
 during server sync for which the process is pending.
 */
@property (nonatomic, readonly) NSInteger serverSyncEventCount;

/**
 The current attributed text message partially typed in text input (use nil to reset it).
 */
@property (nonatomic) NSAttributedString *partialAttributedTextMessage;

/**
 The current thread id for the data source. If provided, data source displays the specified thread, otherwise the whole room messages.
 */
@property (nonatomic, readonly) NSString *threadId;

#pragma mark - Configuration
/**
 The text formatter applied on the events.
 By default, the events are filtered according to the value stored in the shared application settings (see [MXKAppSettings standardAppSettings].eventsFilterForMessages).
 The events whose the type doesn't belong to the this list are not displayed.
 `MXKRoomBubbleCellDataStoring` instances can use it to format text.
 */
@property (nonatomic) MXKEventFormatter *eventFormatter;

/**
 Show the date time label in rendered room bubble cells. NO by default.
 */
@property (nonatomic) BOOL showBubblesDateTime;

/**
 A Boolean value that determines whether the date time labels are customized (By default date time display is handled by MatrixKit). NO by default.
 */
@property (nonatomic) BOOL useCustomDateTimeLabel;

/**
 Show the read marker (if any) in the rendered room bubble cells. YES by default.
 */
@property (nonatomic) BOOL showReadMarker;

/**
 Show the receipts in rendered bubble cell. YES by default.
 */
@property (nonatomic) BOOL showBubbleReceipts;

/**
 A Boolean value that determines whether the read receipts are customized (By default read receipts display is handled by MatrixKit). NO by default.
 */
@property (nonatomic) BOOL useCustomReceipts;

/**
 Show the reactions in rendered bubble cell. NO by default.
 */
@property (nonatomic) BOOL showReactions;

/**
 Show only reactions with single Emoji. NO by default.
 */
@property (nonatomic) BOOL showOnlySingleEmojiReactions;

/**
 A Boolean value that determines whether the unsent button is customized (By default an 'Unsent' button is displayed by MatrixKit in front of unsent events). NO by default.
 */
@property (nonatomic) BOOL useCustomUnsentButton;

/**
 Show the typing notifications of other room members in the chat history (NO by default).
 */
@property (nonatomic) BOOL showTypingNotifications;

/**
 The pagination applied on the rendered room bubble cells (MXKRoomDataSourceBubblesPaginationNone by default).
 */
@property (nonatomic) MXKRoomDataSourceBubblesPagination bubblesPagination;

/**
 Max nbr of cached bubbles when there is no delegate.
 The default value is 30.
 */
@property (nonatomic) unsigned long maxBackgroundCachedBubblesCount;

/**
 The number of messages to preload around the initial event.
 The default value is 30.
 */
@property (nonatomic) NSUInteger paginationLimitAroundInitialEvent;

/**
 Tell whether only the message events with an url key in their content must be handled. NO by default.
 Note: The stickers are not retained by this filter.
 */
@property (nonatomic) BOOL filterMessagesWithURL;

#pragma mark - Life cycle

/**
 Asynchronously create a data source to serve data corresponding to the passed room.

 This method preloads room data, like the room state, to make it available once
 the room data source is created.

 @param roomId the id of the room to get data from.
 @param threadId the id of the thread to load. If provided, thread data source will be loaded from the room specified with `roomId`.
 @param mxSession the Matrix session to get data from.
 @param onComplete a block providing the newly created instance.
 */
+ (void)loadRoomDataSourceWithRoomId:(NSString*)roomId threadId:(NSString*)threadId andMatrixSession:(MXSession*)mxSession onComplete:(void (^)(id roomDataSource))onComplete;

/**
 Asynchronously create adata source to serve data corresponding to an event in the
 past of a room.

 This method preloads room data, like the room state, to make it available once
 the room data source is created.

 @param roomId the id of the room to get data from.
 @param initialEventId the id of the event where to start the timeline.
 @param threadId the id of the thread to load. If provided, thread data source will be loaded from the room specified with `roomId`.
 @param mxSession the Matrix session to get data from.
 @param onComplete a block providing the newly created instance.
 */
+ (void)loadRoomDataSourceWithRoomId:(NSString*)roomId
                      initialEventId:(NSString*)initialEventId
                            threadId:(NSString*)threadId
                    andMatrixSession:(MXSession*)mxSession
                          onComplete:(void (^)(id roomDataSource))onComplete;

/**
 Asynchronously create a data source to peek into a room.

 The data source will close the `peekingRoom` instance on [self destroy].

 This method preloads room data, like the room state, to make it available once
 the room data source is created.

 @param peekingRoom the room to peek.
 @param initialEventId the id of the event where to start the timeline. nil means the live
                       timeline.
 @param onComplete a block providing the newly created instance.
 */
+ (void)loadRoomDataSourceWithPeekingRoom:(MXPeekingRoom*)peekingRoom andInitialEventId:(NSString*)initialEventId onComplete:(void (^)(id roomDataSource))onComplete;

#pragma mark - Constructors (Should not be called directly)

/**
 Initialise the data source to serve data corresponding to the passed room.
 
 @param roomId the id of the room to get data from.
 @param threadId the id of the thread to initialize. If provided, thread data source will be initialized from the room specified with `roomId`.
 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)mxSession threadId:(NSString*)threadId;

/**
 Initialise the data source to serve data corresponding to an event in the
 past of a room.

 @param roomId the id of the room to get data from.
 @param initialEventId the id of the event where to start the timeline.
 @param threadId the id of the thread to initialize. If provided, thread data source will be initialized from the room specified with `roomId`.
 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithRoomId:(NSString*)roomId
                initialEventId:(NSString*)initialEventId
                      threadId:(NSString*)threadId
              andMatrixSession:(MXSession*)mxSession;

/**
 Initialise the data source to peek into a room.
 
 The data source will close the `peekingRoom` instance on [self destroy].

 @param peekingRoom the room to peek.
 @param initialEventId the id of the event where to start the timeline. nil means the live
                       timeline.
 @return the newly created instance.
 */
- (instancetype)initWithPeekingRoom:(MXPeekingRoom*)peekingRoom andInitialEventId:(NSString*)initialEventId;

/**
 Mark all messages as read in the room.
 */
- (void)markAllAsRead;

/**
 Reduce memory usage by releasing room data if the number of bubbles is over the provided limit 'maxBubbleNb'.
 
 This operation is ignored if some local echoes are pending or if unread messages counter is not nil.
 
 @param maxBubbleNb The room bubble data are released only if the number of bubbles is over this limit.
 */
- (void)limitMemoryUsage:(NSInteger)maxBubbleNb;

/**
 Force data reload. Calls `reloadNotifying` with `YES`.
 */
- (void)reload;

/**
 Force data reload.

 @param notify Flag to notify the delegate about the changes.
 */
- (void)reloadNotifying:(BOOL)notify;

/**
 Called when room property changed. Designed to be used by subclasses.
 */
- (void)roomDidSet;

#pragma mark - Public methods
/**
 Get the data for the cell at the given index.

 @param index the index of the cell in the array
 @return the cell data
 */
- (id<MXKRoomBubbleCellDataStoring>)cellDataAtIndex:(NSInteger)index;

/**
 Get the data for the cell which contains the event with the provided event id.

 @param eventId the event identifier
 @return the cell data
 */
- (id<MXKRoomBubbleCellDataStoring>)cellDataOfEventWithEventId:(NSString*)eventId;

/**
 Get the index of the cell which contains the event with the provided event id.

 @param eventId the event identifier
 @return the index of the concerned cell (NSNotFound if none).
 */
- (NSInteger)indexOfCellDataWithEventId:(NSString *)eventId;

/**
 Get height of the cell at the given index.

 @param index the index of the cell in the array.
 @param maxWidth the maximum available width.
 @return the cell height (0 if no data is available for this cell, or if the delegate is undefined).
 */
- (CGFloat)cellHeightAtIndex:(NSInteger)index withMaximumWidth:(CGFloat)maxWidth;


/**
 Force bubbles cell data message recalculation.
 */
- (void)invalidateBubblesCellDataCache;

#pragma mark - Pagination
/**
 Load more messages.
 This method fails (with nil error) if the data source is not ready (see `MXKDataSourceStateReady`).
 
 @param numItems the number of items to get.
 @param direction backwards or forwards.
 @param onlyFromStore if YES, return available events from the store, do not make a pagination request to the homeserver.
 @param success a block called when the operation succeeds. This block returns the number of added cells.
 (Note this count may be 0 if paginated messages have been concatenated to the current first cell).
 @param failure a block called when the operation fails.
 */
- (void)paginate:(NSUInteger)numItems direction:(MXTimelineDirection)direction onlyFromStore:(BOOL)onlyFromStore success:(void (^)(NSUInteger addedCellNumber))success failure:(void (^)(NSError *error))failure;

/**
 Load enough messages to fill the rect.
 This method fails (with nil error) if the data source is not ready (see `MXKDataSourceStateReady`),
 or if the delegate is undefined (this delegate is required to compute the actual size of the cells).
 
 @param rect the rect to fill.
 @param direction backwards or forwards.
 @param minRequestMessagesCount if messages are not available in the store, a request to the homeserver
        is required. minRequestMessagesCount indicates the minimum messages count to retrieve from the hs.
 @param success a block called when the operation succeeds.
 @param failure a block called when the operation fails.
 */
- (void)paginateToFillRect:(CGRect)rect  direction:(MXTimelineDirection)direction withMinRequestMessagesCount:(NSUInteger)minRequestMessagesCount success:(void (^)(void))success failure:(void (^)(NSError *error))failure;


#pragma mark - Sending
/**
 Send a text message to the room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param text the text to send.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendTextMessage:(NSString*)text
                success:(void (^)(NSString *eventId))success
                failure:(void (^)(NSError *error))failure;

/**
 Send a reply to an event with text message to the room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.
 
 @param eventToReply the event to reply.
 @param text the text to send.
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendReplyToEvent:(MXEvent*)eventToReply
         withTextMessage:(NSString *)text
                 success:(void (^)(NSString *))success
                 failure:(void (^)(NSError *))failure;

/**
 Updates an event with replacement event.
 @note the original event is defined in the `MXEventContentRelatesTo` object.

 @param replaceEvent the new event to display
 */
- (void)updateEventWithReplaceEvent:(MXEvent*)replaceEvent;

/**
 Indicates if replying to the provided event is supported.
 Only event of type 'MXEventTypeRoomMessage' are supported for the moment, and for certain msgtype.
 
 @param eventId The id of the event.
 @return YES if it is possible to reply to this event.
 */
- (BOOL)canReplyToEventWithId:(NSString*)eventId;

/**
 Send an image to the room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param image the UIImage containing the image to send.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendImage:(UIImage*)image
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure;

/**
 Send an image to the room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.
 
 @param imageData the full-sized image data of the image to send.
 @param mimetype the mime type of the image
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendImage:(NSData*)imageData mimeType:(NSString*)mimetype success:(void (^)(NSString *))success failure:(void (^)(NSError *))failure;

/**
 Send a video to the room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param videoLocalURL the local filesystem path of the video to send.
 @param videoThumbnail the UIImage hosting a video thumbnail.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendVideo:(NSURL*)videoLocalURL
    withThumbnail:(UIImage*)videoThumbnail
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure;

/**
 Send a video to the room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param videoAsset the AVAsset that represents the video to send.
 @param videoThumbnail the UIImage hosting a video thumbnail.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendVideoAsset:(AVAsset*)videoAsset
         withThumbnail:(UIImage*)videoThumbnail
               success:(void (^)(NSString *eventId))success
               failure:(void (^)(NSError *error))failure;

/**
 Send an audio file to the room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param audioFileLocalURL the local filesystem path of the audio file to send.
 @param mimeType the mime type of the file.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendAudioFile:(NSURL *)audioFileLocalURL
             mimeType:mimeType
              success:(void (^)(NSString *))success
              failure:(void (^)(NSError *))failure;

/**
 Send a voice message to the room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param audioFileLocalURL the local filesystem path of the audio file to send.
 @param mimeType (optional) the mime type of the file. Defaults to `audio/ogg`
 @param duration the length of the voice message in milliseconds
 @param samples an array of floating point values normalized to [0, 1], boxed within NSNumbers
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendVoiceMessage:(NSURL *)audioFileLocalURL
                mimeType:mimeType
                duration:(NSUInteger)duration
                 samples:(NSArray<NSNumber *> *)samples
                 success:(void (^)(NSString *))success
                 failure:(void (^)(NSError *))failure;

/**
 Send a file to the room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.
 
 @param fileLocalURL the local filesystem path of the file to send.
 @param mimeType the mime type of the file.
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendFile:(NSURL*)fileLocalURL
        mimeType:(NSString*)mimeType
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure;

/**
 Send a room message to a room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param content the message content that will be sent to the server as a JSON object.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendMessageWithContent:(NSDictionary*)content
                       success:(void (^)(NSString *eventId))success
                       failure:(void (^)(NSError *error))failure;

/**
 Send a location message to a room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.
 
 @param latitude the location's latitude
 @param longitude the location's longitude
 @param description an optional description
 @param coordinateType the location's type
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendLocationWithLatitude:(double)latitude
                       longitude:(double)longitude
                     description:(NSString *)description
                  coordinateType:(MXEventAssetType)coordinateType
                         success:(void (^)(NSString *))success
                         failure:(void (^)(NSError *))failure;

/**
 Send a generic non state event to a room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param eventTypeString the type of the event. @see MXEventType.
 @param content the content that will be sent to the server as a JSON object.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendEventOfType:(MXEventTypeString)eventTypeString
                            content:(NSDictionary<NSString*, id>*)content
                            success:(void (^)(NSString *eventId))success
                            failure:(void (^)(NSError *error))failure;

/**
 Resend a room message event.
 
 The echo message corresponding to the event will be removed and a new echo message
 will be added at the end of the room history.

 @param eventId of the event to resend.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)resendEventWithEventId:(NSString*)eventId
                  success:(void (^)(NSString *eventId))success
                  failure:(void (^)(NSError *error))failure;


#pragma mark - Events management
/**
 Get an event loaded in this room datasource.

 @param eventId of the event to retrieve.
 @return the MXEvent object or nil if not found.
 */
- (MXEvent *)eventWithEventId:(NSString *)eventId;

/**
 Remove an event from the events loaded by room datasource.

 @param eventId of the event to remove.
 */
- (void)removeEventWithEventId:(NSString *)eventId;

/**
 This method is called for each read receipt event received in forward mode.
 
 By default, it tells the delegate that some cell data/views have been changed.
 You may override this method to handle the receipt event according to the application needs.
 
 You should not call this method directly.
 You may override it in inherited 'MXKRoomDataSource' class.
 
 @param receiptEvent an event with 'm.receipt' type.
 @param roomState the room state right before the event
 */
- (void)didReceiveReceiptEvent:(MXEvent *)receiptEvent roomState:(MXRoomState *)roomState;

/**
 Update read receipts for an event in a bubble cell data.

 @param cellData The cell data to update.
 @param readReceipts The new read receipts.
 @param eventId The id of the event.
 */
- (void)updateCellData:(MXKRoomBubbleCellData*)cellData withReadReceipts:(NSArray<MXReceiptData*>*)readReceipts forEventId:(NSString*)eventId;

/**
 Overridable method to customise the way how unsent messages are managed.
 By default, they are added to the end of the timeline.
 */
- (void)handleUnsentMessages;

#pragma mark - Asynchronous events processing
/**
 The dispatch queue to process room messages.
 
 This processing can consume time. Handling it on a separated thread avoids to block the main thread.
 All MXKRoomDataSource instances share the same dispatch queue.
 */
+ (dispatch_queue_t)processingQueue;

/**
 Decides whether an event should be considered for asynchronous event processing.
 Default implementation checks for `filterMessagesWithURL` and undecryptable events sent before the user joined.
 Subclasses must call super at some point.
 
 @param event event to be processed or not
 @param roomState the state of the room when the event fired
 @param direction the direction of the event
 @return YES to process the event, NO otherwise
 */
- (BOOL)shouldQueueEventForProcessing:(MXEvent*)event
                            roomState:(MXRoomState*)roomState
                            direction:(MXTimelineDirection)direction;

/**
 Queue an event in order to process its display later.

 @param event the event to process.
 @param roomState the state of the room when the event fired.
 @param direction the order of the events in the arrays
 */
- (void)queueEventForProcessing:(MXEvent*)event
                  withRoomState:(MXRoomState*)roomState
                      direction:(MXTimelineDirection)direction;

/**
 Start processing pending events.

 @param onComplete a block called (on the main thread) when the processing has been done. Can be nil.
 Note this block returns the number of added cells in first and last positions.
 */
- (void)processQueuedEvents:(void (^)(NSUInteger addedHistoryCellNb, NSUInteger addedLiveCellNb))onComplete;

#pragma mark - Bubble collapsing

/**
 Collapse or expand a series of collapsable bubbles.
 
 @param bubbleData the first bubble of the series.
 @param collapsed YES to collapse. NO to expand.
 */
- (void)collapseRoomBubble:(id<MXKRoomBubbleCellDataStoring>)bubbleData collapsed:(BOOL)collapsed;

#pragma mark - Reactions

/**
 Indicates if it's possible to react on the event.

 @param eventId The id of the event.
 @return True to indicates reaction possibility for this event.
 */
- (BOOL)canReactToEventWithId:(NSString*)eventId;

/**
 Send a reaction to an event.

 @param reaction Reaction to add.
 @param eventId The id of the event.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)addReaction:(NSString *)reaction
         forEventId:(NSString *)eventId
            success:(void (^)(void))success
            failure:(void (^)(NSError *error))failure;

/**
 Unreact a reaction to an event.

 @param reaction Reaction to unreact.
 @param eventId The id of the event.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)removeReaction:(NSString *)reaction
            forEventId:(NSString *)eventId
               success:(void (^)(void))success
               failure:(void (^)(NSError *error))failure;

#pragma mark - Editions

/**
 Indicates if it's possible to edit the event content.
 
 @param eventId The id of the event.
 @return True to indicates edition possibility for this event.
 */
- (BOOL)canEditEventWithId:(NSString*)eventId;

/**
 Replace a text in an event.

 @param event The event to replace.
 @param text The new message text.
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the homeserver.
 @param failure A block object called when the operation fails.
 */
- (void)replaceTextMessageForEvent:(MXEvent *)event
                   withTextMessage:(NSString *)text
                           success:(void (^)(NSString *eventId))success
                           failure:(void (^)(NSError *error))failure;


/**
 Update reactions for an event in a bubble cell data.

 @param cellData The cell data to update.
 @param eventId The id of the event.
 */
- (void)updateCellDataReactions:(id<MXKRoomBubbleCellDataStoring>)cellData forEventId:(NSString*)eventId;

/**
 Retrieve editable text message from an event.

 @param event An event.
 @return Event text editable by user.
 */
- (NSString*)editableTextMessageForEvent:(MXEvent*)event;

@end
