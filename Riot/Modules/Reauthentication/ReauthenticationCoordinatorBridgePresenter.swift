// File created from FlowTemplate
// $ createRootCoordinator.sh Reauthentication Reauthentication
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol ReauthenticationCoordinatorBridgePresenterDelegate {
    func reauthenticationCoordinatorBridgePresenterDidComplete(_ bridgePresenter: ReauthenticationCoordinatorBridgePresenter, withAuthenticationParameters authenticationParameters: [String: Any]?)
    func reauthenticationCoordinatorBridgePresenterDidCancel(_ bridgePresenter: ReauthenticationCoordinatorBridgePresenter)
    func reauthenticationCoordinatorBridgePresenter(_ bridgePresenter: ReauthenticationCoordinatorBridgePresenter, didFailWithError error: Error)
    
}

/// ReauthenticationCoordinatorBridgePresenter enables to start ReauthenticationCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class ReauthenticationCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
        
    private var coordinator: ReauthenticationCoordinator?
    
    // MARK: Public
    
    private var didComplete: ((_ authenticationParameters: [String: Any]?) -> Void)?
    private var didCancel: (() -> Void)?
    private var didFail: ((Error) -> Void)?
    
    // MARK: - Public
    
    func present(with parameters: ReauthenticationCoordinatorParameters,
                 animated: Bool,
                 success: @escaping ([String: Any]?) -> Void,
                 cancel: @escaping () -> Void,
                 failure: @escaping (Error) -> Void) {
        
        self.didComplete = success
        self.didCancel = cancel
        self.didFail = failure
        
        let coordinator = ReauthenticationCoordinator(parameters: parameters)
        coordinator.delegate = self
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        self.resetCompletions()
        
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
    
    // MARK - Private
    
    private func resetCompletions() {
        self.didComplete = nil
        self.didCancel = nil
        self.didFail = nil
    }
}

// MARK: - ReauthenticationCoordinatorDelegate
extension ReauthenticationCoordinatorBridgePresenter: ReauthenticationCoordinatorDelegate {
    func reauthenticationCoordinatorDidComplete(_ coordinator: ReauthenticationCoordinatorType, withAuthenticationParameters authenticationParameters: [String: Any]?) {
        self.didComplete?(authenticationParameters)
    }
    
    func reauthenticationCoordinatorDidCancel(_ coordinator: ReauthenticationCoordinatorType) {
        self.didCancel?()
    }
    
    func reauthenticationCoordinator(_ coordinator: ReauthenticationCoordinatorType, didFailWithError error: Error) {
        self.didFail?(error)
    }
}
