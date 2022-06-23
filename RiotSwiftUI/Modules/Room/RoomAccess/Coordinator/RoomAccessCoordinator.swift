// File created from FlowTemplate
// $ createRootCoordinator.sh RoomAccessCoordinator RoomAccess
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

/// Actions returned by the coordinator callback
enum RoomAccessCoordinatorCoordinatorAction {
    case done(String)
    case cancel(String)
}

@objcMembers
final class RoomAccessCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomAccessCoordinatorParameters
    private var upgradedRoomId: String?
    
    private var navigationRouter: NavigationRouterType {
        return self.parameters.navigationRouter
    }
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    var callback: ((RoomAccessCoordinatorCoordinatorAction) -> Void)?
    
    var currentRoomId: String {
        if let upgradedRoomId = upgradedRoomId {
            return upgradedRoomId
        }
        return parameters.room.roomId
    }
    
    private weak var accessCoordinator: RoomAccessTypeChooserCoordinator?
    
    // MARK: - Setup
    
    init(parameters: RoomAccessCoordinatorParameters) {
        self.parameters = parameters
    }    
    
    // MARK: - Public
    
    
    func start() {
        MXLog.debug("[RoomAccessCoordinator] did start.")
        let rootCoordinator = self.createRoomAccessTypeCoordinator()
        rootCoordinator.start()
        
        self.add(childCoordinator: rootCoordinator)
        self.accessCoordinator = rootCoordinator
        
        if self.navigationRouter.modules.isEmpty == false {
            self.navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            })
        } else {
            self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private
    
    func pushScreen(with coordinator: Coordinator & Presentable) {
        add(childCoordinator: coordinator)
        
        self.navigationRouter.push(coordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: coordinator)
        })
        
        coordinator.start()
    }

    func popupScreen(with coordinator: Coordinator & Presentable) {
        add(childCoordinator: coordinator)
        
        coordinator.toPresentable().modalPresentationStyle = .overFullScreen
        coordinator.toPresentable().modalTransitionStyle = .crossDissolve
        self.navigationRouter.present(coordinator, animated: true)
        
        coordinator.start()
    }

    private func createRoomAccessTypeCoordinator() -> RoomAccessTypeChooserCoordinator {
        let coordinator: RoomAccessTypeChooserCoordinator = RoomAccessTypeChooserCoordinator(parameters: RoomAccessTypeChooserCoordinatorParameters(roomId: parameters.room.roomId, allowsRoomUpgrade: parameters.allowsRoomUpgrade, session: parameters.room.mxSession))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .done(let roomId):
                self.callback?(.done(roomId))
            case .cancel(let roomId):
                self.callback?(.cancel(roomId))
            case .spaceSelection(let roomId, _):
                self.upgradedRoomId = roomId
                self.pushScreen(with: self.createRestrictedAccessSpaceChooserCoordinator(with: roomId))
            case .roomUpgradeNeeded(let roomId, let versionOverride):
                self.popupScreen(with: self.createUpgradeRoomCoordinator(withRoomWithId: roomId, to: versionOverride))
            }
        }
        return coordinator
    }
    
    private func createRestrictedAccessSpaceChooserCoordinator(with roomId: String) -> MatrixItemChooserCoordinator {
        let paramaters = MatrixItemChooserCoordinatorParameters(
            session: parameters.room.mxSession,
            viewProvider: RoomRestrictedAccessSpaceChooserViewProvider(navTitle: VectorL10n.roomAccessSettingsScreenNavTitle),
            itemsProcessor: RoomRestrictedAccessSpaceChooserItemsProcessor(roomId: roomId, session: parameters.room.mxSession))
        let coordinator = MatrixItemChooserCoordinator(parameters: paramaters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .back:
                self.navigationRouter.popModule(animated: true)
            case .cancel:
                self.callback?(.cancel(roomId))
            case .done:
                self.callback?(.done(roomId))
            }
        }
        return coordinator
    }

    private func createUpgradeRoomCoordinator(withRoomWithId roomId: String, to versionOverride: String) -> RoomUpgradeCoordinator {
        let paramaters = RoomUpgradeCoordinatorParameters(
            session: parameters.room.mxSession,
            roomId: roomId,
            parentSpaceId: parameters.parentSpaceId,
            versionOverride: versionOverride)
        let coordinator = RoomUpgradeCoordinator(parameters: paramaters)
        
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            self.accessCoordinator?.handleRoomUpgradeResult(result)
            
            self.navigationRouter.dismissModule(animated: true) {
                self.remove(childCoordinator: coordinator)
            }
        }

        return coordinator
    }
}
