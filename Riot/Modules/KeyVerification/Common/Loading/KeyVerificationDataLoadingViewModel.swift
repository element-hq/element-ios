// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

enum KeyVerificationDataLoadingViewModelError: Error {
    case transactionCancelled
    case transactionCancelledByMe(reason: MXTransactionCancelCode)
}

final class KeyVerificationDataLoadingViewModel: KeyVerificationDataLoadingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private(set) var verificationKind: KeyVerificationKind
    private let otherUserId: String?
    private let otherDeviceId: String?
    private let keyVerificationService = KeyVerificationService()
    
    private let keyVerificationRequest: MXKeyVerificationRequest?
    
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: KeyVerificationDataLoadingViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationDataLoadingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, verificationKind: KeyVerificationKind, otherUserId: String, otherDeviceId: String) {
        self.session = session
        self.verificationKind = verificationKind
        self.otherUserId = otherUserId
        self.otherDeviceId = otherDeviceId
        self.keyVerificationRequest = nil
    }
    
    init(session: MXSession, verificationKind: KeyVerificationKind, keyVerificationRequest: MXKeyVerificationRequest) {
        self.session = session
        self.verificationKind = verificationKind
        self.otherUserId = nil
        self.otherDeviceId = nil
        self.keyVerificationRequest = keyVerificationRequest
    }
    
    deinit {
        self.currentOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationDataLoadingViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .cancel:
            self.coordinatorDelegate?.keyVerificationDataLoadingViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        if let keyVerificationRequest = self.keyVerificationRequest {
            self.acceptKeyVerificationRequest(keyVerificationRequest)
        } else {
            self.downloadOtherDeviceKeys()
        }
    }
    
    private func acceptKeyVerificationRequest(_ keyVerificationRequest: MXKeyVerificationRequest) {
        
        self.update(viewState: .loading)
        
        keyVerificationRequest.accept(withMethods: self.keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.coordinatorDelegate?.keyVerificationDataLoadingViewModel(self, didAcceptKeyVerificationRequest: keyVerificationRequest)
            
        }, failure: { [weak self] (error) in
            guard let self = self else {
                return
            }
            self.update(viewState: .error(error))
        })
    }
    
    private func downloadOtherDeviceKeys() {
        guard let crypto = session.crypto,
            let otherUserId = self.otherUserId,
            let otherDeviceId = self.otherDeviceId else {
            self.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
            MXLog.debug("[KeyVerificationDataLoadingViewModel] Error session.crypto is nil")
            return
        }
        
        if let otherUser = session.user(withUserId: otherUserId) {
            
            self.update(viewState: .loading)
           
            self.currentOperation = crypto.downloadKeys([otherUserId], forceDownload: false, success: { [weak self] (usersDevicesMap, crossSigningKeysMap) in
                guard let sself = self else {
                    return
                }
                
                if let otherDevice = usersDevicesMap?.object(forDevice: otherDeviceId, forUser: otherUserId) {
                    sself.update(viewState: .loaded)
                    sself.coordinatorDelegate?.keyVerificationDataLoadingViewModel(sself, didLoadUser: otherUser, device: otherDevice)
                } else {
                    sself.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
                }
                
                }, failure: { [weak self] (error) in
                    guard let sself = self else {
                        return
                    }
                    
                    sself.update(viewState: .error(error))
            })
            
        } else {
            self.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
        }
    }
    
    private func update(viewState: KeyVerificationDataLoadingViewState) {
        self.viewDelegate?.keyVerificationDataLoadingViewModel(self, didUpdateViewState: viewState)
    }
}
