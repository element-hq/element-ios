// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
// File created from FlowTemplate
// $ createRootCoordinator.sh SpaceCreationCoordinator SpaceCreation
/*
 Copyright 2021 New Vector Ltd
 
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

import Foundation

/// SpaceCreationCoordinator input parameters
struct SpaceCreationCoordinatorParameters {
    
    /// The Matrix session
    let session: MXSession
    
    /// The identifier of the parent space. `nil` for creating a root space
    let parentSpaceId: String?
    
    /// Parameters needed to create the new space
    let creationParameters: SpaceCreationParameters = SpaceCreationParameters()
                
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
