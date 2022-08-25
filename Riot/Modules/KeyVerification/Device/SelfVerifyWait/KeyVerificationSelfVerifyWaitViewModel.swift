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
    private var secretsRecoveryAvailability: SecretsRecoveryAvailability
    private var keyVerificationRequest: MXKeyVerificationRequest?
    
    // MARK: Public
    
    weak var viewDelegate: KeyVerificationSelfVerifyWaitViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, isNewSignIn: Bool) {
        self.session = session
        verificationManager = session.crypto.keyVerificationManager
        keyVerificationService = KeyVerificationService()
        self.isNewSignIn = isNewSignIn
        secretsRecoveryAvailability = session.crypto.recoveryService.vc_availability
    }
    
    deinit {
        self.unregisterKeyVerificationManagerNewRequestNotification()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationSelfVerifyWaitViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .cancel:
            cancel()
        case .recoverSecrets:
            switch secretsRecoveryAvailability {
            case .notAvailable:
                fatalError("Should not happen: When recovery is not available button is hidden")
            case .available(let secretsRecoveryMode):
                coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self, wantsToRecoverSecretsWith: secretsRecoveryMode)
            }
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        if !isNewSignIn {
            MXLog.debug("[KeyVerificationSelfVerifyWaitViewModel] loadData: Send a verification request to all devices")
            
            let keyVerificationService = KeyVerificationService()
            verificationManager.requestVerificationByToDevice(withUserId: session.myUserId, deviceIds: nil, methods: keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] keyVerificationRequest in
                guard let self = self else {
                    return
                }
                
                self.keyVerificationRequest = keyVerificationRequest
                
            }, failure: { [weak self] error in
                self?.update(viewState: .error(error))
            })
            
            continueLoadData()
        } else {
            //  be sure that session has completed its first sync
            if session.state >= .running {
                // Always send request instead of waiting for an incoming one as per recent EW changes
                MXLog.debug("[KeyVerificationSelfVerifyWaitViewModel] loadData: Send a verification request to all devices instead of waiting")
                
                let keyVerificationService = KeyVerificationService()
                verificationManager.requestVerificationByToDevice(withUserId: session.myUserId, deviceIds: nil, methods: keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] keyVerificationRequest in
                    guard let self = self else {
                        return
                    }
                    
                    self.keyVerificationRequest = keyVerificationRequest
                    
                }, failure: { [weak self] error in
                    self?.update(viewState: .error(error))
                })
                continueLoadData()
            } else {
                //  show loader
                update(viewState: .secretsRecoveryCheckingAvailability(VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsCheckingAvailability))
                NotificationCenter.default.addObserver(self, selector: #selector(sessionStateChanged), name: .mxSessionStateDidChange, object: session)
            }
        }
    }
    
    @objc
    private func sessionStateChanged() {
        if session.state >= .running {
            NotificationCenter.default.removeObserver(self, name: .mxSessionStateDidChange, object: session)
            continueLoadData()
        }
    }
    
    private func continueLoadData() {
        //  update availability again
        secretsRecoveryAvailability = session.crypto.recoveryService.vc_availability
        
        let viewData = KeyVerificationSelfVerifyWaitViewData(isNewSignIn: isNewSignIn, secretsRecoveryAvailability: secretsRecoveryAvailability)
        
        registerKeyVerificationManagerNewRequestNotification(for: verificationManager)
        update(viewState: .loaded(viewData))
        registerTransactionDidStateChangeNotification()
        registerKeyVerificationRequestChangeNotification()
    }
    
    private func cancel() {
        unregisterKeyVerificationRequestChangeNotification()
        unregisterKeyVerificationManagerNewRequestNotification()
        cancelKeyVerificationRequest()
        coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModelDidCancel(self)
    }
    
    private func update(viewState: KeyVerificationSelfVerifyWaitViewState) {
        viewDelegate?.keyVerificationSelfVerifyWaitViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelKeyVerificationRequest() {
        keyVerificationRequest?.cancel(with: MXTransactionCancelCode.user(), success: nil, failure: nil)
    }
    
    private func acceptKeyVerificationRequest(_ keyVerificationRequest: MXKeyVerificationRequest) {
        keyVerificationRequest.accept(withMethods: keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] in
            guard let self = self else {
                return
            }
            
            self.coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self, didAcceptKeyVerificationRequest: keyVerificationRequest)
            
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }
            self.update(viewState: .error(error))
        })
    }
    
    // MARK: MXKeyVerificationManagerNewRequest
    
    private func registerKeyVerificationManagerNewRequestNotification(for verificationManager: MXKeyVerificationManager) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyVerificationManagerNewRequestNotification(notification:)), name: .MXKeyVerificationManagerNewRequest, object: verificationManager)
        AppDelegate.theDelegate().handleSelfVerificationRequest = false
    }
    
    private func unregisterKeyVerificationManagerNewRequestNotification() {
        AppDelegate.theDelegate().handleSelfVerificationRequest = true
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
        
        unregisterTransactionDidStateChangeNotification()
        acceptKeyVerificationRequest(keyVerificationRequest)
    }
    
    // MARK: MXKeyVerificationRequestDidChangeNotification
    
    private func registerKeyVerificationRequestChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyVerificationRequestChangeNotification(notification:)),
                                               name: .MXKeyVerificationRequestDidChange,
                                               object: nil)
    }
    
    private func unregisterKeyVerificationRequestChangeNotification() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .MXKeyVerificationRequestDidChange,
                                                  object: nil)
    }
    
    @objc private func keyVerificationRequestChangeNotification(notification: Notification) {
        guard let request = notification.object as? MXKeyVerificationRequest else {
            return
        }
        guard let keyVerificationRequest = keyVerificationRequest,
              keyVerificationRequest.requestId == request.requestId else {
            return
        }
        
        guard keyVerificationRequest.isFromMyUser,
              keyVerificationRequest.isFromMyDevice else {
            return
        }
        
        if keyVerificationRequest.state == MXKeyVerificationRequestStateReady {
            unregisterKeyVerificationRequestChangeNotification()
            coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self,
                                                                        didAcceptKeyVerificationRequest: keyVerificationRequest)
        }
    }
    
    // MARK: MXKeyVerificationTransactionDidChange
    
    private func registerTransactionDidStateChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: .MXKeyVerificationTransactionDidChange, object: nil)
    }

    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let sasTransaction = notification.object as? MXIncomingSASTransaction,
              sasTransaction.otherUserId == self.session.myUserId else {
            return
        }
        sasTransactionDidStateChange(sasTransaction)
    }

    private func sasTransactionDidStateChange(_ transaction: MXIncomingSASTransaction) {
        switch transaction.state {
        case MXSASTransactionStateIncomingShowAccept:
            transaction.accept()
        case MXSASTransactionStateShowSAS:
            unregisterTransactionDidStateChangeNotification()
            coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self, didAcceptIncomingSASTransaction: transaction)
        case MXSASTransactionStateCancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            unregisterTransactionDidStateChangeNotification()
            update(viewState: .cancelled(reason))
        case MXSASTransactionStateCancelledByMe:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            unregisterTransactionDidStateChangeNotification()
            update(viewState: .cancelledByMe(reason))
        default:
            break
        }
    }
}
