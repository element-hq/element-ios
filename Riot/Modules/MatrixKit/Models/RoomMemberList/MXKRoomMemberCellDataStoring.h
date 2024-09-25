/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>
#import <MatrixSDK/MatrixSDK.h>

#import "MXKCellData.h"

@class MXKRoomMemberListDataSource;

/**
 `MXKRoomMemberCellDataStoring` defines a protocol a class must conform in order to store room member cell data
 managed by `MXKRoomMemberListDataSource`.
 */
@protocol MXKRoomMemberCellDataStoring <NSObject>


#pragma mark - Data displayed by a room member cell

/**
 The member displayed by the cell.
 */
@property (nonatomic, readonly) MXRoomMember *roomMember;

/**
 The member display name
 */
@property (nonatomic, readonly) NSString *memberDisplayName;

/**
 The member power level
 */
@property (nonatomic, readonly) CGFloat powerLevel;

/**
 YES when member is typing in the room
 */
@property (nonatomic) BOOL isTyping;

#pragma mark - Public methods
/**
 Create a new `MXKCellData` object for a new member cell.

 @param memberListDataSource the `MXKRoomMemberListDataSource` object that will use this instance.
 @return the newly created instance.
 */
- (instancetype)initWithRoomMember:(MXRoomMember*)member roomState:(MXRoomState*)roomState andRoomMemberListDataSource:(MXKRoomMemberListDataSource*)memberListDataSource;

/**
 Update the member data with the provided roon state.
 */
- (void)updateWithRoomState:(MXRoomState*)roomState;

@end
