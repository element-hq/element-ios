//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            self.navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        } else {
            self.navigationRouter = nil
        }

        if let spaceId = self.parentSpaceId, let spaceRoom = self.session?.spaceService.getSpace(withId: spaceId)?.room {
            self.presentRoomSelector(between: room, and: spaceRoom)
            return
        }
        
        self.pushContactsPicker(for: room)
    }
    
    // MARK: - Private
    
    private class RoomOptionListItemViewData: OptionListItemViewData {
        let room: MXRoom
        
        init(title: String? = nil,
             detail: String? = nil,
             image: UIImage? = nil,
             room: MXRoom,
             accessoryImage: UIImage? = Asset.Images.chevron.image,
             enabled: Bool = true) {
            self.room = room
            super.init(title: title, detail: detail, image: image, accessoryImage: accessoryImage, enabled: enabled)
        }
    }
    
    private func presentRoomSelector(between room: MXRoom, and spaceRoom: MXRoom) {
        let roomName = room.displayName ?? ""
        let spaceName = spaceRoom.displayName ?? ""
        
        self.roomOptions = [
            RoomOptionListItemViewData(title: VectorL10n.roomInviteToSpaceOptionTitle(spaceName),
                                       detail: VectorL10n.roomInviteToSpaceOptionDetail(spaceName, roomName),
                                       image: Asset.Images.addParticipants.image, room: spaceRoom,
                                       accessoryImage: Asset.Images.chevron.image),
            RoomOptionListItemViewData(title: VectorL10n.roomInviteToRoomOptionTitle,
                                       detail: VectorL10n.roomInviteToRoomOptionDetail(spaceName),
                                       image: Asset.Images.addParticipants.image, room: room,
                                       accessoryImage: Asset.Images.chevron.image)
        ]
        
        let coordinator = OptionListCoordinator(parameters: OptionListCoordinatorParameters(title: VectorL10n.roomIntroCellAddParticipantsAction, options: self.roomOptions, navigationRouter: self.navigationRouter))
        coordinator.delegate = self
        coordinator.start()
        
        self.optionListCoordinator = coordinator
    }
    
    private func pushContactsPicker(for room: MXRoom) {
        guard let session = self.session else {
            MXLog.error("[RoomParticipantsInviteCoordinatorBridgePresenter] pushContactsPicker: nil session found")
            return
        }
        
        canInvite(to: room) { [weak self] canInvite in
            guard let self = self else { return }
            
            guard canInvite else {
                let message = room.summary?.roomType == .space ? VectorL10n.spaceInviteNotEnoughPermission : VectorL10n.roomInviteNotEnoughPermission
                let alert = UIAlertController(title: VectorL10n.spacesInvitePeople, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
                self.navigationRouter?.present(alert, animated: true)
                return
            }
            
            let coordinator = ContactsPickerCoordinator(session: session,
                                                        room: room,
                                                        initialSearchText: self.currentSearchText,
                                                        actualParticipants: self.actualParticipants,
                                                        invitedParticipants: self.invitedParticipants,
                                                        userParticipant: self.userParticipant,
                                                        navigationRouter: self.navigationRouter)
            coordinator.delegate = self
            coordinator.start()
            
            self.contactPickerCoordinator = coordinator
        }
    }
    
    private func canInvite(to room: MXRoom, completion: @escaping (Bool) -> Void) {
        guard let userId = self.session?.myUserId else {
            MXLog.error("[RoomParticipantsInviteCoordinatorBridgePresenter] canInvite: userId not found")
            completion(false)
            return
        }

        room.state { roomState in
            guard let powerLevels = roomState?.powerLevels else {
                MXLog.error("[RoomParticipantsInviteCoordinatorBridgePresenter] canInvite: room powerLevels not found")
                completion(false)
                return
            }
            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: userId)
            
            completion(userPowerLevel >= powerLevels.invite)
        }
    }
}

extension RoomParticipantsInviteCoordinatorBridgePresenter: ContactsPickerCoordinatorDelegate {
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
        delegate?.roomParticipantsInviteCoordinatorBridgePresenterDidStartLoading(self)
    }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
        delegate?.roomParticipantsInviteCoordinatorBridgePresenterDidEndLoading(self)
    }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol) {
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
