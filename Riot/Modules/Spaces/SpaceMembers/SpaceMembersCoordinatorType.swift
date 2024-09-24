// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceMembers SpaceMemberList ShowSpaceMemberList
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SpaceMembersCoordinatorDelegate: AnyObject {
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType)
}

/// `SpaceMembersCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol SpaceMembersCoordinatorType: Coordinator, Presentable {
    var delegate: SpaceMembersCoordinatorDelegate? { get }
}
