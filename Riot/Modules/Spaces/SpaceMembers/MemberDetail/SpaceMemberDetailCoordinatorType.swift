// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberDetail ShowSpaceMemberDetail
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceMemberDetailCoordinatorDelegate: AnyObject {
    func spaceMemberDetailCoordinator(_ coordinator: SpaceMemberDetailCoordinatorType, showRoomWithId roomId: String)
    func spaceMemberDetailCoordinatorDidCancel(_ coordinator: SpaceMemberDetailCoordinatorType)
}

/// `SpaceMemberDetailCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SpaceMemberDetailCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceMemberDetailCoordinatorDelegate? { get }
}
