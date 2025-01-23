// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol ContactsPickerCoordinatorDelegate: AnyObject {
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol)
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol)
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol)
}

protocol ContactsPickerCoordinatorProtocol: Coordinator, Presentable {
    var delegate: ContactsPickerCoordinatorDelegate? { get }
}
