// File created from FlowTemplate
// $ createRootCoordinator.sh RoomAccessCoordinator RoomAccess
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
