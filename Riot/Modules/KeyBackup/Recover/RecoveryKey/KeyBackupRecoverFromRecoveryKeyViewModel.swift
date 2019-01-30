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

enum KeyBackupRecoverFromRecoveryKeyViewModelError: Error {
    case missingKeyBackupVersion
}

final class KeyBackupRecoverFromRecoveryKeyViewModel: KeyBackupRecoverFromRecoveryKeyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let keyBackup: MXKeyBackup
    private var currentHTTPOperation: MXHTTPOperation?
    private let keyBackupVersion: MXKeyBackupVersion
    
    // MARK: Public
    
    var recoveryKey: String?
    
    var isFormValid: Bool {
        return self.recoveryKey?.isEmpty == false
    }
    
    weak var viewDelegate: KeyBackupRecoverFromRecoveryKeyViewModelViewDelegate?
    weak var coordinatorDelegate: KeyBackupRecoverFromRecoveryKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        self.keyBackup = keyBackup
        self.keyBackupVersion = keyBackupVersion
    }
    
    deinit {
        self.currentHTTPOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyBackupRecoverFromRecoveryKeyViewAction) {
        switch viewAction {
        case .recover:
            self.recover()
        case .cancel:
            self.coordinatorDelegate?.keyBackupRecoverFromRecoveryKeyViewModelDidCancel(self)
        case .unknownRecoveryKey:
            break
        }
    }
    
    // MARK: - Private
    
    private func recover() {
        guard let recoveryKey = self.recoveryKey else {
            return
        }
        
        guard let keyBackupVersion = self.keyBackupVersion.version else {
            self.update(viewState: .error(KeyBackupRecoverFromRecoveryKeyViewModelError.missingKeyBackupVersion))
            return
        }
        
        self.update(viewState: .loading)
        
        self.currentHTTPOperation = self.keyBackup.restore(keyBackupVersion, withRecoveryKey: recoveryKey, room: nil, session: nil, success: { [weak self] (totalKeys, _) in
            guard let sself = self else {
                return
            }
            sself.update(viewState: .loaded(totalKeys: totalKeys))
            if totalKeys > 0 {
                DispatchQueue.main.async {
                    sself.coordinatorDelegate?.keyBackupRecoverFromRecoveryKeyViewModelDidRecover(sself)
                }
            }
        }, failure: { [weak self] error in
            guard let sself = self else {
                return
            }
            DispatchQueue.main.async {
                sself.update(viewState: .error(error))
            }
        })
    }
    
    private func update(viewState: KeyBackupRecoverFromRecoveryKeyViewState) {        
        self.viewDelegate?.keyBackupRecoverFromPassphraseViewModel(self, didUpdateViewState: viewState)
    }
}
