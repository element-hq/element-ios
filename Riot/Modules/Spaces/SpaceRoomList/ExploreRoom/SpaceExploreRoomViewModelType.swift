// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceRoomList/ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
