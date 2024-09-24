// File created from FlowTemplate
// $ createRootCoordinator.sh RoomAccessCoordinator RoomAccess
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// RoomAccessCoordinator input parameters
struct RoomAccessCoordinatorParameters {
    /// The Matrix room
    let room: MXRoom
    
    /// ID of the currently selected space. `nil` if home space
    let parentSpaceId: String?
    
    /// Set this value to false if you want to avoid room to be upgraded
    let allowsRoomUpgrade: Bool
                
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType
    
    init(room: MXRoom,
         parentSpaceId: String?,
         allowsRoomUpgrade: Bool = true,
         navigationRouter: NavigationRouterType? = nil) {
        self.room = room
        self.parentSpaceId = parentSpaceId
        self.allowsRoomUpgrade = allowsRoomUpgrade
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}
