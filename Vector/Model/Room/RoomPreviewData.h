/*
 Copyright 2016 OpenMarket Ltd

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

#import <Foundation/Foundation.h>

#import "RoomEmailInvitation.h"
#import "MXSession.h"
#import "RoomDataSource.h"

/**
 The `RoomEmailInvitation` gathers information for displaying the preview of a
 room that is unknown for the user.

 Such room can come from an email invitation link or a link to a room.
 */

@interface RoomPreviewData : NSObject

/**
 The id of the room to preview.
 */
@property (nonatomic, readonly) NSString *roomId;

/**
 In case of email invitation, the information extracted from the email invitation link.
 */
@property (nonatomic, readonly) RoomEmailInvitation *emailInvitation;

/**
 The matrix session to show the data.
 */
@property (nonatomic) MXSession *mxSession;

/**
 The id of the event where to start to show the room once joined.
 It is non nil only for permalinks to rooms the user has not joined yet.
 */
@property (nonatomic) NSString *eventId;

/**
 Preview information.
 They come from the `emailInvitationParams` or [self fetchPreviewData].
 */
@property (nonatomic, readonly) NSString *roomName;
@property (nonatomic, readonly) NSString *roomAvatarUrl;

/**
 The RoomDataSource to peek into the room. 
 Note: this object is creating when [self peekInRoom:] succeeds.
 */
@property (nonatomic, readonly) RoomDataSource *roomDataSource;

/**
 Contructors.
 
 @param roomId the id of the room.
 @param emailInvitationParams, in case of an email invitation link, the query parameters extracted from the link.
 @param mxSession the session to open the room preview with.
 */
- (instancetype)initWithRoomId:(NSString*)roomId andSession:(MXSession*)mxSession;
- (instancetype)initWithRoomId:(NSString*)roomId emailInvitationParams:(NSDictionary*)emailInvitationParams andSession:(MXSession*)mxSession;

/**
 Attempt to peek into room to get room data (state, messages history, etc).

 The operation succeeds only if the room history is world_readable.

 @param completion the block called when the request is complete. `successed` means
                   the self.roomDataSource has been created and is ready to provide
                   room history.
 */
- (void)peekInRoom:(void (^)(BOOL successed))completion;

@end
