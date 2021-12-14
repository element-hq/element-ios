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
    private var roomOptions: [RoomOptionListItemViewData] = []

    private weak var contactsPickerViewController: ContactsTableViewController?
    private weak var currentAlert: UIAlertController?
    private var contactPickerCoordinator: ContactsPickerCoordinator?
    private var optionListCoordinator: OptionListCoordinator?
    private var navigationRouter: NavigationRouterType?

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
        
        if let navigationController = viewController.navigationController {
            navigationRouter = NavigationRouterStore.shared.findNavigationRouter(for: navigationController) ?? NavigationRouter(navigationController: navigationController)
        } else {
            navigationRouter = nil
        }

        if let spaceId = self.parentSpaceId, let spaceRoom = session?.spaceService.getSpace(withId: spaceId)?.room {
            presentRoomSelector(between: room, and: spaceRoom)
            return
        }
        
        pushContactsPicker(for: room)
    }
    
    // MARK: - Private
    
    private class RoomOptionListItemViewData: OptionListItemViewData {
        let room: MXRoom
        
        init(title: String? = nil,
             detail: String? = nil,
             image: UIImage? = nil,
             room: MXRoom,
             accessoryImage: UIImage? = Asset.Images.chevron.image) {
            self.room = room
            super.init(title: title, detail: detail, image: image, accessoryImage: accessoryImage)
        }
    }
    
    private func presentRoomSelector(between room: MXRoom, and spaceRoom: MXRoom) {
        let roomName = room.displayName ?? ""
        let spaceName = spaceRoom.displayName ?? ""
        roomOptions = [
            RoomOptionListItemViewData(title: VectorL10n.roomInviteToSpaceOptionTitle(spaceName),
                                       detail: VectorL10n.roomInviteToSpaceOptionDetail(spaceName, roomName),
                                       image: Asset.Images.addParticipants.image, room: spaceRoom),
            RoomOptionListItemViewData(title: VectorL10n.roomInviteToRoomOptionTitle,
                                       detail: VectorL10n.roomInviteToRoomOptionDetail(spaceName),
                                       image: Asset.Images.addParticipants.image, room: room)
        ]
        optionListCoordinator = OptionListCoordinator(parameters: OptionListCoordinatorParameters(title: VectorL10n.roomIntroCellAddParticipantsAction, options: roomOptions, navigationRouter: navigationRouter))
        optionListCoordinator?.delegate = self
        optionListCoordinator?.start()
    }
    
    private func pushContactsPicker(for room: MXRoom) {
        guard let session = self.session else {
            MXLog.error("[RoomParticipantsInviteCoordinatorBridgePresenter] pushContactsPicker: nil session found")
            return
        }
        
        let coordinator = ContactsPickerCoordinator(session: session,
                                                    room: room,
                                                    currentSearchText: currentSearchText,
                                                    actualParticipants: actualParticipants,
                                                    invitedParticipants: invitedParticipants,
                                                    userParticipant: userParticipant,
                                                    navigationRouter: navigationRouter)
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

extension RoomParticipantsInviteCoordinatorBridgePresenter: OptionListCoordinatorDelegate {
    func optionListCoordinator(_ coordinator: OptionListCoordinatorProtocol, didSelectOptionAt index: Int) {
        optionListCoordinator = nil
        self.pushContactsPicker(for: roomOptions[index].room)
    }
    
    func optionListCoordinator(_ coordinator: OptionListCoordinatorProtocol, didCompleteWithUserDisplayName userDisplayName: String?) {
        optionListCoordinator = nil
    }
    
    func optionListCoordinatorDidCancel(_ coordinator: OptionListCoordinatorProtocol) {
        optionListCoordinator = nil
    }
}
