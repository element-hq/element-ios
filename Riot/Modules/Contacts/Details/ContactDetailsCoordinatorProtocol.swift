// File created from ScreenTemplate
// $ createScreen.sh Contacts ContactDetails
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

protocol ContactDetailsCoordinatorDelegate: AnyObject {
    func contactDetailsCoordinatorDidCancel(_ coordinator: ContactDetailsCoordinatorProtocol)
}

/// `ContactDetailsCoordinatorProtocol` is a protocol describing a Coordinator that handle contact details navigation flow.
protocol ContactDetailsCoordinatorProtocol: Coordinator, Presentable {
    var delegate: ContactDetailsCoordinatorDelegate? { get }
}
