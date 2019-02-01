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

protocol KeyBackupSetupRecoveryKeyViewModelViewDelegate: class {
    func keyBackupSetupRecoveryKeyViewModel(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType, didUpdateViewState viewSate: KeyBackupSetupRecoveryKeyViewState)
    func keyBackupSetupPassphraseViewModelShowSkipAlert(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType)    
}

protocol KeyBackupSetupRecoveryKeyViewModelCoordinatorDelegate: class {
    func keyBackupSetupRecoveryKeyViewModelDidCreateBackup(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType)
    func keyBackupSetupRecoveryKeyViewModelDidCancel(_ viewModel: KeyBackupSetupRecoveryKeyViewModelType)
}

/// Protocol describing the view model used by `KeyBackupSetupRecoveryKeyViewController`
protocol KeyBackupSetupRecoveryKeyViewModelType {
    
    var recoveryKey: String { get }
    
    var viewDelegate: KeyBackupSetupRecoveryKeyViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupSetupRecoveryKeyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupSetupRecoveryKeyViewAction)
}
