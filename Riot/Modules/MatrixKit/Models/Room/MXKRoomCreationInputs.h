/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
