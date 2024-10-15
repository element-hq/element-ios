/*
Copyright 2021-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
