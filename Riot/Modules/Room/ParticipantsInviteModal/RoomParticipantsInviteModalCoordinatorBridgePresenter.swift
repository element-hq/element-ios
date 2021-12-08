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

@objc protocol RoomParticipantsInviteCoordinatorBridgePresenterDelegate {
    func roomParticipantsInviteCoordinatorBridgePresenterDidStartLoading(_ coordinatorBridgePresenter: RoomParticipantsInviteCoordinatorBridgePresenter)
    func roomParticipantsInviteCoordinatorBridgePresenterDidEndLoading(_ coordinatorBridgePresenter: RoomParticipantsInviteCoordinatorBridgePresenter)
    func roomParticipantsInviteCoordinatorBridgePresenterDidComplete(_ coordinatorBridgePresenter: RoomParticipantsInviteCoordinatorBridgePresenter)
}

/// RoomParticipantsInviteCoordinatorBridgePresenter enables to start ContactsPickerCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class RoomParticipantsInviteCoordinatorBridgePresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession?
    private let room: MXRoom?
    private let parentSpaceId: String?
    private let currentSearchText: String?
    private var actualParticipants: [Contact]?
    private var invitedParticipants: [Contact]?
    private var userParticipant: Contact?

    private weak var contactsPickerViewController: ContactsTableViewController?
    private weak var currentAlert: UIAlertController?
    private var contactPickerCoordinator: ContactsPickerCoordinator?

    // MARK: Public
    
    weak var delegate: RoomParticipantsInviteCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession?, room: MXRoom?, parentSpaceId: String?) {
        self.session = session
        self.room = room
        self.parentSpaceId = parentSpaceId
        self.currentSearchText = nil
        self.actualParticipants = nil
        self.invitedParticipants = nil
        self.userParticipant = nil

        super.init()
    }
    
    init(session: MXSession?, room: MXRoom?, parentSpaceId: String?, currentSearchText: String? = nil, actualParticipants: [Contact]? = nil, invitedParticipants: [Contact]? = nil, userParticipant: Contact? = nil) {
        self.session = session
        self.room = room
        self.parentSpaceId = parentSpaceId
        self.currentSearchText = currentSearchText
        self.actualParticipants = actualParticipants
        self.invitedParticipants = invitedParticipants
        self.userParticipant = userParticipant
        
        super.init()
    }

    func present(from viewController: UIViewController, animated: Bool) {
        guard let room = self.room else {
            MXLog.error("[RoomParticipantsInviteCoordinatorBridgePresenter] present: nil room found")
            return
        }
        
        if let spaceId = self.parentSpaceId, let spaceRoom = session?.spaceService.getSpace(withId: spaceId)?.room {
            presentRoomSelector(between: room, and: spaceRoom, from: viewController)
            return
        }
        
        pushContactsPicker(for: room, from: viewController)
    }
    
    // MARK: - Private
    
    private func presentRoomSelector(between room: MXRoom, and spaceRoom: MXRoom, from viewController: UIViewController) {
        let alert = UIAlertController(title: VectorL10n.roomIntroCellAddParticipantsAction, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "To \(spaceRoom.displayName ?? "space")", style: .default) { [weak self] action in
            self?.pushContactsPicker(for: spaceRoom, from: viewController)
        })
        alert.addAction(UIAlertAction(title: "To just this room", style: .destructive) { [weak self] (action) in
            self?.pushContactsPicker(for: room, from: viewController)
        })
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
    private func pushContactsPicker(for room: MXRoom, from viewController: UIViewController) {
        guard let session = self.session else {
            MXLog.error("[RoomParticipantsInviteCoordinatorBridgePresenter] pushContactsPicker: nil session found")
            return
        }
        
        let navigationRouter: NavigationRouterType?
        if let navigationController = viewController.navigationController {
            navigationRouter = NavigationRouterStore.shared.findNavigationRouter(for: navigationController) ?? NavigationRouter(navigationController: navigationController)
        } else {
            navigationRouter = nil
        }
        
        let coordinator = ContactsPickerCoordinator(session: session, room: room, currentSearchText: currentSearchText, actualParticipants: actualParticipants, invitedParticipants: invitedParticipants, userParticipant: userParticipant, navigationRouter: navigationRouter)
        coordinator.delegate = self
        coordinator.start()
        
        self.contactPickerCoordinator = coordinator
    }
}

extension RoomParticipantsInviteCoordinatorBridgePresenter: ContactsPickerCoordinatorDelegate {
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorType) {
        delegate?.roomParticipantsInviteCoordinatorBridgePresenterDidStartLoading(self)
    }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorType) {
        delegate?.roomParticipantsInviteCoordinatorBridgePresenterDidEndLoading(self)
    }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorType) {
        delegate?.roomParticipantsInviteCoordinatorBridgePresenterDidComplete(self)
    }
}
