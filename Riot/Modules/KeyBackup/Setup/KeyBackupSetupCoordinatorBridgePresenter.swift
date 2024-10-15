/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol KeyBackupSetupCoordinatorBridgePresenterDelegate {
    func keyBackupSetupCoordinatorBridgePresenterDelegateDidCancel(_ keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter)
    func keyBackupSetupCoordinatorBridgePresenterDelegateDidSetupRecoveryKey(_ keyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorBridgePresenter)
}

/// KeyBackupSetupCoordinatorBridgePresenter enables to start KeyBackupSetupCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class KeyBackupSetupCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var coordinator: KeyBackupSetupCoordinator?
    
    // MARK: Public
    
    weak var delegate: KeyBackupSetupCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        super.init()
    }
    
    // MARK: - Public
    
    // NOTE: Default value feature is not compatible with Objective-C.
    func present(from viewController: UIViewController, animated: Bool) {
        self.present(from: viewController, isStartedFromSignOut: false, animated: animated)
    }
    
    func present(from viewController: UIViewController, isStartedFromSignOut: Bool, animated: Bool) {
        let keyBackupSetupCoordinator = KeyBackupSetupCoordinator(session: self.session, isStartedFromSignOut: isStartedFromSignOut)
        keyBackupSetupCoordinator.delegate = self
        viewController.present(keyBackupSetupCoordinator.toPresentable(), animated: animated, completion: nil)
        keyBackupSetupCoordinator.start()
        
        self.coordinator = keyBackupSetupCoordinator
    }
    
    func dismiss(animated: Bool) {
        guard let coordinator = self.coordinator else {
            return
        }        
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil
        }
    }
}

// MARK: - KeyBackupSetupCoordinatorDelegate
extension KeyBackupSetupCoordinatorBridgePresenter: KeyBackupSetupCoordinatorDelegate {
    func keyBackupSetupCoordinatorDidCancel(_ keyBackupSetupCoordinator: KeyBackupSetupCoordinatorType) {
        self.delegate?.keyBackupSetupCoordinatorBridgePresenterDelegateDidCancel(self)
    }
    
    func keyBackupSetupCoordinatorDidSetupRecoveryKey(_ keyBackupSetupCoordinator: KeyBackupSetupCoordinatorType) {
        self.delegate?.keyBackupSetupCoordinatorBridgePresenterDelegateDidSetupRecoveryKey(self)
    }
}
