/*
 Copyright 2019 New Vector Ltd
 
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

protocol KeyBackupSetupPassphraseViewModelViewDelegate: AnyObject {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didUpdateViewState viewSate: KeyBackupSetupPassphraseViewState)
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupPassphraseViewModelType)
}

protocol KeyBackupSetupPassphraseViewModelCoordinatorDelegate: AnyObject {
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didCreateBackupFromPassphraseWithResultingRecoveryKey recoveryKey: String)
    func keyBackupSetupPassphraseViewModel(_ viewModel: KeyBackupSetupPassphraseViewModelType, didCreateBackupFromRecoveryKey recoveryKey: String)    
    func keyBackupSetupPassphraseViewModelDidCancel(_ viewModel: KeyBackupSetupPassphraseViewModelType)
}

/// Protocol describing the view model used by `KeyBackupSetupPassphraseViewController`
protocol KeyBackupSetupPassphraseViewModelType {
    
    var passphrase: String? { get set }
    var confirmPassphrase: String? { get set }
    var passphraseStrength: PasswordStrength { get }
    
    var isPassphraseValid: Bool { get }
    var isConfirmPassphraseValid: Bool { get }
    var isFormValid: Bool { get }
        
    var viewDelegate: KeyBackupSetupPassphraseViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupSetupPassphraseViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupSetupPassphraseViewAction)
}
