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
    private let verificationManager: MXKeyVerificationManager?
    private let isNewSignIn: Bool
    private var secretsRecoveryAvailability: SecretsRecoveryAvailability?
    private var keyVerificationRequest: MXKeyVerificationRequest?
    
    private var myUserId: String {
        guard let userId = session.myUserId else {
            MXLog.error("[KeyVerificationSelfVerifyWaitViewModel] userId is missing")
            return ""
        }
        return userId
    }
    
    // MARK: Public
    
    weak var viewDelegate: KeyVerificationSelfVerifyWaitViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationSelfVerifyWaitViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, isNewSignIn: Bool) {
        self.session = session
        self.verificationManager = session.crypto?.keyVerificationManager
        self.keyVerificationService = KeyVerificationService()
        self.isNewSignIn = isNewSignIn
        self.secretsRecoveryAvailability = session.crypto?.recoveryService.vc_availability
    }
    
    deinit {
        self.unregisterKeyVerificationManagerNewRequestNotification()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationSelfVerifyWaitViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .cancel:
            self.cancel()
        case .recoverSecrets:
            guard let availability = secretsRecoveryAvailability else {
                MXLog.error("[KeyVerificationSelfVerifyWaitViewModel] process: secretsRecoveryAvailability not set")
                self.cancel()
                return
            }
            
            switch availability {
            case .notAvailable:
                MXLog.error("Should not happen: When recovery is not available button is hidden")
                self.cancel()
            case .available(let secretsRecoveryMode):
                self.coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self, wantsToRecoverSecretsWith: secretsRecoveryMode)
            }
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        guard let verificationManager = verificationManager else {
            MXLog.failure("Verification manager is not set")
            return
        }
        
        if !self.isNewSignIn {
            MXLog.debug("[KeyVerificationSelfVerifyWaitViewModel] loadData: Send a verification request to all devices")
            
            let keyVerificationService = KeyVerificationService()
            verificationManager.requestVerificationByToDevice(withUserId: self.myUserId, deviceIds: nil, methods: keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] (keyVerificationRequest) in
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
                
                if let existingRequest = verificationManager.pendingRequests.first(where: { $0.isFromMyUser && !$0.isFromMyDevice && $0.state == MXKeyVerificationRequestStatePending }) {
                    MXLog.debug("[KeyVerificationSelfVerifyWaitViewModel] loadData: Accepting an existing self-verification request instead of starting a new one")
                    
                    registerTransactionDidStateChangeNotification()
                    acceptKeyVerificationRequest(existingRequest)
                } else {
                    
                    // Always send request instead of waiting for an incoming one as per recent EW changes
                    MXLog.debug("[KeyVerificationSelfVerifyWaitViewModel] loadData: Send a verification request to all devices instead of waiting")
                    
                    let keyVerificationService = KeyVerificationService()
                    verificationManager.requestVerificationByToDevice(withUserId: self.myUserId, deviceIds: nil, methods: keyVerificationService.supportedKeyVerificationMethods(), success: { [weak self] (keyVerificationRequest) in
                        guard let self = self else {
                            return
                        }
                        
                        self.keyVerificationRequest = keyVerificationRequest
                        
                    }, failure: { [weak self] error in
                        self?.update(viewState: .error(error))
                    })
                    continueLoadData()
                }
            } else {
                //  show loader
                self.update(viewState: .secretsRecoveryCheckingAvailability(VectorL10n.deviceVerificationSelfVerifyWaitRecoverSecretsCheckingAvailability))
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
        guard let verificationManager = verificationManager, let recoveryService = session.crypto?.recoveryService else {
            MXLog.error("[KeyVerificationSelfVerifyWaitViewModel] continueLoadData: Missing dependencies")
            return
        }
        
        //  update availability again
        let availability = recoveryService.vc_availability
        self.secretsRecoveryAvailability = availability
        
        let viewData = KeyVerificationSelfVerifyWaitViewData(isNewSignIn: self.isNewSignIn, secretsRecoveryAvailability: availability)
        
        self.registerKeyVerificationManagerNewRequestNotification(for: verificationManager)
        self.update(viewState: .loaded(viewData))
        self.registerTransactionDidStateChangeNotification()
        self.registerKeyVerificationRequestChangeNotification()
    }
    
    private func cancel() {
        self.unregisterKeyVerificationRequestChangeNotification()
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
        AppDelegate.theDelegate().handleSelfVerificationRequest = false
    }
    
    private func unregisterKeyVerificationManagerNewRequestNotification() {
        AppDelegate.theDelegate().handleSelfVerificationRequest = true
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationManagerNewRequest, object: nil)
    }
    
    @objc private func keyVerificationManagerNewRequestNotification(notification: Notification) {
        
        guard let userInfo = notification.userInfo, let keyVerificationRequest = userInfo[MXKeyVerificationManagerNotificationRequestKey] as? MXKeyVerificationRequest, keyVerificationRequest.transport == .toDevice else {
            return
        }
        
        guard keyVerificationRequest.isFromMyUser,
            keyVerificationRequest.isFromMyDevice == false,
            keyVerificationRequest.state == MXKeyVerificationRequestStatePending else {
            return
        }
        
        self.unregisterTransactionDidStateChangeNotification()
        self.acceptKeyVerificationRequest(keyVerificationRequest)
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
            self.unregisterKeyVerificationRequestChangeNotification()
            self.coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self,
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
        guard let sasTransaction = notification.object as? MXSASTransaction,
            sasTransaction.isIncoming, sasTransaction.otherUserId == self.myUserId else {
            return
        }
        self.sasTransactionDidStateChange(sasTransaction)
    }

    private func sasTransactionDidStateChange(_ transaction: MXSASTransaction) {
        switch transaction.state {
        case MXSASTransactionStateIncomingShowAccept:
            // The transaction will be automatically accepted by the MXKeyVerificationManager when the SAS start event is handled
            break
        case MXSASTransactionStateShowSAS:
            self.unregisterTransactionDidStateChangeNotification()
            self.coordinatorDelegate?.keyVerificationSelfVerifyWaitViewModel(self, didAcceptIncomingSASTransaction: transaction)
        case MXSASTransactionStateCancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .cancelled(reason))
        case MXSASTransactionStateCancelledByMe:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .cancelledByMe(reason))
        default:
            break
        }
    }
}
