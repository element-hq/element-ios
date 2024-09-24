// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation
import UIKit

final class KeyBackupRecoverFromPrivateKeyCoordinator: KeyBackupRecoverFromPrivateKeyCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var keyBackupRecoverFromPrivateKeyViewModel: KeyBackupRecoverFromPrivateKeyViewModelType
    private let keyBackupRecoverFromPrivateKeyViewController: KeyBackupRecoverFromPrivateKeyViewController
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: KeyBackupRecoverFromPrivateKeyCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        
        let keyBackupRecoverFromPrivateKeyViewModel = KeyBackupRecoverFromPrivateKeyViewModel(keyBackup: keyBackup, keyBackupVersion: keyBackupVersion)
        let keyBackupRecoverFromPrivateKeyViewController = KeyBackupRecoverFromPrivateKeyViewController.instantiate(with: keyBackupRecoverFromPrivateKeyViewModel)
        self.keyBackupRecoverFromPrivateKeyViewModel = keyBackupRecoverFromPrivateKeyViewModel
        self.keyBackupRecoverFromPrivateKeyViewController = keyBackupRecoverFromPrivateKeyViewController
    }
    
    // MARK: - Public methods
    
    func start() {            
        self.keyBackupRecoverFromPrivateKeyViewModel.coordinatorDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.keyBackupRecoverFromPrivateKeyViewController
    }
}

// MARK: - KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate
extension KeyBackupRecoverFromPrivateKeyCoordinator: KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate {
    func keyBackupRecoverFromPrivateKeyViewModelDidRecover(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPrivateKeyCoordinatorDidRecover(self)
    }
    
    func keyBackupRecoverFromPrivateKeyViewModelDidPrivateKeyFail(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPrivateKeyCoordinatorDidPrivateKeyFail(self)
    }
    
    func keyBackupRecoverFromPrivateKeyViewModelDidCancel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType) {
        self.delegate?.keyBackupRecoverFromPrivateKeyCoordinatorDidCancel(self)
    }
}
