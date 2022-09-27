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

import UIKit

/// Actions returned by the coordinator callback
enum SpaceSettingsModalCoordinatorAction {
    case done(_ spaceId: String)
    case cancel(_ spaceId: String)
}

@objcMembers
final class SpaceSettingsModalCoordinator: Coordinator {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SpaceSettingsModalCoordinatorParameters
    private var upgradedRoomId: String?
    private var currentRoomId: String {
        upgradedRoomId ?? parameters.spaceId
    }
    
    private var navigationRouter: NavigationRouterType {
        parameters.navigationRouter
    }
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    var callback: ((SpaceSettingsModalCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SpaceSettingsModalCoordinatorParameters) {
        self.parameters = parameters
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[SpaceSettingsModalCoordinator] did start.")
        let rootCoordinator = createSpaceSettingsCoordinator()
        rootCoordinator.start()
        
        add(childCoordinator: rootCoordinator)
        
        if navigationRouter.modules.isEmpty == false {
            navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    func pushScreen(with coordinator: Coordinator & Presentable) {
        add(childCoordinator: coordinator)
        
        navigationRouter.push(coordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        
        coordinator.start()
    }

    private func createSpaceSettingsCoordinator() -> SpaceSettingsCoordinator {
        let coordinator = SpaceSettingsCoordinator(parameters: SpaceSettingsCoordinatorParameters(session: parameters.session, spaceId: parameters.spaceId))
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.callback?(.cancel(self.currentRoomId))
            case .done:
                self.callback?(.done(self.currentRoomId))
            case .optionScreen(let optionType):
                self.pushOptionScreen(ofType: optionType)
            }
        }
        return coordinator
    }

    private func pushOptionScreen(ofType optionType: SpaceSettingsOptionType) {
        switch optionType {
        case .rooms:
            Analytics.shared.viewRoomTrigger = .spaceSettings
            exploreRooms(ofSpaceWithId: parameters.spaceId)
        case .members:
            Analytics.shared.viewRoomTrigger = .spaceSettings
            showMembers(ofSpaceWithId: parameters.spaceId)
        case .visibility:
            showAccess(ofSpaceWithId: parameters.spaceId)
        }
    }
    
    private func exploreRooms(ofSpaceWithId spaceId: String) {
        let coordinator = ExploreRoomCoordinator(session: parameters.session, spaceId: spaceId)
        coordinator.delegate = self
        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.present(coordinator.toPresentable(), animated: true)
    }
    
    private func showMembers(ofSpaceWithId spaceId: String) {
        let coordinator = SpaceMembersCoordinator(parameters: SpaceMembersCoordinatorParameters(userSessionsService: UserSessionsService.shared, session: parameters.session, spaceId: spaceId))
        coordinator.delegate = self
        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.present(coordinator.toPresentable(), animated: true)
    }
    
    private func showAccess(ofSpaceWithId spaceId: String) {
        guard let room = parameters.session.room(withRoomId: spaceId) else {
            return
        }
        // Needed more tests on synaose side before starting space upgrade implementation
        let coordinator = RoomAccessCoordinator(parameters: RoomAccessCoordinatorParameters(room: room, parentSpaceId: parameters.parentSpaceId, allowsRoomUpgrade: false))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel(let roomId), .done(let roomId):
                if roomId != spaceId {
                    // TODO: room has been upgraded
                    self.upgradedRoomId = roomId
                }
                
                self.navigationRouter.dismissModule(animated: true, completion: {
                    self.remove(childCoordinator: coordinator)
                })
            }
        }
        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.present(coordinator.toPresentable(), animated: true)
    }
}

// MARK: - ExploreRoomCoordinatorDelegate

extension SpaceSettingsModalCoordinator: ExploreRoomCoordinatorDelegate {
    func exploreRoomCoordinatorDidComplete(_ coordinator: ExploreRoomCoordinatorType) {
        navigationRouter.dismissModule(animated: true, completion: {
            self.remove(childCoordinator: coordinator)
        })
    }
}

// MARK: - SpaceMembersCoordinatorDelegate

extension SpaceSettingsModalCoordinator: SpaceMembersCoordinatorDelegate {
    func spaceMembersCoordinatorDidCancel(_ coordinator: SpaceMembersCoordinatorType) {
        navigationRouter.dismissModule(animated: true, completion: {
            self.remove(childCoordinator: coordinator)
        })
    }
}
