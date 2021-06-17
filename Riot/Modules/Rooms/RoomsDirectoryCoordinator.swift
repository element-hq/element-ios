// File created from FlowTemplate
// $ createRootCoordinator.sh Rooms2 RoomsDirectory ShowDirectory
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
final class RoomsDirectoryCoordinator: RoomsDirectoryCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let dataSource: PublicRoomsDirectoryDataSource
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomsDirectoryCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, dataSource: PublicRoomsDirectoryDataSource) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.dataSource = dataSource
    }    
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createShowDirectoryCoordinator()

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
      }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods

    private func createShowDirectoryCoordinator() -> ShowDirectoryCoordinator {
        let coordinator = ShowDirectoryCoordinator(session: self.session, dataSource: dataSource)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - ShowDirectoryCoordinatorDelegate
extension RoomsDirectoryCoordinator: ShowDirectoryCoordinatorDelegate {
    
    func showDirectoryCoordinator(_ coordinator: ShowDirectoryCoordinatorType, didSelectRoom room: MXPublicRoom) {
        self.delegate?.roomsDirectoryCoordinator(self, didSelectRoom: room)
    }
    
    func showDirectoryCoordinatorDidTapCreateNewRoom(_ coordinator: ShowDirectoryCoordinatorType) {
        self.delegate?.roomsDirectoryCoordinatorDidTapCreateNewRoom(self)
    }
    
    func showDirectoryCoordinatorDidCancel(_ coordinator: ShowDirectoryCoordinatorType) {
        self.delegate?.roomsDirectoryCoordinatorDidComplete(self)
    }
    
    func showDirectoryCoordinatorWantsToShow(_ coordinator: ShowDirectoryCoordinatorType, viewController: UIViewController) {
        toPresentable().present(RiotNavigationController(rootViewController: viewController), animated: true, completion: nil)
    }
    
    func showDirectoryCoordinator(_ coordinator: ShowDirectoryCoordinatorType, didSelectRoomWithIdOrAlias roomIdOrAlias: String) {
        self.delegate?.roomsDirectoryCoordinator(self, didSelectRoomWithIdOrAlias: roomIdOrAlias)
    }
}
