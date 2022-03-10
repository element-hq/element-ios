// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceList SpaceList
/*
 Copyright 2020 New Vector Ltd
 
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

protocol SpaceListCoordinatorDelegate: AnyObject {
    func spaceListCoordinatorDidSelectHomeSpace(_ coordinator: SpaceListCoordinatorType)
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didSelectSpaceWithId spaceId: String)
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didSelectInviteWithId spaceId: String, from sourceView: UIView?)
    func spaceListCoordinator(_ coordinator: SpaceListCoordinatorType, didPressMoreForSpaceWithId spaceId: String, from sourceView: UIView)
    func spaceListCoordinatorDidSelectCreateSpace(_ coordinator: SpaceListCoordinatorType)
}

/// `SpaceListCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SpaceListCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceListCoordinatorDelegate? { get }
    func revertItemSelection()
    func select(spaceWithId spaceId: String)
}
