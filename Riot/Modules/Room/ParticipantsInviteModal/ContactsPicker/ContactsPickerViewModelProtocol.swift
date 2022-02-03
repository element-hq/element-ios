// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

protocol ContactsPickerViewModelCoordinatorDelegate: AnyObject {
    func contactsPickerViewModelDidStartLoading(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidEndLoading(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidStartInvite(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModelDidEndInvite(_ viewModel: ContactsPickerViewModelProtocol)
    func contactsPickerViewModel(_ viewModel: ContactsPickerViewModelProtocol, inviteFailedWithError error: Error?)
    func contactsPickerViewModel(_ viewModel: ContactsPickerViewModelProtocol, display message: String, title: String, actions: [UIAlertAction])
}

protocol ContactsPickerViewModelProtocol {
    var coordinatorDelegate: ContactsPickerViewModelCoordinatorDelegate? { get set }
    var areParticipantsLoaded: Bool { get }
    
    func loadParticipants()
    @discardableResult func prepare(contactsViewController: RoomInviteViewController, currentSearchText: String?) -> Bool
}
