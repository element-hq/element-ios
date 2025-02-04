// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol ContactsPickerViewModelCoordinatorDelegate: AnyObject {
    func contactsPickerViewModelDidStartLoading(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidEndLoading(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidStartInvite(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidEndInvite(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModel(_ viewModel: ContactsPickerViewModelProtocol, inviteFailedWithError error: Error?)
    func contactsPickerViewModel(_ viewModel: ContactsPickerViewModelProtocol, display message: String, title: String, actions: [UIAlertAction])
    func contactsPickerViewModelDidStartValidatingUser(_ coordinator: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidEndValidatingUser(_ coordinator: ContactsPickerViewModelProtocol)
}

protocol ContactsPickerViewModelProtocol {
    var coordinatorDelegate: ContactsPickerViewModelCoordinatorDelegate? { get set }
    var areParticipantsLoaded: Bool { get }
    
    func loadParticipants()
    @discardableResult func prepare(contactsViewController: RoomInviteViewController, currentSearchText: String?) -> Bool
}
