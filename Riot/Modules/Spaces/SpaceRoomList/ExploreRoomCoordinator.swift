// File created from FlowTemplate
// $ createRootCoordinator.sh Spaces/SpaceRoomList ExploreRoom ShowSpaceExploreRoom
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
final class ExploreRoomCoordinator: ExploreRoomCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    private let spaceId: String
    private weak var roomDetailCoordinator: ShowSpaceChildRoomDetailCoordinator?

    private lazy var slidingModalPresenter: SlidingModalPresenter = {
        return SlidingModalPresenter()
    }()

    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ExploreRoomCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, spaceId: String) {
        self.navigationRouter = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.spaceId = spaceId
    }
    
    // MARK: - Public methods
    
    func start() {

        let rootCoordinator = self.createShowSpaceExploreRoomCoordinator(session: self.session, spaceId: self.spaceId, spaceName: self.session.spaceService.getSpace(withId: self.spaceId)?.summary?.displayname)

        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        self.navigationRouter.setRootModule(rootCoordinator)
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    func pushSpace(with item: SpaceExploreRoomListItemViewData) {
        let coordinator = self.createShowSpaceExploreRoomCoordinator(session: self.session, spaceId: item.childInfo.childRoomId, spaceName: item.childInfo.name)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.navigationRouter.push(coordinator.toPresentable(), animated: true) {
            self.remove(childCoordinator: coordinator)
        }
    }
    
    func presentRoom(with item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        if let currentCoordinator = self.roomDetailCoordinator {
            self.remove(childCoordinator: currentCoordinator)
        }

        let coordinator = self.createShowSpaceRoomDetailCoordinator(session: self.session, childInfo: item.childInfo)
        coordinator.start()
        self.add(childCoordinator: coordinator)
        self.roomDetailCoordinator = coordinator
        
        if UIDevice.current.isPhone {
            slidingModalPresenter.present(coordinator.toSlidingPresentable(), from: self.navigationRouter.toPresentable(), animated: true, completion: nil)
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

    private func createShowSpaceExploreRoomCoordinator(session: MXSession, spaceId: String, spaceName: String?) -> ShowSpaceExploreRoomCoordinator {
        let coordinator = ShowSpaceExploreRoomCoordinator(session: session, spaceId: spaceId, spaceName: spaceName)
        coordinator.delegate = self
        return coordinator
    }
    
    private func createShowSpaceRoomDetailCoordinator(session: MXSession, childInfo: MXSpaceChildInfo) -> ShowSpaceChildRoomDetailCoordinator {
        let coordinator = ShowSpaceChildRoomDetailCoordinator(session: session, childInfo: childInfo)
        coordinator.delegate = self
        return coordinator
    }
}

// MARK: - ShowSpaceExploreRoomCoordinatorDelegate
extension ExploreRoomCoordinator: ShowSpaceExploreRoomCoordinatorDelegate {
    func showSpaceExploreRoomCoordinator(_ coordinator: ShowSpaceExploreRoomCoordinatorType, didSelect item: SpaceExploreRoomListItemViewData, from sourceView: UIView?) {
        self.delegate?.exploreRoomCoordinatorDidComplete(self, withSelectedIem: item, from: sourceView)
    }
    
    func showSpaceExploreRoomCoordinatorDidCancel(_ coordinator: ShowSpaceExploreRoomCoordinatorType) {
        self.delegate?.exploreRoomCoordinatorDidComplete(self, withSelectedIem: nil, from: nil)
    }
}

// MARK: - ShowSpaceChildRoomDetailCoordinator
extension ExploreRoomCoordinator: ShowSpaceChildRoomDetailCoordinatorDelegate {
    func showSpaceChildRoomDetailCoordinator(_ coordinator: ShowSpaceChildRoomDetailCoordinatorType, didCompleteWithUserDisplayName userDisplayName: String?) {
        if UIDevice.current.isPhone {
            self.delegate?.exploreRoomCoordinatorDidComplete(self, withSelectedIem: nil, from: nil)
        } else {
            self.navigationRouter.toPresentable().dismiss(animated: true) {
                if let lastCoordinator = self.roomDetailCoordinator {
                    self.remove(childCoordinator: lastCoordinator)
                }
            }
        }
    }
    
    func showSpaceChildRoomDetailCoordinatorDidCancel(_ coordinator: ShowSpaceChildRoomDetailCoordinatorType) {
        self.delegate?.exploreRoomCoordinatorDidComplete(self, withSelectedIem: nil, from: nil)
    }
}
