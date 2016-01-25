/*
 Copyright 2015 OpenMarket Ltd

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

/**
 `AvatarGenerator` class generate an avatar image from objects
 */
@interface AvatarGenerator : NSObject

/**
 Generate an avatar for a room.
 @param roomId the id of the room.
 @param displayName the display name of the room.
 @return the avatar image
 */
+ (UIImage*)generateRoomAvatar:(NSString*)roomId andDisplayName:(NSString*)displayName;

/**
 Generate an avatar for a room member.
 @param userId the member userId
 @param displayname the member displayname
 @return the avatar image
 */
+ (UIImage*)generateRoomMemberAvatar:(NSString*)userId displayName:(NSString*)displayname;

/**
 Generate an avatar for a text.
 @param text the text.
 @return the avatar image
 */
+ (UIImage*)generateAvatarForText:(NSString*)text;

@end
