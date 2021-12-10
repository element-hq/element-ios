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
