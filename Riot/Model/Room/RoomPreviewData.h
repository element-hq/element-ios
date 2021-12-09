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

#import "MatrixKit.h"
#import "RoomEmailInvitation.h"
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
 In case of preview, the server names to try and join through in addition to those
 that are automatically chosen.
 */
@property (nonatomic) NSArray<NSString*> *viaServers;

/**
 Preview information.
 */
@property (nonatomic) NSString *roomName;
@property (nonatomic, readonly) NSString *roomTopic;
@property (nonatomic, readonly) NSString *roomAvatarUrl;
@property (nonatomic, readonly) NSString *roomCanonicalAlias;
@property (nonatomic, readonly) NSArray<NSString*> *roomAliases;
@property (nonatomic, readonly) NSInteger numJoinedMembers; // -1 if unknown.

/**
 The RoomDataSource to peek into the room. 
 Note: this object is created when [self peekInRoom:] succeeds.
 */
@property (nonatomic, readonly) RoomDataSource *roomDataSource;

/**
 Contructors.
 
 @param roomId the id of the room.
 @param mxSession the session to open the room preview with.
 */
- (instancetype)initWithRoomId:(NSString*)roomId andSession:(MXSession*)mxSession;

/**
 Contructors.
 
 @param roomId the id of the room.
 @param emailInvitationParams in case of an email invitation link, the query parameters extracted from the link.
 @param mxSession the session to open the room preview with.
 */
- (instancetype)initWithRoomId:(NSString*)roomId emailInvitationParams:(NSDictionary*)emailInvitationParams andSession:(MXSession*)mxSession;

/**
 Contructors.
 
 @param publicRoom a public room returned by the publicRoom request.
 @param mxSession the session to open the room preview with.
 */
- (instancetype)initWithPublicRoom:(MXPublicRoom*)publicRoom andSession:(MXSession*)mxSession;

/**
 Contructors.
 
 @param childInfo MXSpaceChildInfo instance that describes the child.
 @param mxSession the session to open the room preview with.
 */
- (instancetype)initWithSpaceChildInfo:(MXSpaceChildInfo*)childInfo andSession:(MXSession*)mxSession;

/**
 Attempt to peek into the room to get room data (state, messages history, etc).

 The operation succeeds only if the room history is world_readable.

 @param completion the block called when the request is complete. `succeeded` means
                   the self.roomDataSource has been created and is ready to provide
                   room history.
 */
- (void)peekInRoom:(void (^)(BOOL succeeded))completion;

@end
