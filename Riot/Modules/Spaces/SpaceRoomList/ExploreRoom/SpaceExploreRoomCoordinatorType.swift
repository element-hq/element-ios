// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
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

protocol SpaceExploreRoomCoordinatorDelegate: AnyObject {
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?)
    func spaceExploreRoomCoordinatorDidCancel(_ coordinator: SpaceExploreRoomCoordinatorType)
    func spaceExploreRoomCoordinatorDidAddRoom(_ coordinator: SpaceExploreRoomCoordinatorType)
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, openSettingsOf item: SpaceExploreRoomListItemViewData)
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, inviteTo item: SpaceExploreRoomListItemViewData)
    func spaceExploreRoomCoordinator(_ coordinator: SpaceExploreRoomCoordinatorType, didJoin item: SpaceExploreRoomListItemViewData)
}

/// `SpaceExploreRoomCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SpaceExploreRoomCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceExploreRoomCoordinatorDelegate? { get }
}
