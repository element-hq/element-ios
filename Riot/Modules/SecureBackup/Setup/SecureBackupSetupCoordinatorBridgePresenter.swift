// File created from FlowTemplate
// $ createRootCoordinator.sh KeyBackupSetup/SecureSetup SecureKeyBackupSetup
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

@objc protocol SecureBackupSetupCoordinatorBridgePresenterDelegate {
    func secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete(_ coordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter)
    func secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel(_ coordinatorBridgePresenter: SecureBackupSetupCoordinatorBridgePresenter)
}

/// SecureBackupSetupCoordinatorBridgePresenter enables to start SecureBackupSetupCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class SecureBackupSetupCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let allowOverwrite: Bool
    private var coordinator: SecureBackupSetupCoordinator?
    
    // MARK: Public
    weak var delegate: SecureBackupSetupCoordinatorBridgePresenterDelegate?

    var isPresenting: Bool {
        return self.coordinator != nil
    }

    // MARK: - Setup

    init(session: MXSession, allowOverwrite: Bool) {
        self.session = session
        self.allowOverwrite = allowOverwrite
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    // func present(from viewController: UIViewController, animated: Bool) {
    //     self.present(from: viewController, animated: animated)
    // }

    func present(from viewController: UIViewController, animated: Bool) {
        self.present(from: viewController, animated: animated, cancellable: true)
    }
    
    func present(from viewController: UIViewController, animated: Bool, cancellable: Bool) {
        let secureBackupSetupCoordinator = SecureBackupSetupCoordinator(session: self.session, allowOverwrite: self.allowOverwrite, cancellable: cancellable)
        secureBackupSetupCoordinator.delegate = self
        viewController.present(secureBackupSetupCoordinator.toPresentable(), animated: animated, completion: nil)
        secureBackupSetupCoordinator.start()
        
        self.coordinator = secureBackupSetupCoordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
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
}

// MARK: - SecureBackupSetupCoordinatorDelegate
extension SecureBackupSetupCoordinatorBridgePresenter: SecureBackupSetupCoordinatorDelegate {
    func secureBackupSetupCoordinatorDidComplete(_ coordinator: SecureBackupSetupCoordinatorType) {
        self.delegate?.secureBackupSetupCoordinatorBridgePresenterDelegateDidComplete(self)
    }
    
    func secureBackupSetupCoordinatorDidCancel(_ coordinator: SecureBackupSetupCoordinatorType) {
        self.delegate?.secureBackupSetupCoordinatorBridgePresenterDelegateDidCancel(self)
    }
}
