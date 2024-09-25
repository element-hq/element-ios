/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

/// FlowTemplateCoordinator input parameters
struct FlowTemplateCoordinatorParameters {
    
    /// The Matrix session
    let session: MXSession
                
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType
    
    init(session: MXSession,
         navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}
