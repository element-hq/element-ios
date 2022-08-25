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

final class KeyBackupRecoverFromRecoveryKeyViewModel: KeyBackupRecoverFromRecoveryKeyViewModelType {
    // MARK: - Properties
    
    // MARK: Private
    
    private let keyBackup: MXKeyBackup
    private var currentHTTPOperation: MXHTTPOperation?
    private let keyBackupVersion: MXKeyBackupVersion
    
    // MARK: Public
    
    var recoveryKey: String?
    
    var isFormValid: Bool {
        self.recoveryKey?.isEmpty == false
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
            recover()
        case .cancel:
            coordinatorDelegate?.keyBackupRecoverFromRecoveryKeyViewModelDidCancel(self)
        case .unknownRecoveryKey:
            break
        }
    }
    
    // MARK: - Private
    
    private func recover() {
        guard let recoveryKey = recoveryKey else {
            return
        }
        
        update(viewState: .loading)
        
        currentHTTPOperation = keyBackup.restore(keyBackupVersion, withRecoveryKey: recoveryKey, room: nil, session: nil, success: { [weak self] _, _ in
            guard let sself = self else {
                return
            }

            // Trust on decrypt
            sself.currentHTTPOperation = sself.keyBackup.trust(sself.keyBackupVersion, trust: true, success: { [weak sself] () in
                guard let ssself = sself else {
                    return
                }

                ssself.update(viewState: .loaded)
                ssself.coordinatorDelegate?.keyBackupRecoverFromRecoveryKeyViewModelDidRecover(ssself)

            }, failure: { [weak sself] error in
                sself?.update(viewState: .error(error))
            })

        }, failure: { [weak self] error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: KeyBackupRecoverFromRecoveryKeyViewState) {
        viewDelegate?.keyBackupRecoverFromPassphraseViewModel(self, didUpdateViewState: viewState)
    }
}
