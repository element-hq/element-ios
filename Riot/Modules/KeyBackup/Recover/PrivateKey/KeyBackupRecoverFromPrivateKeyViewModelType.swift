// File created from ScreenTemplate
// $ createScreen.sh .KeyBackup/Recover/PrivateKey KeyBackupRecoverFromPrivateKey
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

protocol KeyBackupRecoverFromPrivateKeyViewModelViewDelegate: AnyObject {
    func keyBackupRecoverFromPrivateKeyViewModel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType, didUpdateViewState viewSate: KeyBackupRecoverFromPrivateKeyViewState)
}

protocol KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate: AnyObject {
    func keyBackupRecoverFromPrivateKeyViewModelDidRecover(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType)
    func keyBackupRecoverFromPrivateKeyViewModelDidPrivateKeyFail(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType)
    func keyBackupRecoverFromPrivateKeyViewModelDidCancel(_ viewModel: KeyBackupRecoverFromPrivateKeyViewModelType)
}

/// Protocol describing the view model used by `KeyBackupRecoverFromPrivateKeyViewController`
protocol KeyBackupRecoverFromPrivateKeyViewModelType {

    var viewDelegate: KeyBackupRecoverFromPrivateKeyViewModelViewDelegate? { get set }
    var coordinatorDelegate: KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate? { get set }
    
    func process(viewAction: KeyBackupRecoverFromPrivateKeyViewAction)
}
