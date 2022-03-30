/*
 Copyright 2020 New Vector Ltd
 
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

@objc protocol SecretsRecoveryCoordinatorBridgePresenterDelegate {
    func secretsRecoveryCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SecretsRecoveryCoordinatorBridgePresenter)
    func secretsRecoveryCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: SecretsRecoveryCoordinatorBridgePresenter)
}

/// SecretsRecoveryCoordinatorBridgePresenter enables to start SecretsRecoveryCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class SecretsRecoveryCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let recoveryMode: SecretsRecoveryMode
    let recoveryGoal: SecretsRecoveryGoalBridge
    
    private var coordinator: SecretsRecoveryCoordinator?
    
    // MARK: Public
    
    weak var delegate: SecretsRecoveryCoordinatorBridgePresenterDelegate?
    
    var isPresenting: Bool {
        return self.coordinator != nil
    }
    
    // MARK: - Setup
    
    init(session: MXSession, recoveryMode: SecretsRecoveryMode, recoveryGoal: SecretsRecoveryGoalBridge) {
        self.session = session
        self.recoveryMode = recoveryMode
        self.recoveryGoal = recoveryGoal
        super.init()
    }
    
    init(session: MXSession, recoveryGoal: SecretsRecoveryGoalBridge) {
        self.session = session
        
        if case SecretsRecoveryAvailability.available(let secretMode) = session.crypto.recoveryService.vc_availability {
            self.recoveryMode = secretMode
        } else {
            fatalError("[SecretsRecoveryCoordinatorBridgePresenter] recoveryService should be available when presenting recovery")
        }
        
        self.recoveryGoal = recoveryGoal
        super.init()
    }
    
    // MARK: - Public
    
    func toPresentable() -> UIViewController? {
        return self.coordinator?.toPresentable()
    }
    
    func present(from viewController: UIViewController, animated: Bool) {
        
        let coordinator = SecretsRecoveryCoordinator(session: self.session, recoveryMode: self.recoveryMode, recoveryGoal: self.recoveryGoal.goal, cancellable: true)
        coordinator.delegate = self
        
        let presentable = coordinator.toPresentable()
        presentable.modalPresentationStyle = .formSheet
        viewController.present(presentable, animated: animated, completion: nil)
        
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        
        MXLog.debug("[SecretsRecoveryCoordinatorBridgePresenter] Dismiss")
        
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil
            
            if let completion = completion {
                completion()
            }
        }
    }
}

// MARK: - KeyVerificationCoordinatorDelegate
extension SecretsRecoveryCoordinatorBridgePresenter: SecretsRecoveryCoordinatorDelegate {
    func secretsRecoveryCoordinatorDidRecover(_ coordinator: SecretsRecoveryCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func secretsRecoveryCoordinatorDidCancel(_ coordinator: SecretsRecoveryCoordinatorType) {
        self.delegate?.secretsRecoveryCoordinatorBridgePresenterDelegateDidCancel(self)
    }
}
