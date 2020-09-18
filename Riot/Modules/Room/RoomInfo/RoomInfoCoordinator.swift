// File created from FlowTemplate
// $ createRootCoordinator.sh Room2 RoomInfo RoomInfoList
/*
 Copyright 2020 New Vector Ltd
 
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
final class RoomInfoCoordinator: RoomInfoCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let room: MXRoom
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomInfoCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, room: MXRoom) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.room = room
    }    
    
    // MARK: - Public methods
    
    func start() {
        let rootCoordinator = self.createRoomInfoListCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createRoomInfoListCoordinator() -> RoomInfoListCoordinator {
        let coordinator = RoomInfoListCoordinator(session: self.session, room: room)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - RoomInfoListCoordinatorDelegate
extension RoomInfoCoordinator: RoomInfoListCoordinatorDelegate {
    
    func roomInfoListCoordinator(_ coordinator: RoomInfoListCoordinatorType, wantsToNavigate viewController: UIViewController) {
        let coordinator = BasicCoordinator(withViewController: viewController)
        coordinator.start()
        
        self.add(childCoordinator: coordinator)
        navigationRouter.push(coordinator, animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }

    func roomInfoListCoordinatorDidCancel(_ coordinator: RoomInfoListCoordinatorType) {
        self.delegate?.roomInfoCoordinatorDidComplete(self)
    }

}

class BasicCoordinator: Coordinator {
    
    private let viewController: UIViewController
    
    init(withViewController viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func start() {
        
    }
    
    var childCoordinators: [Coordinator] = []
    
}

extension BasicCoordinator: Presentable {
    
    func toPresentable() -> UIViewController {
        return viewController
    }
    
}
