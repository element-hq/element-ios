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
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
    }
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createSpaceMemberListCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
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
        let parameters = SpaceMemberDetailCoordinatorParameters(userSessionsService: self.parameters.userSessionsService, member: member, session: self.parameters.session, spaceId: self.parameters.spaceId)
        let coordinator = SpaceMemberDetailCoordinator(parameters: parameters)
        coordinator.delegate = self
        return coordinator
    }
    
    private func navigateTo(roomWith roomId: String) {
        let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.parameters.session)
        roomDataSourceManager?.roomDataSource(forRoom: roomId, create: true, onComplete: { [weak self] roomDataSource in
            
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
}

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
