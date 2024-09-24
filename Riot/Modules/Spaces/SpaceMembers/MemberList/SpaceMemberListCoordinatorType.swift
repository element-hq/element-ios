// File created from ScreenTemplate
// $ createScreen.sh Spaces/SpaceMembers/MemberList ShowSpaceMemberList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceMemberListCoordinatorDelegate: AnyObject {
    func spaceMemberListCoordinator(_ coordinator: SpaceMemberListCoordinatorType, didSelect member: MXRoomMember, from sourceView: UIView?)
    func spaceMemberListCoordinatorDidCancel(_ coordinator: SpaceMemberListCoordinatorType)
    func spaceMemberListCoordinatorShowInvite(_ coordinator: SpaceMemberListCoordinatorType)
}

/// `SpaceMemberListCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol SpaceMemberListCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceMemberListCoordinatorDelegate? { get }
}
