// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyStart
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
        verificationManager = session.crypto.keyVerificationManager
        self.otherDeviceId = otherDeviceId
        keyVerificationService = KeyVerificationService()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationSelfVerifyStartViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .startVerification:
            startVerification()
        case .cancel:
            cancelKeyVerificationRequest()
            coordinatorDelegate?.keyVerificationSelfVerifyStartViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        startVerification()
    }
    
    private func startVerification() {
        update(viewState: .verificationPending)
        
        verificationManager.requestVerificationByToDevice(withUserId: session.myUser.userId, deviceIds: [otherDeviceId], methods: keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] keyVerificationRequest in
            guard let self = self else {
                return
            }
            
            self.keyVerificationRequest = keyVerificationRequest
            self.update(viewState: .loaded)
            self.registerKeyVerificationRequestDidChangeNotification(for: keyVerificationRequest)
        }, failure: { [weak self] error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: KeyVerificationSelfVerifyStartViewState) {
        viewDelegate?.keyVerificationSelfVerifyStartViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelKeyVerificationRequest() {
        guard let keyVerificationRequest = keyVerificationRequest else {
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
            unregisterKeyVerificationRequestDidChangeNotification()
            coordinatorDelegate?.keyVerificationSelfVerifyStartViewModel(self, otherDidAcceptRequest: currentKeyVerificationRequest)
        case MXKeyVerificationRequestStateReady:
            unregisterKeyVerificationRequestDidChangeNotification()
            coordinatorDelegate?.keyVerificationSelfVerifyStartViewModel(self, otherDidAcceptRequest: currentKeyVerificationRequest)
        case MXKeyVerificationRequestStateCancelled:
            guard let reason = keyVerificationRequest.reasonCancelCode else {
                return
            }
            unregisterKeyVerificationRequestDidChangeNotification()
            update(viewState: .cancelled(reason))
        case MXKeyVerificationRequestStateCancelledByMe:
            guard let reason = keyVerificationRequest.reasonCancelCode else {
                return
            }
            unregisterKeyVerificationRequestDidChangeNotification()
            update(viewState: .cancelledByMe(reason))
        case MXKeyVerificationRequestStateExpired:
            unregisterKeyVerificationRequestDidChangeNotification()
            update(viewState: .error(UserVerificationStartViewModelError.keyVerificationRequestExpired))
        default:
            break
        }
    }
}
