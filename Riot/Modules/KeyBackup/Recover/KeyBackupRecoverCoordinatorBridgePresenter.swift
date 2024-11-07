/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

@objc protocol KeyBackupRecoverCoordinatorBridgePresenterDelegate {
    func keyBackupRecoverCoordinatorBridgePresenterDidCancel(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter)
    func keyBackupRecoverCoordinatorBridgePresenterDidRecover(_ keyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorBridgePresenter)
}

/// KeyBackupRecoverCoordinatorBridgePresenter enables to start KeyBackupRecoverCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
@objcMembers
final class KeyBackupRecoverCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let keyBackupVersion: MXKeyBackupVersion
    private var coordinator: KeyBackupRecoverCoordinator?
    
    // MARK: Public
    
    weak var delegate: KeyBackupRecoverCoordinatorBridgePresenterDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, keyBackupVersion: MXKeyBackupVersion) {
        self.session = session
        self.keyBackupVersion = keyBackupVersion
        super.init()
    }
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        guard let keyBackup = session.crypto?.backup else {
            MXLog.failure("[KeyBackupRecoverCoordinatorBridgePresenter] Cannot setup backups without backup module")
            return
        }
        
        let keyBackupSetupCoordinator = KeyBackupRecoverCoordinator(keyBackup: keyBackup, keyBackupVersion: keyBackupVersion)
        keyBackupSetupCoordinator.delegate = self
        viewController.present(keyBackupSetupCoordinator.toPresentable(), animated: animated, completion: nil)
        keyBackupSetupCoordinator.start()
        
        self.coordinator = keyBackupSetupCoordinator
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
        guard let keyBackup = session.crypto?.backup else {
            MXLog.failure("[KeyBackupRecoverCoordinatorBridgePresenter] Cannot setup backups without backup module")
            return
        }
        
        MXLog.debug("[KeyBackupRecoverCoordinatorBridgePresenter] Push complete security from \(navigationController)")
        
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let keyBackupSetupCoordinator = KeyBackupRecoverCoordinator(keyBackup: keyBackup, keyBackupVersion: keyBackupVersion, navigationRouter: navigationRouter)
        keyBackupSetupCoordinator.delegate = self
        keyBackupSetupCoordinator.start() // Will trigger view controller push
        
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

// MARK: - KeyBackupRecoverCoordinatorDelegate
extension KeyBackupRecoverCoordinatorBridgePresenter: KeyBackupRecoverCoordinatorDelegate {
    func keyBackupRecoverCoordinatorDidRecover(_ keyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorBridgePresenterDidRecover(self)
    }
    
    func keyBackupRecoverCoordinatorDidCancel(_ keyBackupRecoverCoordinator: KeyBackupRecoverCoordinatorType) {
        self.delegate?.keyBackupRecoverCoordinatorBridgePresenterDidCancel(self)
    }
}
