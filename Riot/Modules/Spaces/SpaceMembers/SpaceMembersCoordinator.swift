// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceMembers SpaceMemberList ShowSpaceMemberList
/*
 Copyright 2021 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

struct SpaceMembersCoordinatorParameters {
    let userSessionsService: UserSessionsService
    let session: MXSession
    let spaceId: String
    let navigationRouter: NavigationRouterType
    
    init(userSessionsService: UserSessionsService,
         session: MXSession,
         spaceId: String,
         navigationRouter: NavigationRouterType = NavigationRouter(navigationController: RiotNavigationController())) {
        self.userSessionsService = userSessionsService
        self.session = session
        self.spaceId = spaceId
        self.navigationRouter = navigationRouter
    }
}

@objcMembers
final class SpaceMembersCoordinator: SpaceMembersCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceMembersCoordinatorParameters
    private let navigationRouter: NavigationRouterType
    private weak var memberDetailCoordinator: SpaceMemberDetailCoordinator?

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceMembersCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(parameters: SpaceMembersCoordinatorParameters) {
        self.parameters = parameters
        self.navigationRouter = parameters.navigationRouter
    }
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createSpaceMemberListCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        if self.navigationRouter.modules.isEmpty {
            self.navigationRouter.setRootModule(rootCoordinator)
        } else {
            self.navigationRouter.push(rootCoordinator, animated: true) {
                self.remove(childCoordinator: rootCoordinator)
            }
        }

    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    func presentMemberDetail(with member: MXRoomMember, from sourceView: UIView?) {
        let coordinator = self.createSpaceMemberDetailCoordinator(with: member)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.memberDetailCoordinator = coordinator
        
        if UIDevice.current.isPhone {
            self.navigationRouter.push(coordinator.toPresentable(), animated: true) {
                if let memberDetailCoordinator = self.memberDetailCoordinator {
                    self.remove(childCoordinator: memberDetailCoordinator)
                }
            }
        } else {
            let viewController = coordinator.toPresentable()
            viewController.modalPresentationStyle = .popover
            if let sourceView = sourceView, let popoverPresentationController = viewController.popoverPresentationController {
                popoverPresentationController.sourceView = sourceView
                popoverPresentationController.sourceRect = sourceView.bounds
            }

            self.navigationRouter.present(viewController, animated: true)
        }
    }
    
    // MARK: - Private methods

    private func createSpaceMemberListCoordinator() -> SpaceMemberListCoordinator {
        let coordinator = SpaceMemberListCoordinator(session: self.parameters.session, spaceId: self.parameters.spaceId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createSpaceMemberDetailCoordinator(with member: MXRoomMember) -> SpaceMemberDetailCoordinator {
        let parameters = SpaceMemberDetailCoordinatorParameters(userSessionsService: self.parameters.userSessionsService, member: member, session: self.parameters.session, spaceId: self.parameters.spaceId, showCancelMenuItem: false)
        let coordinator = SpaceMemberDetailCoordinator(parameters: parameters)
        coordinator.delegate = self
        return coordinator
    }
    
    private func navigateTo(roomWith roomId: String) {
        let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.parameters.session)
        roomDataSourceManager?.roomDataSource(forRoom: roomId, create: true, onComplete: { [weak self] roomDataSource in
            
            if let room = self?.parameters.session.room(withRoomId: roomId) {
                Analytics.shared.trackViewRoom(room)
            }

            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            guard let roomViewController = storyboard.instantiateViewController(withIdentifier: "RoomViewControllerStoryboardId") as? RoomViewController else {
                return
            }
            
            self?.navigationRouter.push(roomViewController, animated: true, popCompletion: nil)
            roomViewController.displayRoom(roomDataSource)
            roomViewController.navigationItem.leftItemsSupplementBackButton = true
            roomViewController.showMissedDiscussionsBadge = false
        })
    }
}

// MARK: - SpaceMemberListCoordinatorDelegate
extension SpaceMembersCoordinator: SpaceMemberListCoordinatorDelegate {
    func spaceMemberListCoordinator(_ coordinator: SpaceMemberListCoordinatorType, didSelect member: MXRoomMember, from sourceView: UIView?) {
        self.presentMemberDetail(with: member, from: sourceView)
    }
    
    func spaceMemberListCoordinatorDidCancel(_ coordinator: SpaceMemberListCoordinatorType) {
        self.delegate?.spaceMembersCoordinatorDidCancel(self)
    }
    
    func spaceMemberListCoordinatorShowInvite(_ coordinator: SpaceMemberListCoordinatorType) {
        guard let space = parameters.session.spaceService.getSpace(withId: parameters.spaceId), let spaceRoom = space.room else {
            MXLog.error("[SpaceMembersCoordinator] spaceMemberListCoordinatorShowInvite: failed to find space", context: [
                "space_id": parameters.spaceId
            ])
            return
        }
        
        spaceRoom.state { [weak self] roomState in
            guard let self = self else { return }
            
            guard let powerLevels = roomState?.powerLevels, let userId = self.parameters.session.myUserId else {
                MXLog.error("[SpaceMembersCoordinator] spaceMemberListCoordinatorShowInvite: failed to find powerLevels for room")
                return
            }
            let userPowerLevel = powerLevels.powerLevelOfUser(withUserID: userId)
            
            guard userPowerLevel >= powerLevels.invite else {
                let alert = UIAlertController(title: VectorL10n.spacesInvitePeople, message: VectorL10n.spaceInviteNotEnoughPermission, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
                self.navigationRouter.present(alert, animated: true)
                return
            }
            
            let coordinator = ContactsPickerCoordinator(session: self.parameters.session, room: spaceRoom, initialSearchText: nil, actualParticipants: nil, invitedParticipants: nil, userParticipant: nil)
            coordinator.delegate = self
            coordinator.start()
            self.childCoordinators.append(coordinator)
            self.navigationRouter.present(coordinator.toPresentable(), animated: true)
        }
    }
}

// MARK: - ContactsPickerCoordinatorDelegate
extension SpaceMembersCoordinator: ContactsPickerCoordinatorDelegate {
    func contactsPickerCoordinatorDidStartLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidEndLoading(_ coordinator: ContactsPickerCoordinatorProtocol) {
    }
    
    func contactsPickerCoordinatorDidClose(_ coordinator: ContactsPickerCoordinatorProtocol) {
        remove(childCoordinator: coordinator)
    }
}

// MARK: - SpaceMemberDetailCoordinatorDelegate
extension SpaceMembersCoordinator: SpaceMemberDetailCoordinatorDelegate {
    func spaceMemberDetailCoordinator(_ coordinator: SpaceMemberDetailCoordinatorType, showRoomWithId roomId: String) {
        if !UIDevice.current.isPhone, let memberDetailCoordinator = self.memberDetailCoordinator {
            memberDetailCoordinator.toPresentable().dismiss(animated: true, completion: {
                self.memberDetailCoordinator = nil
                self.navigateTo(roomWith: roomId)
            })
        } else {
            self.navigateTo(roomWith: roomId)
        }
    }
    
    func spaceMemberDetailCoordinatorDidCancel(_ coordinator: SpaceMemberDetailCoordinatorType) {
        self.delegate?.spaceMembersCoordinatorDidCancel(self)
    }
}
