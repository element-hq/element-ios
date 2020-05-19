// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
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

enum KeyVerificationManuallyVerifyViewModelError: Error {
    case unknown
    case deviceNotFound
}

final class KeyVerificationManuallyVerifyViewModel: KeyVerificationManuallyVerifyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let deviceId: String
    private let userId: String
    
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: KeyVerificationManuallyVerifyViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationManuallyVerifyViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, deviceId: String, userId: String) {
        self.session = session
        self.deviceId = deviceId
        self.userId = userId
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationManuallyVerifyViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .verify:
            self.verifyDevice()
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.keyVerificationManuallyVerifyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        
        guard let deviceInfo =  self.session.crypto.device(withDeviceId: self.deviceId, ofUser: self.userId) else {
            self.update(viewState: .error(KeyVerificationManuallyVerifyViewModelError.deviceNotFound))
            return
        }
        
        var deviceKey: String?
        
        if let deviceFingerprint = deviceInfo.fingerprint {
            deviceKey = MXTools.addWhiteSpaces(to: deviceFingerprint, every: 4)
        }
        
        let viewData = KeyVerificationManuallyVerifyViewData(deviceId: self.deviceId, deviceName: deviceInfo.displayName, deviceKey: deviceKey)
        self.update(viewState: .loaded(viewData))
    }
    
    private func update(viewState: KeyVerificationManuallyVerifyViewState) {
        self.viewDelegate?.keyVerificationManuallyVerifyViewModel(self, didUpdateViewState: viewState)
    }
    
    private func verifyDevice() {
        
        self.update(viewState: .loading)
        
        self.session.crypto.setDeviceVerification(.verified, forDevice: self.deviceId, ofUser: self.userId, success: { [weak self] in
            guard let self = self else {
                return
            }
            self.coordinatorDelegate?.keyVerificationManuallyVerifyViewModel(self, didVerifiedDeviceWithId: self.deviceId, of: self.userId)
        }, failure: { [weak self] (error) in
            guard let self = self else {
                return
            }
            let finalError = error ?? KeyVerificationManuallyVerifyViewModelError.unknown
            self.update(viewState: .error(finalError))
        })
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
