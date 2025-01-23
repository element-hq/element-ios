//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

@objc protocol SpaceSettingsModalCoordinatorBridgePresenterDelegate {
    func spaceSettingsModalCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: SpaceSettingsModalCoordinatorBridgePresenter)
    func spaceSettingsModalCoordinatorBridgePresenterDelegateDidFinish(_ coordinatorBridgePresenter: SpaceSettingsModalCoordinatorBridgePresenter)
}

/// SpaceSettingsModalCoordinatorBridgePresenter enables to start SpaceSettingsModalCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class SpaceSettingsModalCoordinatorBridgePresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let spaceId: String
    private let session: MXSession
    private let parentSpaceId: String?
    private var coordinator: SpaceSettingsModalCoordinator?
    
    // MARK: Public
    
    weak var delegate: SpaceSettingsModalCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(spaceId: String, parentSpaceId: String?, session: MXSession) {
        self.spaceId = spaceId
        self.parentSpaceId = parentSpaceId
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let navigationRouter = NavigationRouter()
        let coordinator = SpaceSettingsModalCoordinator(parameters: SpaceSettingsModalCoordinatorParameters(session: session, spaceId: spaceId, parentSpaceId: parentSpaceId, navigationRouter: navigationRouter))
        coordinator.callback = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .cancel:
                self.delegate?.spaceSettingsModalCoordinatorBridgePresenterDelegateDidCancel(self)
            case .done:
                self.delegate?.spaceSettingsModalCoordinatorBridgePresenterDelegateDidFinish(self)
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

extension SpaceSettingsModalCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    func roomNotificationSettingsCoordinatorDidComplete(_ presentationController: UIPresentationController) {
        delegate?.spaceSettingsModalCoordinatorBridgePresenterDelegateDidCancel(self)
    }
}
