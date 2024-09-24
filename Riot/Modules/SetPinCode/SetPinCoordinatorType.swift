// File created from FlowTemplate
// $ createRootCoordinator.sh SetPinCode SetPin EnterPinCode
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol SetPinCoordinatorDelegate: AnyObject {
    func setPinCoordinatorDidComplete(_ coordinator: SetPinCoordinatorType)
    func setPinCoordinatorDidCompleteWithReset(_ coordinator: SetPinCoordinatorType, dueToTooManyErrors: Bool)
    func setPinCoordinatorDidCancel(_ coordinator: SetPinCoordinatorType)
}

/// `SetPinCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol SetPinCoordinatorType: Coordinator, Presentable {
    var delegate: SetPinCoordinatorDelegate? { get }
}
