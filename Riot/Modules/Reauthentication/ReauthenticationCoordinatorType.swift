// File created from FlowTemplate
// $ createRootCoordinator.sh Reauthentication Reauthentication
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ReauthenticationCoordinatorDelegate: AnyObject {
    func reauthenticationCoordinatorDidComplete(_ coordinator: ReauthenticationCoordinatorType, withAuthenticationParameters: [String: Any]?)
    func reauthenticationCoordinatorDidCancel(_ coordinator: ReauthenticationCoordinatorType)
    func reauthenticationCoordinator(_ coordinator: ReauthenticationCoordinatorType, didFailWithError: Error)
}

/// `ReauthenticationCoordinatorType` is a protocol describing a Coordinator that handle reauthentication. It is used before calling an authenticated API.
protocol ReauthenticationCoordinatorType: Coordinator, Presentable {
    var delegate: ReauthenticationCoordinatorDelegate? { get }
}
