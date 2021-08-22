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

@objcMembers
final class SpaceMemberListCoordinator: SpaceMemberListCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let spaceId: String
    private weak var memberDetailCoordinator: ShowSpaceMemberDetailCoordinator?

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: SpaceMemberListCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.spaceId = spaceId
    }    
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createShowSpaceMemberListCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    func presentMemberDetail(with member: MXRoomMember, from sourceView: UIView?) {
        let coordinator = self.createShowSpaceMemberDetailCoordinator(with: member)
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

    private func createShowSpaceMemberListCoordinator() -> ShowSpaceMemberListCoordinator {
        let coordinator = ShowSpaceMemberListCoordinator(session: self.session, spaceId: self.spaceId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createShowSpaceMemberDetailCoordinator(with member: MXRoomMember) -> ShowSpaceMemberDetailCoordinator {
        let coordinator = ShowSpaceMemberDetailCoordinator(session: self.session, member: member, spaceId: self.spaceId)
        coordinator.delegate = self
        return coordinator
    }
    
    private func navigateTo(roomWith roomId: String) {
        let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
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

// MARK: - ShowSpaceMemberListCoordinatorDelegate
extension SpaceMemberListCoordinator: ShowSpaceMemberListCoordinatorDelegate {
    func showSpaceMemberListCoordinator(_ coordinator: ShowSpaceMemberListCoordinatorType, didSelect member: MXRoomMember, from sourceView: UIView?) {
        self.delegate?.spaceMemberListCoordinator(self, didSelect: member, from: sourceView)
    }
    
    func showSpaceMemberListCoordinatorDidCancel(_ coordinator: ShowSpaceMemberListCoordinatorType) {
        self.delegate?.spaceMemberListCoordinatorDidCancel(self)
    }
}

extension SpaceMemberListCoordinator: ShowSpaceMemberDetailCoordinatorDelegate {
    func showSpaceMemberDetailCoordinator(_ coordinator: ShowSpaceMemberDetailCoordinatorType, showRoomWithId roomId: String) {
        if !UIDevice.current.isPhone, let memberDetailCoordinator = self.memberDetailCoordinator {
            memberDetailCoordinator.toPresentable().dismiss(animated: true, completion: {
                self.memberDetailCoordinator = nil
                self.navigateTo(roomWith: roomId)
            })
        } else {
            self.navigateTo(roomWith: roomId)
        }
    }
    
    func showSpaceMemberDetailCoordinatorDidCancel(_ coordinator: ShowSpaceMemberDetailCoordinatorType) {
        self.delegate?.spaceMemberListCoordinatorDidCancel(self)
    }
}
