/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// RoomSuggestionCoordinator input parameters
struct RoomSuggestionCoordinatorParameters {
    /// The Matrix room
    let room: MXRoom
                
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType
    
    init(room: MXRoom,
         navigationRouter: NavigationRouterType? = nil) {
        self.room = room
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}
