/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

/**
 Temporary category to help in the transition from synchronous access to room.state
 to asynchronous access.
 */
@interface MXRoom (Sync)

/**
 Get the room state if it has been already loaded else return nil.

 Use this method only where you are sure the room state is already mounted.
 */
@property (nonatomic, readonly) MXRoomState *dangerousSyncState;

@end
