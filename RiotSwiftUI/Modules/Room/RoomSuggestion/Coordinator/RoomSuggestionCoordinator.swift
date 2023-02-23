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
enum RoomSuggestionCoordinatorCoordinatorAction {
    case done
    case cancel
}

@objcMembers
final class RoomSuggestionCoordinator: Coordinator {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomSuggestionCoordinatorParameters
    
    private var navigationRouter: NavigationRouterType {
        parameters.navigationRouter
    }
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    var callback: ((RoomSuggestionCoordinatorCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: RoomSuggestionCoordinatorParameters) {
        self.parameters = parameters
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[RoomSuggestionCoordinator] did start.")
        let rootCoordinator = createRoomSuggestionSpaceChooser()
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
    
    private func createRoomSuggestionSpaceChooser() -> MatrixItemChooserCoordinator {
        let paramaters = MatrixItemChooserCoordinatorParameters(
            session: parameters.room.mxSession,
            title: VectorL10n.roomSuggestionSettingsScreenTitle,
            detail: VectorL10n.roomSuggestionSettingsScreenMessage,
            viewProvider: RoomSuggestionSpaceChooserViewProvider(navTitle: VectorL10n.roomAccessSettingsScreenNavTitle),
            itemsProcessor: RoomSuggestionSpaceChooserItemsProcessor(roomId: parameters.room.roomId, session: parameters.room.mxSession)
        )
        let coordinator = MatrixItemChooserCoordinator(parameters: paramaters)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .back:
                self.navigationRouter.popModule(animated: true)
            case .cancel:
                self.callback?(.cancel)
            case .done:
                self.callback?(.done)
            }
        }
        return coordinator
    }
}
