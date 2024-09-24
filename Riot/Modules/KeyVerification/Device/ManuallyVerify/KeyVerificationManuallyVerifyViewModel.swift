// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Device/ManuallyVerify KeyVerificationManuallyVerify
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
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
