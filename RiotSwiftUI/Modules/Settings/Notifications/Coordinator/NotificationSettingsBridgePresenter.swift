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
import Foundation

@objc protocol NotificationSettingsCoordinatorBridgePresenterDelegate {
    func notificationSettingsCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: NotificationSettingsCoordinatorBridgePresenter)
}

/// NotificationSettingsCoordinatorBridgePresenter enables to start NotificationSettingsCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class NotificationSettingsCoordinatorBridgePresenter: NSObject {
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: NotificationSettingsCoordinator?
    private var router: NavigationRouterType?
    
    // MARK: Public
    
    weak var delegate: NotificationSettingsCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    func push(from navigationController: UINavigationController, animated: Bool, screen: NotificationSettingsScreen, popCompletion: (() -> Void)?) {
        let router = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let notificationSettingsCoordinator = NotificationSettingsCoordinator(session: session, screen: screen)
        
        router.push(notificationSettingsCoordinator, animated: animated) { [weak self] in
            self?.coordinator = nil
            self?.router = nil
            popCompletion?()
        }
        
        notificationSettingsCoordinator.start()
        
        coordinator = notificationSettingsCoordinator
        self.router = router
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

// MARK: - NotificationSettingsCoordinatorDelegate

extension NotificationSettingsCoordinatorBridgePresenter: NotificationSettingsCoordinatorDelegate {
    func notificationSettingsCoordinatorDidComplete(_ coordinator: NotificationSettingsCoordinatorType) {
        delegate?.notificationSettingsCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension NotificationSettingsCoordinatorBridgePresenter: UIAdaptivePresentationControllerDelegate {
    func notificationSettingsCoordinatorDidComplete(_ presentationController: UIPresentationController) {
        delegate?.notificationSettingsCoordinatorBridgePresenterDelegateDidComplete(self)
    }
}
