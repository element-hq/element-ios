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

final class KeyBackupSetupRecoveryKeyViewModel: KeyBackupSetupRecoveryKeyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let megolmBackupCreationInfo: MXMegolmBackupCreationInfo
    private let keyBackup: MXKeyBackup
    private let coordinatorDelegateQueue: OperationQueue
    private var createKeyBackupOperation: MXHTTPOperation?
    
    // MARK: Public
    
    let recoveryKey: String
    
    weak var viewDelegate: KeyBackupSetupRecoveryKeyViewModelViewDelegate?
    weak var coordinatorDelegate: KeyBackupSetupRecoveryKeyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(keyBackup: MXKeyBackup, megolmBackupCreationInfo: MXMegolmBackupCreationInfo) {
        self.megolmBackupCreationInfo = megolmBackupCreationInfo
        self.recoveryKey = megolmBackupCreationInfo.recoveryKey
        self.keyBackup = keyBackup
        self.coordinatorDelegateQueue = OperationQueue.vc_createSerialOperationQueue(name: "\(type(of: self)).coordinatorDelegateQueue")
    }
    
    deinit {
        self.createKeyBackupOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyBackupSetupRecoveryKeyViewAction) {
        switch viewAction {
        case .madeCopy:
            self.createBackup()
        case .skip:
            self.coordinatorDelegateQueue.vc_pause()
            self.viewDelegate?.keyBackupSetupPassphraseViewModelShowSkipAlert(self)
        case.skipAlertContinue:
            self.coordinatorDelegateQueue.vc_resume()
        case.skipAlertSkip:
            self.coordinatorDelegateQueue.cancelAllOperations()
            self.coordinatorDelegate?.keyBackupSetupRecoveryKeyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    func createBackup() {
        self.viewDelegate?.keyBackupSetupRecoveryKeyViewModel(self, didUpdateViewState: .loading)
        
        self.keyBackup.createKeyBackupVersion(self.megolmBackupCreationInfo, success: { [weak self] (keyBackupVersion) in
            guard let sself = self else {
                return
            }
            sself.viewDelegate?.keyBackupSetupRecoveryKeyViewModel(sself, didUpdateViewState: .loaded)
            
            sself.coordinatorDelegateQueue.addOperation {
                DispatchQueue.main.async {
                    sself.coordinatorDelegate?.keyBackupSetupRecoveryKeyViewModelDidCreateBackup(sself)
                }
            }
        }, failure: { [weak self] error in
            guard let sself = self else {
                return
            }
            sself.viewDelegate?.keyBackupSetupRecoveryKeyViewModel(sself, didUpdateViewState: .error(error))
        })    
    }
}
