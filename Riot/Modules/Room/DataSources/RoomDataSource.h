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

#import <MatrixKit/MatrixKit.h>

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
@property(nonatomic) NSString *selectedEventId;

/**
 Tell whether the initial event of the timeline (if any) must be marked. Default is NO.
 */
@property(nonatomic) BOOL markTimelineInitialEvent;

/**
 Tell whether timestamp should be displayed on event selection. Default is YES.
 */
@property(nonatomic) BOOL showBubbleDateTimeOnSelection;

/**
 Current room members trust level for an encrypted room.
 */
@property(nonatomic, readonly) RoomEncryptionTrustLevel encryptionTrustLevel;

/**
 List of members who are typing in the room.
 */
@property(nonatomic, nullable) NSArray<TypingUserInfo *> *currentTypingUsers;

/**
 Check if there is an active jitsi widget in the room and return it.

 @return a widget representating the active jitsi conference in the room. Else, nil.
 */
- (Widget *)jitsiWidget;

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
- (void)sendVideo:(NSURL*)videoLocalURL
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure;

/**
 Accept incoming key verification request.

 @param eventId Event id associated to the key verification request event.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)acceptVerificationRequestForEventId:(NSString*)eventId
                                    success:(void(^)(void))success
                                    failure:(void(^)(NSError*))failure;

/**
 Decline incoming key verification request.

 @param eventId Event id associated to the key verification request event.
 @param success A block object called when the operation succeeds.
 @param failure A block object called when the operation fails.
 */
- (void)declineVerificationRequestForEventId:(NSString*)eventId
                                     success:(void(^)(void))success
                                     failure:(void(^)(NSError*))failure;

- (void)resetTypingNotification;

@end

@protocol RoomDataSourceDelegate <MXKDataSourceDelegate>

- (void)roomDataSource:(RoomDataSource*)roomDataSource didUpdateEncryptionTrustLevel:(RoomEncryptionTrustLevel)roomEncryptionTrustLevel;

- (void)roomDataSource:(RoomDataSource*)roomDataSource didCancel:(MXEvent *)event;


@end
