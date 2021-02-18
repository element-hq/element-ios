// File created from FlowTemplate
// $ createRootCoordinator.sh Reauthentication Reauthentication
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
