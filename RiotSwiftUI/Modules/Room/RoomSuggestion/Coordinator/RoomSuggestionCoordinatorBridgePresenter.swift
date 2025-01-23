//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import UIKit

@objc protocol RoomSuggestionCoordinatorBridgePresenterDelegate {
    func roomSuggestionCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: RoomSuggestionCoordinatorBridgePresenter)
    func roomSuggestionCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: RoomSuggestionCoordinatorBridgePresenter)
}

/// RoomSuggestionCoordinatorBridgePresenter enables to start RoomSuggestionCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class RoomSuggestionCoordinatorBridgePresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let room: MXRoom
    private var coordinator: RoomSuggestionCoordinator?
    
    // MARK: Public
    
    weak var delegate: RoomSuggestionCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(room: MXRoom) {
        self.room = room
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let navigationRouter = NavigationRouter()
        let coordinator = RoomSuggestionCoordinator(parameters: RoomSuggestionCoordinatorParameters(room: room, navigationRouter: navigationRouter))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.delegate?.roomSuggestionCoordinatorBridgePresenterDelegateDidCancel(self)
            case .done:
                self.delegate?.roomSuggestionCoordinatorBridgePresenterDelegateDidComplete(self)
            }
        }
        let presentable = coordinator.toPresentable()
        presentable.presentationController?.delegate = self
        navigationRouter.setRootModule(presentable)
        viewController.present(navigationRouter.toPresentable(), animated: animated, completion: nil)
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RoomSuggestionCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    func roomNotificationSettingsCoordinatorDidComplete(_ presentationController: UIPresentationController) {
        delegate?.roomSuggestionCoordinatorBridgePresenterDelegateDidCancel(self)
    }
}
