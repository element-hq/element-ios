// File created from ScreenTemplate
// $ createScreen.sh KeyVerification KeyVerificationSelfVerifyWait
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

final class KeyVerificationSelfVerifyWaitViewModel: KeyVerificationSelfVerifyWaitViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let keyVerificationService: KeyVerificationService
    private let verificationManager: MXKeyVerificationManager
    private let isNewSignIn: Bool
    
    private var keyVerificationRequest: MXKeyVerificationRequest?
    
    // MARK: Public
    
    weak var viewDelegate: KeyVerificationSelfVerifyWaitViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, isNewSignIn: Bool) {
        self.session = session
        self.verificationManager = session.crypto.keyVerificationManager
        self.keyVerificationService = KeyVerificationService()
        self.isNewSignIn = isNewSignIn
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationSelfVerifyWaitViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .cancel:
            self.cancel()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        self.registerKeyVerificationManagerNewRequestNotification(for: self.verificationManager)
        self.update(viewState: .loaded(self.isNewSignIn))
    }
    
    private func cancel() {
        self.unregisterKeyVerificationManagerNewRequestNotification()
        self.cancelKeyVerificationRequest()
        self.coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModelDidCancel(self)
    }
    
    private func update(viewState: KeyVerificationSelfVerifyWaitViewState) {
        self.viewDelegate?.keyVerificationSelfVerifyWaitViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelKeyVerificationRequest() {
        self.keyVerificationRequest?.cancel(with: MXTransactionCancelCode.user(), success: nil, failure: nil)
    }
    
    private func acceptKeyVerificationRequest(_ keyVerificationRequest: MXKeyVerificationRequest) {
        
        keyVerificationRequest.accept(withMethods: self.keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self, didAcceptKeyVerificationRequest: keyVerificationRequest)
            
            }, failure: { [weak self] (error) in
                guard let self = self else {
                    return
                }
                self.update(viewState: .error(error))
        })
    }
    
    // MARK: MXKeyVerificationManagerNewRequest
    
    private func registerKeyVerificationManagerNewRequestNotification(for verificationManager: MXKeyVerificationManager) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyVerificationManagerNewRequestNotification(notification:)), name: .MXKeyVerificationManagerNewRequest, object: verificationManager)
    }
    
    private func unregisterKeyVerificationManagerNewRequestNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationManagerNewRequest, object: nil)
    }
    
    @objc private func keyVerificationManagerNewRequestNotification(notification: Notification) {
        
        guard let userInfo = notification.userInfo, let keyVerificationRequest = userInfo[MXKeyVerificationManagerNotificationRequestKey] as? MXKeyVerificationByToDeviceRequest else {
            return
        }
        
        guard keyVerificationRequest.isFromMyUser,
            keyVerificationRequest.isFromMyDevice == false,
            keyVerificationRequest.state == MXKeyVerificationRequestStatePending else {
            return
        }
        
        self.acceptKeyVerificationRequest(keyVerificationRequest)
    }
}
