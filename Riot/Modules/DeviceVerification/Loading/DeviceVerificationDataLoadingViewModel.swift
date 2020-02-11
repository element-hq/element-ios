// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
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

enum DeviceVerificationDataLoadingViewModelError: Error {
    case unknown
    case transactionCancelled
    case transactionCancelledByMe(reason: MXTransactionCancelCode)
}

final class DeviceVerificationDataLoadingViewModel: DeviceVerificationDataLoadingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession?
    private let otherUserId: String?
    private let otherDeviceId: String?
    
    private let keyVerificationRequest: MXKeyVerificationRequest?
    
    private var currentOperation: MXHTTPOperation?
    
    // MARK: Public

    weak var viewDelegate: DeviceVerificationDataLoadingViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationDataLoadingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUserId: String, otherDeviceId: String) {
        self.session = session
        self.otherUserId = otherUserId
        self.otherDeviceId = otherDeviceId
        self.keyVerificationRequest = nil
    }
    
    init(keyVerificationRequest: MXKeyVerificationRequest) {
        self.session = nil
        self.otherUserId = nil
        self.otherDeviceId = nil
        self.keyVerificationRequest = keyVerificationRequest
    }
    
    deinit {
        self.currentOperation?.cancel()
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationDataLoadingViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .cancel:
            self.coordinatorDelegate?.deviceVerificationDataLoadingViewModelDidCancel(self)
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
        
        keyVerificationRequest.accept(withMethod: MXKeyVerificationMethodSAS, success: { [weak self] (deviceVerificationTransaction) in
            guard let self = self else {
                return
            }
            
            if let outgoingSASTransaction = deviceVerificationTransaction as? MXOutgoingSASTransaction {
                self.registerTransactionDidStateChangeNotification(transaction: outgoingSASTransaction)
            } else {
                self.update(viewState: .error(DeviceVerificationDataLoadingViewModelError.unknown))
            }
            
        }, failure: { [weak self] (error) in
            guard let self = self else {
                return
            }
            self.update(viewState: .error(error))
        })
    }
    
    private func downloadOtherDeviceKeys() {
        guard let session = self.session,
            let crypto = session.crypto,
            let otherUserId = self.otherUserId,
            let otherDeviceId = self.otherDeviceId else {
            self.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
            NSLog("[DeviceVerificationDataLoadingViewModel] Error session.crypto is nil")
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
                    sself.coordinatorDelegate?.deviceVerificationDataLoadingViewModel(sself, didLoadUser: otherUser, device: otherDevice)
                } else {
                    sself.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
                }
                
                }, failure: { [weak self] (error) in
                    guard let sself = self else {
                        return
                    }
                    
                    let finalError = error ?? DeviceVerificationDataLoadingViewModelError.unknown
                    
                    sself.update(viewState: .error(finalError))
            })
            
        } else {
            self.update(viewState: .errorMessage(VectorL10n.deviceVerificationErrorCannotLoadDevice))
        }
    }
    
    private func update(viewState: DeviceVerificationDataLoadingViewState) {
        self.viewDelegate?.deviceVerificationDataLoadingViewModel(self, didUpdateViewState: viewState)
    }
    
    // MARK: MXKeyVerificationTransactionDidChange
    
    private func registerTransactionDidStateChangeNotification(transaction: MXOutgoingSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXKeyVerificationTransactionDidChange, object: transaction)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }
    
    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXOutgoingSASTransaction else {
            return
        }
        
        switch transaction.state {
        case MXSASTransactionStateShowSAS:
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.deviceVerificationDataLoadingViewModel(self, didAcceptKeyVerificationWithTransaction: transaction)
        case MXSASTransactionStateCancelled:
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .error(DeviceVerificationDataLoadingViewModelError.transactionCancelled))
        case MXSASTransactionStateCancelledByMe:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .error(DeviceVerificationDataLoadingViewModelError.transactionCancelledByMe(reason: reason)))
        default:
            break
        }
    }
}
