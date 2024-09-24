// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceRoomList ExploreRoom ShowSpaceExploreRoom
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ExploreRoomCoordinatorDelegate: AnyObject {
    func exploreRoomCoordinatorDidComplete(_ coordinator: ExploreRoomCoordinatorType)
}

/// `ExploreRoomCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol ExploreRoomCoordinatorType: Coordinator, Presentable {
    var delegate: ExploreRoomCoordinatorDelegate? { get }
}
