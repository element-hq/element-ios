// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
// File created from FlowTemplate
// $ createRootCoordinator.sh SpaceCreationCoordinator SpaceCreation
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

/// SpaceCreationCoordinator input parameters
struct SpaceCreationCoordinatorParameters {
    /// The Matrix session
    let session: MXSession
    
    /// The identifier of the parent space. `nil` for creating a root space
    let parentSpaceId: String?
    
    /// Parameters needed to create the new space
    let creationParameters = SpaceCreationParameters()
                
    /// The navigation router that manage physical navigation
    let navigationRouter: NavigationRouterType
    
    init(session: MXSession,
         parentSpaceId: String?,
         navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.parentSpaceId = parentSpaceId
        self.navigationRouter = navigationRouter ?? NavigationRouter(navigationController: RiotNavigationController())
    }
}
