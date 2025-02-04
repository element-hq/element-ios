//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// SpaceSettingsModalCoordinator input parameters
struct SpaceSettingsModalCoordinatorParameters {
    /// The Matrix session
    let session: MXSession

    /// The ID of the space
    let spaceId: String
    
    /// The ID of the currently selected parent of this space. `nil` for home
    let parentSpaceId: String?
                
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType
    
    init(session: MXSession,
         spaceId: String,
         parentSpaceId: String?,
         navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.spaceId = spaceId
        self.parentSpaceId = parentSpaceId
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}
