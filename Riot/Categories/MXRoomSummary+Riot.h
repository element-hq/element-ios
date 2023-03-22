/*
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

#import "MatrixKit.h"

/**
 RoomEncryptionTrustLevel represents the trust level in an encrypted room.
 */
typedef NS_ENUM(NSUInteger, RoomEncryptionTrustLevel) {
    RoomEncryptionTrustLevelTrusted,
    RoomEncryptionTrustLevelWarning,
    RoomEncryptionTrustLevelNormal,
    RoomEncryptionTrustLevelUnknown
};


/**
 Define a `MXRoomSummary` category at Riot level.
 */
@interface MXRoomSummary (Riot)

@property(nonatomic, readonly) BOOL isJoined;

/**
 Set the room avatar in the dedicated MXKImageView.
 The riot style implies to use in order :
 1 - the default avatar if there is one
 2 - the member avatar for < 3 members rooms
 3 - the first letter of the room name.
 
 @param mxkImageView the destinated MXKImageView.
 */
- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView;

/**
 Get the trust level in the room.
 
 @return the trust level.
 */
- (RoomEncryptionTrustLevel)roomEncryptionTrustLevel;

@end
