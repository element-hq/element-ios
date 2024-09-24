// File created from ScreenTemplate
// $ createScreen.sh SetPinCode/EnterPinCode EnterPinCode
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol EnterPinCodeCoordinatorDelegate: AnyObject {
    func enterPinCodeCoordinatorDidComplete(_ coordinator: EnterPinCodeCoordinatorType)
    func enterPinCodeCoordinatorDidCompleteWithReset(_ coordinator: EnterPinCodeCoordinatorType, dueToTooManyErrors: Bool)
    func enterPinCodeCoordinator(_ coordinator: EnterPinCodeCoordinatorType, didCompleteWithPin pin: String)
    func enterPinCodeCoordinatorDidCancel(_ coordinator: EnterPinCodeCoordinatorType)
}

/// `EnterPinCodeCoordinatorType` is a protocol describing a Coordinator that handle key backup setup passphrase navigation flow.
protocol EnterPinCodeCoordinatorType: Coordinator, Presentable {
    var delegate: EnterPinCodeCoordinatorDelegate? { get }
}
