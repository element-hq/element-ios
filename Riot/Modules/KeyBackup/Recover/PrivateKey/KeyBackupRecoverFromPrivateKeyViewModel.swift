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

final class KeyBackupRecoverFromPrivateKeyViewModel: KeyBackupRecoverFromPrivateKeyViewModelType {    
    
    // MARK: - Properties
    
    // MARK: Private

    private let keyBackup: MXKeyBackup
    private var currentHTTPOperation: MXHTTPOperation?
    private let keyBackupVersion: MXKeyBackupVersion
    
    // MARK: Public

    weak var viewDelegate: KeyBackupRecoverFromPrivateKeyViewModelViewDelegate?
    weak var coordinatorDelegate: KeyBackupRecoverFromPrivateKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, keyBackupVersion: MXKeyBackupVersion) {
        self.keyBackup = keyBackup
        self.keyBackupVersion = keyBackupVersion
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyBackupRecoverFromPrivateKeyViewAction) {
        switch viewAction {
        case .recover:
            self.recoverWithPrivateKey()
        case .cancel:
            self.coordinatorDelegate?.keyBackupRecoverFromPrivateKeyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func recoverWithPrivateKey() {

        self.update(viewState: .loading)
        
        self.currentHTTPOperation = keyBackup.restoreUsingPrivateKey(inCryptoStore: keyBackupVersion, room: nil, session: nil, success: { [weak self] (_, _) in
            guard let sself = self else {
                return
            }
            
            // Trust on decrypt
            sself.currentHTTPOperation = sself.keyBackup.trust(sself.keyBackupVersion, trust: true, success: { [weak sself] () in
                guard let ssself = sself else {
                    return
                }
                
                ssself.update(viewState: .loaded)
                ssself.coordinatorDelegate?.keyBackupRecoverFromPrivateKeyViewModelDidRecover(ssself)
                
                }, failure: { [weak sself] error in
                    sself?.update(viewState: .error(error))
            })
            
            }, failure: { [weak self] error in
                self?.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: KeyBackupRecoverFromPrivateKeyViewState) {
        self.viewDelegate?.keyBackupRecoverFromPrivateKeyViewModel(self, didUpdateViewState: viewState)
    }
}
