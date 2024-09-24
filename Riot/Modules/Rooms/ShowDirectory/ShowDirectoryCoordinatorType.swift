// File created from ScreenTemplate
// $ createScreen.sh Rooms/ShowDirectory ShowDirectory
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ShowDirectoryCoordinatorDelegate: AnyObject {
    func showDirectoryCoordinator(_ coordinator: ShowDirectoryCoordinatorType, didSelectRoom room: MXPublicRoom)
    func showDirectoryCoordinatorDidTapCreateNewRoom(_ coordinator: ShowDirectoryCoordinatorType)
    func showDirectoryCoordinatorDidCancel(_ coordinator: ShowDirectoryCoordinatorType)
    func showDirectoryCoordinatorWantsToShow(_ coordinator: ShowDirectoryCoordinatorType, viewController: UIViewController)
    func showDirectoryCoordinator(_ coordinator: ShowDirectoryCoordinatorType, didSelectRoomWithIdOrAlias roomIdOrAlias: String)
}

/// `ShowDirectoryCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol ShowDirectoryCoordinatorType: Coordinator, Presentable {
    var delegate: ShowDirectoryCoordinatorDelegate? { get }
}
