/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

#import "WidgetManager.h"

#import "MXRoomSummary+Riot.h"

#import "TypingUserInfo.h"

@protocol RoomDataSourceDelegate;

/**
 The data source for `RoomViewController` in Vector.
 */
@interface RoomDataSource : MXKRoomDataSource

/**
 The event id of the current selected event if any. Default is nil.
 */
@property(nonatomic, nullable) NSString *selectedEventId;

/**
 Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
 */
@property(nonatomic) BOOL markTimelineInitialEvent;

/**
 Tell whether timestamp should be displayed on event selection. Default is YES.
 */
@property(nonatomic) BOOL showBubbleDateTimeOnSelection;

/**
 Flag to decide displaying typing row in the data source. Default is YES.
 */
@property (nonatomic, assign) BOOL showTypingRow;

/**
 Current room members trust level for an encrypted room.
 */
@property(nonatomic, readonly) RoomEncryptionTrustLevel encryptionTrustLevel;

/**
 List of members who are typing in the room.
 */
@property(nonatomic, nullable) NSArray<TypingUserInfo *> *currentTypingUsers;

/**
 Identifier of the event to be highlighted. Default is nil.
 Data source owner should reload the view itself to reflect changes, and nullify the parameter afterwards when it doesn't highlight the event anymore.
 */
@property (nonatomic, nullable) NSString *highlightedEventId;

/// Is current user sharing is location in the room
@property(nonatomic, readonly) BOOL isCurrentUserSharingActiveLocation;

/**
 Check if there is an active jitsi widget in the room and return it.

 @return a widget representating the active jitsi conference in the room. Else, nil.
 */
- (Widget * _Nullable)jitsiWidget;

/**
 Send a video to the room.
 Note: Move this method to MatrixKit when MatrixKit project will handle Swift module.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.
 
 @param videoLocalURL the local filesystem path of the video to send.
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the homeserver
 @param failure A block object called when the operation fails.
 */
- (void)sendVideo:(NSURL * _Nonnull)videoLocalURL
          success:(nullable void (^)(NSString * _Nonnull))success
          failure:(nullable void (^)(NSError * _Nullable))failure;

/**
 Accept incoming key verification request.

 @param eventId Event id associated to the key verification request event.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)acceptVerificationRequestForEventId:(NSString * _Nonnull)eventId
                                    success:(nullable void(^)(void))success
                                    failure:(nullable void(^)(NSError * _Nullable))failure;

/**
 Decline incoming key verification request.

 @param eventId Event id associated to the key verification request event.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)declineVerificationRequestForEventId:(NSString * _Nonnull)eventId
                                     success:(nullable void(^)(void))success
                                     failure:(nullable void(^)(NSError * _Nullable))failure;

- (void)resetTypingNotification;

@end

@protocol RoomDataSourceDelegate <MXKDataSourceDelegate>

/**
 Called when the room's encryption trust level did update.
 
 @param roomDataSource room data source instance
 */
- (void)roomDataSourceDidUpdateEncryptionTrustLevel:(RoomDataSource * _Nonnull)roomDataSource;

/**
 Called when a thread summary view is tapped.
 
 @param roomDataSource room data source instance
 */
- (void)roomDataSource:(RoomDataSource * _Nonnull)roomDataSource
          didTapThread:(id<MXThreadProtocol> _Nonnull)thread;

/// Called when current live location sharing status is changing (start or stop location sharing in the room)
- (void)roomDataSourceDidUpdateCurrentUserSharingLocationStatus:(RoomDataSource * _Nonnull)roomDataSource;

@end
