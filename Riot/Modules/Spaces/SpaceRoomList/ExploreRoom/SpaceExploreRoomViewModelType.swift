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
import MatrixSDK

protocol SpaceExploreRoomViewModelViewDelegate: AnyObject {
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, didUpdateViewState viewSate: SpaceExploreRoomViewState)
}

protocol SpaceExploreRoomViewModelCoordinatorDelegate: AnyObject {
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?)
    func spaceExploreRoomViewModelDidCancel(_ viewModel: SpaceExploreRoomViewModelType)
    func spaceExploreRoomViewModelDidAddRoom(_ viewModel: SpaceExploreRoomViewModelType)
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, openSettingsOf item: SpaceExploreRoomListItemViewData)
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, inviteTo item: SpaceExploreRoomListItemViewData)
    func spaceExploreRoomViewModel(_ viewModel: SpaceExploreRoomViewModelType, didJoin item: SpaceExploreRoomListItemViewData)
}

/// Protocol describing the view model used by `SpaceExploreRoomViewController`
protocol SpaceExploreRoomViewModelType {        
        
    var viewDelegate: SpaceExploreRoomViewModelViewDelegate? { get set }
    var coordinatorDelegate: SpaceExploreRoomViewModelCoordinatorDelegate? { get set }
    var showCancelMenuItem: Bool { get }
    var space: MXSpace? { get }

    func process(viewAction: SpaceExploreRoomViewAction)
    @available(iOS 13.0, *)
    func contextMenu(for itemData: SpaceExploreRoomListItemViewData) -> UIMenu
}
