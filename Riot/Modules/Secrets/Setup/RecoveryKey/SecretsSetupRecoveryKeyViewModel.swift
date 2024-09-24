// File created from ScreenTemplate
// $ createScreen.sh SecretsSetupRecoveryKey SecretsSetupRecoveryKey
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class SecretsSetupRecoveryKeyViewModel: SecretsSetupRecoveryKeyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let recoveryService: MXRecoveryService
    private let passphrase: String?
    private let passphraseOnly: Bool
    private let allowOverwrite: Bool
    private let dehydrationService: DehydrationService?
    
    // MARK: Public

    weak var viewDelegate: SecretsSetupRecoveryKeyViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsSetupRecoveryKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(recoveryService: MXRecoveryService, passphrase: String?, passphraseOnly: Bool, allowOverwrite: Bool = false, dehydrationService: DehydrationService?) {
        self.recoveryService = recoveryService
        self.passphrase = passphrase
        self.passphraseOnly = passphraseOnly
        self.allowOverwrite = allowOverwrite
        self.dehydrationService = dehydrationService
    }
    
    // MARK: - Public
    
    func process(viewAction: SecretsSetupRecoveryKeyViewAction) {
        switch viewAction {
        case .loadData:
            self.update(viewState: .loaded(self.passphraseOnly))
            self.createSecureKey()
        case .done:
            self.coordinatorDelegate?.secretsSetupRecoveryKeyViewModelDidComplete(self)
        case .errorAlertOk:
            self.coordinatorDelegate?.secretsSetupRecoveryKeyViewModelDidFailed(self)
        case .cancel:
            self.coordinatorDelegate?.secretsSetupRecoveryKeyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func createSecureKey() {
        self.update(viewState: .loading)
        
        if allowOverwrite && self.recoveryService.hasRecovery() {
            MXLog.debug("[SecretsSetupRecoveryKeyViewModel] createSecureKey: Overwrite existing secure backup")
            self.recoveryService.deleteRecovery(withDeleteServicesBackups: true) {
                self.createSecureKey()
            } failure: { error in
                self.update(viewState: .error(error))
            }
            return
        }
                
        self.recoveryService.createRecovery(forSecrets: nil, withPassphrase: self.passphrase, createServicesBackups: true, success: { secretStorageKeyCreationInfo in
            self.update(viewState: .recoveryCreated(secretStorageKeyCreationInfo.recoveryKey))
            
            Task {
                await self.dehydrationService?.runDeviceDehydrationFlow(privateKeyData: secretStorageKeyCreationInfo.privateKey)
            }
        }, failure: { error in
            self.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: SecretsSetupRecoveryKeyViewState) {
        self.viewDelegate?.secretsSetupRecoveryKeyViewModel(self, didUpdateViewState: viewState)
    }
}
