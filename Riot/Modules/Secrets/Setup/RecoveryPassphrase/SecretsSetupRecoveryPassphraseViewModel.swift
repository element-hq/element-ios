// File created from ScreenTemplate
// $ createScreen.sh Test SecretsSetupRecoveryPassphrase
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

final class SecretsSetupRecoveryPassphraseViewModel: SecretsSetupRecoveryPassphraseViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let passphraseInput: SecretsSetupRecoveryPassphraseInput
    private let passwordStrengthManager: PasswordStrengthManager
    
    private var currentViewData: SecretsSetupRecoveryPassphraseViewData?
    private var passphrase: String?
    
    // MARK: Public

    weak var viewDelegate: SecretsSetupRecoveryPassphraseViewModelViewDelegate?
    weak var coordinatorDelegate: SecretsSetupRecoveryPassphraseViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(passphraseInput: SecretsSetupRecoveryPassphraseInput) {
        self.passphraseInput = passphraseInput
        self.passwordStrengthManager = PasswordStrengthManager()
    }
    
    // MARK: - Public
    
    func process(viewAction: SecretsSetupRecoveryPassphraseViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .updatePassphrase(let passphrase):
            self.updatePassphrase(passphrase)
        case .validate:
            self.validate()
        case .cancel:
            self.coordinatorDelegate?.secretsSetupRecoveryPassphraseViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        
        let viewDataMode: SecretsSetupRecoveryPassphraseViewDataMode
        
        switch self.passphraseInput {
        case .new:
            viewDataMode = .newPassphrase(strength: .tooGuessable)
        case .confirm:
            viewDataMode = .confimPassphrase
        }
        
        let viewData = SecretsSetupRecoveryPassphraseViewData(mode: viewDataMode, isFormValid: false)
        
        self.update(viewState: .loaded(viewData))
    }
    
    private func update(viewState: SecretsSetupRecoveryPassphraseViewState) {
        self.viewDelegate?.secretsSetupRecoveryPassphraseViewModel(self, didUpdateViewState: viewState)
    }
    
    private func updatePassphrase(_ passphrase: String?) {
        
        let viewDataMode: SecretsSetupRecoveryPassphraseViewDataMode
        let isFormValid: Bool
        
        switch self.passphraseInput {
        case .new:
            let passphraseStrength = self.passwordStrength(for: passphrase)
            viewDataMode = .newPassphrase(strength: passphraseStrength)
            isFormValid = passphraseStrength == .veryUnguessable
        case .confirm(let passphraseToConfirm):
            viewDataMode = .confimPassphrase
            isFormValid = passphrase == passphraseToConfirm
        }
        
        let viewData = SecretsSetupRecoveryPassphraseViewData(mode: viewDataMode, isFormValid: isFormValid)
        
        self.passphrase = passphrase
        self.currentViewData = viewData
        
        self.update(viewState: .formUpdated(viewData))
    }
    
    private func validate() {
        guard let viewData = self.currentViewData,
            viewData.isFormValid,
            let passphrase = self.passphrase else {
            return
        }
        
        switch self.passphraseInput {
        case .new:
            self.coordinatorDelegate?.secretsSetupRecoveryPassphraseViewModel(self, didEnterNewPassphrase: passphrase)
        case .confirm:
            self.coordinatorDelegate?.secretsSetupRecoveryPassphraseViewModel(self, didConfirmPassphrase: passphrase)
        }
    }
    
    private func passwordStrength(for password: String?) -> PasswordStrength {
        guard let password = password else {
            return .tooGuessable
        }
        return self.passwordStrengthManager.passwordStrength(for: password)
    }
}
