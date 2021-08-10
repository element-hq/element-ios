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
    
    // MARK: - Private methods

    private func createShowSpaceMemberListCoordinator() -> ShowSpaceMemberListCoordinator {
        let coordinator = ShowSpaceMemberListCoordinator(session: self.session, spaceId: self.spaceId)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - ShowSpaceMemberListCoordinatorDelegate
extension SpaceMemberListCoordinator: ShowSpaceMemberListCoordinatorDelegate {
    func showSpaceMemberListCoordinator(_ coordinator: ShowSpaceMemberListCoordinatorType, didCompleteWithUserDisplayName userDisplayName: String?) {
        self.delegate?.spaceMemberListCoordinatorDidComplete(self)
    }
    
    func showSpaceMemberListCoordinatorDidCancel(_ coordinator: ShowSpaceMemberListCoordinatorType) {
        self.delegate?.spaceMemberListCoordinatorDidComplete(self)
    }
}
