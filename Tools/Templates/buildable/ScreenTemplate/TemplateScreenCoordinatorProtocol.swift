/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol TemplateScreenCoordinatorDelegate: AnyObject {
    func templateScreenCoordinator(_ coordinator: TemplateScreenCoordinatorProtocol, didCompleteWithUserDisplayName userDisplayName: String?)
    func templateScreenCoordinatorDidCancel(_ coordinator: TemplateScreenCoordinatorProtocol)
}

/// `TemplateScreenCoordinatorProtocol` is a protocol describing a Coordinator that handle xxxxxxx navigation flow.
protocol TemplateScreenCoordinatorProtocol: Coordinator, Presentable {
    var delegate: TemplateScreenCoordinatorDelegate? { get }
}
