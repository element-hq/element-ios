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

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

#import <MatrixSDK/MXEnumConstants.h>

@class MXSession;

/**
 `MXKRoomCreationInputs` objects lists all the fields considered for a new room creation.
 */
@interface MXKRoomCreationInputs : NSObject

/**
 The selected matrix session in which the new room should be created.
 */
@property (nonatomic) MXSession* mxSession;

/**
 The room name.
 */
@property (nonatomic) NSString* roomName;

/**
 The room alias.
 */
@property (nonatomic) NSString* roomAlias;

/**
 The room topic.
 */
@property (nonatomic) NSString* roomTopic;

/**
 The room picture.
 */
@property (nonatomic) UIImage *roomPicture;

/**
 The room visibility (kMXRoomVisibilityPrivate by default).
 */
@property (nonatomic) MXRoomDirectoryVisibility roomVisibility;

/**
 The room participants (nil by default).
 */
@property (nonatomic) NSArray *roomParticipants;

/**
 Add a participant.
 
 @param participantId The matrix user id of the participant.
 */
- (void)addParticipant:(NSString *)participantId;

/**
 Remove a participant.
 
 @param participantId The matrix user id of the participant.
 */
- (void)removeParticipant:(NSString *)participantId;

@end
