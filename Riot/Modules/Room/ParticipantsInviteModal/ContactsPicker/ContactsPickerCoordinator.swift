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

class ContactsPickerCoordinator: ContactsPickerCoordinatorProtocol {
    
    private weak var currentAlert: UIAlertController?

    // MARK: - Private

    private let session: MXSession?
    private let room: MXRoom?
    private let initialSearchText: String?
    private var actualParticipants: [Contact]?
    private var invitedParticipants: [Contact]?
    private var userParticipant: Contact?

    private let navigationRouter: NavigationRouterType
    private weak var contactsPickerViewController: ContactsTableViewController?
    private var viewModel: ContactsPickerViewModelProtocol?

    // MARK: Public

    internal var childCoordinators: [Coordinator] = []
    weak var delegate: ContactsPickerCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, room: MXRoom, initialSearchText: String?, actualParticipants: [Contact]?, invitedParticipants: [Contact]?, userParticipant: Contact?, navigationRouter: NavigationRouterType? = nil) {
        self.session = session
        self.room = room
        self.initialSearchText = initialSearchText
        
        self.actualParticipants = actualParticipants
        self.invitedParticipants = invitedParticipants
        self.userParticipant = userParticipant
        
        if let navigationRouter = navigationRouter {
            self.navigationRouter = navigationRouter
        } else {
            self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        }
    }
    
    // MARK: - Public methods
    
    func start() {
        guard let room = self.room else {
            MXLog.error("[ContactsCoordinator] start: no room")
            return
        }
        
        let viewModel = ContactsPickerViewModel(room: room, actualParticipants: self.actualParticipants, invitedParticipants: self.invitedParticipants, userParticipant: self.userParticipant)
        viewModel.coordinatorDelegate = self
        self.viewModel = viewModel
        
        guard viewModel.areParticipantsLoaded else {
            viewModel.loadParticipants()
            return
        }

        startWithParticipants()
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func startWithParticipants() {
        // Push the contacts picker.
        let contactsViewController = RoomInviteViewController()
        viewModel?.prepare(contactsViewController: contactsViewController, currentSearchText: initialSearchText)
        self.navigationRouter.push(contactsViewController, animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.contactsPickerCoordinatorDidClose(self)
        }
        contactsPickerViewController = contactsViewController
    }
}

// MARK: - ContactsViewModelCoordinatorDelegate

extension ContactsPickerCoordinator: ContactsPickerViewModelCoordinatorDelegate {
    func contactsPickerViewModelDidStartLoading(_ viewModel: ContactsPickerViewModelProtocol) {
        delegate?.contactsPickerCoordinatorDidStartLoading(self)
    }
    
    func contactsPickerViewModelDidEndLoading(_ viewModel: ContactsPickerViewModelProtocol) {
        delegate?.contactsPickerCoordinatorDidEndLoading(self)
        startWithParticipants()
    }
    
    func contactsPickerViewModelDidStartInvite(_ viewModel: ContactsPickerViewModelProtocol) {
        contactsPickerViewController?.startActivityIndicator()
    }
    
    func contactsPickerViewModelDidEndInvite(_ viewModel: ContactsPickerViewModelProtocol) {
        contactsPickerViewController?.stopActivityIndicator()
        contactsPickerViewController?.withdrawViewController(animated: true, completion: {
            self.delegate?.contactsPickerCoordinatorDidClose(self)
        })
    }
    
    func contactsPickerViewModel(_ viewModel: ContactsPickerViewModelProtocol, inviteFailedWithError error: Error?) {
        contactsPickerViewController?.stopActivityIndicator()
        if let error = error {
            AppDelegate.theDelegate().showError(asAlert: error)
        }
    }
    
    func contactsPickerViewModel(_ viewModel: ContactsPickerViewModelProtocol, display message: String, title: String, actions: [UIAlertAction]) {
        currentAlert?.dismiss(animated: false, completion: nil)
        currentAlert = nil
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        
        alert.mxk_setAccessibilityIdentifier("RoomParticipantsVCInviteAlert")
        navigationRouter.present(alert, animated: true)
        
        currentAlert = alert
    }
}
