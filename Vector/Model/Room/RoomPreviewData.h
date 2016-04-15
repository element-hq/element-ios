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
 TODO
 */
@property (nonatomic, readonly) NSString *roomName;
@property (nonatomic, readonly) NSString *roomAvatarUrl;
@property (nonatomic, readonly) NSString *roomTopic;

/**
 Contructors.
 
 @param roomId the id of the room.
 @param emailInvitationParams, in case of an email invitation link, the query parameters extracted from the link.
 @param mxSession the session to open the room preview with.
 */
- (instancetype)initWithRoomId:(NSString*)roomId andSession:(MXSession*)mxSession;
- (instancetype)initWithRoomId:(NSString*)roomId emailInvitationParams:(NSDictionary*)emailInvitationParams andSession:(MXSession*)mxSession;

@end
