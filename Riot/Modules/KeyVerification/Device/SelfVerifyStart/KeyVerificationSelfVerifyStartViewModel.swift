// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyVerificationSelfVerifyStartViewModel: KeyVerificationSelfVerifyStartViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let otherDeviceId: String
    private let verificationManager: MXKeyVerificationManager
    private let keyVerificationService: KeyVerificationService
    
    private var keyVerificationRequest: MXKeyVerificationRequest?
    
    // MARK: Public    

    weak var viewDelegate: KeyVerificationSelfVerifyStartViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationSelfVerifyStartViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherDeviceId: String) {
        self.session = session
        self.verificationManager = session.crypto.keyVerificationManager
        self.otherDeviceId = otherDeviceId
        self.keyVerificationService = KeyVerificationService()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationSelfVerifyStartViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .startVerification:
            self.startVerification()
        case .cancel:
            self.cancelKeyVerificationRequest()
            self.coordinatorDelegate?.keyVerificationSelfVerifyStartViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        self.startVerification()
    }
    
    private func startVerification() {
        self.update(viewState: .verificationPending)
        
        self.verificationManager.requestVerificationByToDevice(withUserId: session.myUser.userId, deviceIds: [otherDeviceId], methods: self.keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] (keyVerificationRequest) in
            guard let self = self else {
                return
            }
            
            self.keyVerificationRequest = keyVerificationRequest
            self.update(viewState: .loaded)
            self.registerKeyVerificationRequestDidChangeNotification(for: keyVerificationRequest)
            }, failure: { [weak self]  error in
                self?.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: KeyVerificationSelfVerifyStartViewState) {
        self.viewDelegate?.keyVerificationSelfVerifyStartViewModel(self, didUpdateViewState: viewState)
    }        
    
    private func cancelKeyVerificationRequest() {
        guard let keyVerificationRequest = self.keyVerificationRequest  else {
            return
        }
        
        keyVerificationRequest.cancel(with: MXTransactionCancelCode.user(), success: nil, failure: nil)
    }
    
    // MARK: - MXKeyVerificationRequestDidChange
    
    private func registerKeyVerificationRequestDidChangeNotification(for keyVerificationRequest: MXKeyVerificationRequest) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyVerificationRequestDidChange(notification:)), name: .MXKeyVerificationRequestDidChange, object: keyVerificationRequest)
    }
    
    private func unregisterKeyVerificationRequestDidChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationRequestDidChange, object: nil)
    }
    
    @objc private func keyVerificationRequestDidChange(notification: Notification) {
        guard let keyVerificationRequest = notification.object as? MXKeyVerificationRequest else {
            return
        }
        
        guard let currentKeyVerificationRequest = self.keyVerificationRequest, keyVerificationRequest.requestId == currentKeyVerificationRequest.requestId else {
            return
        }
        
        switch keyVerificationRequest.state {
        case MXKeyVerificationRequestStateAccepted:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.coordinatorDelegate?.keyVerificationSelfVerifyStartViewModel(self, otherDidAcceptRequest: currentKeyVerificationRequest)
        case MXKeyVerificationRequestStateReady:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.coordinatorDelegate?.keyVerificationSelfVerifyStartViewModel(self, otherDidAcceptRequest: currentKeyVerificationRequest)
        case MXKeyVerificationRequestStateCancelled:
            guard let reason = keyVerificationRequest.reasonCancelCode else {
                return
            }
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .cancelled(reason))
        case MXKeyVerificationRequestStateCancelledByMe:
            guard let reason = keyVerificationRequest.reasonCancelCode else {
                return
            }
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .cancelledByMe(reason))
        case MXKeyVerificationRequestStateExpired:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .error(UserVerificationStartViewModelError.keyVerificationRequestExpired))
        default:
            break
        }
    }
}
