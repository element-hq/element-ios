// File created from ScreenTemplate
// $ createScreen.sh Verify KeyVerificationVerifyByScanning
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

enum KeyVerificationVerifyByScanningViewModelError: Error {
    case unknown
}

final class KeyVerificationVerifyByScanningViewModel: KeyVerificationVerifyByScanningViewModelType {
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let verificationKind: KeyVerificationKind
    private let keyVerificationRequest: MXKeyVerificationRequest
    private let qrCodeDataCoder: MXQRCodeDataCoder
    private let keyVerificationManager: MXKeyVerificationManager
    
    private var qrCodeTransaction: MXQRCodeTransaction?
    private var scannedQRCodeData: MXQRCodeData?
    
    // MARK: Public

    weak var viewDelegate: KeyVerificationVerifyByScanningViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationVerifyByScanningViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, verificationKind: KeyVerificationKind, keyVerificationRequest: MXKeyVerificationRequest) {
        self.session = session
        self.verificationKind = verificationKind
        keyVerificationManager = self.session.crypto.keyVerificationManager
        self.keyVerificationRequest = keyVerificationRequest
        qrCodeDataCoder = MXQRCodeDataCoder()
    }
    
    deinit {
        self.removePendingQRCodeTransaction()
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationVerifyByScanningViewAction) {
        switch viewAction {
        case .loadData:
            loadData()
        case .scannedCode(payloadData: let payloadData):
            scannedQRCode(payloadData: payloadData)
        case .cannotScan:
            startSASVerification()
        case .cancel:
            cancel()
        case .acknowledgeMyUserScannedOtherCode:
            acknowledgeScanOtherCode()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let qrCodePlayloadData: Data?
        let canShowScanAction: Bool
        
        qrCodeTransaction = keyVerificationManager.qrCodeTransaction(withTransactionId: keyVerificationRequest.requestId)
        
        if let supportedVerificationMethods = keyVerificationRequest.myMethods {
            if let qrCodeData = qrCodeTransaction?.qrCodeData {
                qrCodePlayloadData = qrCodeDataCoder.encode(qrCodeData)
            } else {
                qrCodePlayloadData = nil
            }
            
            canShowScanAction = self.canShowScanAction(from: supportedVerificationMethods)
        } else {
            qrCodePlayloadData = nil
            canShowScanAction = false
        }
        
        let viewData = KeyVerificationVerifyByScanningViewData(verificationKind: verificationKind,
                                                               qrCodeData: qrCodePlayloadData,
                                                               showScanAction: canShowScanAction)
        
        update(viewState: .loaded(viewData: viewData))
        
        registerTransactionDidStateChangeNotification()
    }
    
    private func canShowScanAction(from verificationMethods: [String]) -> Bool {
        verificationMethods.contains(MXKeyVerificationMethodQRCodeScan)
    }
    
    private func cancel() {
        cancelQRCodeTransaction()
        keyVerificationRequest.cancel(with: MXTransactionCancelCode.user(), success: nil, failure: nil)
        unregisterTransactionDidStateChangeNotification()
        coordinatorDelegate?.keyVerificationVerifyByScanningViewModelDidCancel(self)
    }
    
    private func cancelQRCodeTransaction() {
        guard let transaction = qrCodeTransaction else {
            return
        }
        
        transaction.cancel(with: MXTransactionCancelCode.user())
        removePendingQRCodeTransaction()
    }
    
    private func update(viewState: KeyVerificationVerifyByScanningViewState) {
        viewDelegate?.keyVerificationVerifyByScanningViewModel(self, didUpdateViewState: viewState)
    }
    
    // MARK: QR code
    
    private func scannedQRCode(payloadData: Data) {
        scannedQRCodeData = qrCodeDataCoder.decode(payloadData)
        
        let isQRCodeValid = scannedQRCodeData != nil
        
        update(viewState: .scannedCodeValidated(isValid: isQRCodeValid))
    }
    
    private func acknowledgeScanOtherCode() {
        guard let scannedQRCodeData = scannedQRCodeData else {
            return
        }
        
        guard let qrCodeTransaction = qrCodeTransaction else {
            return
        }
        
        unregisterTransactionDidStateChangeNotification()
        coordinatorDelegate?.keyVerificationVerifyByScanningViewModel(self, didScanOtherQRCodeData: scannedQRCodeData, withTransaction: qrCodeTransaction)
    }
    
    private func removePendingQRCodeTransaction() {
        guard let qrCodeTransaction = qrCodeTransaction else {
            return
        }
        keyVerificationManager.removeQRCodeTransaction(withTransactionId: qrCodeTransaction.transactionId)
    }
    
    // MARK: SAS
    
    private func startSASVerification() {
        update(viewState: .loading)
        
        session.crypto.keyVerificationManager.beginKeyVerification(from: keyVerificationRequest, method: MXKeyVerificationMethodSAS, success: { [weak self] keyVerificationTransaction in
            guard let self = self else {
                return
            }
            
            // Remove pending QR code transaction, as we are going to use SAS verification
            self.removePendingQRCodeTransaction()
            
            if keyVerificationTransaction is MXSASTransaction == false || keyVerificationTransaction.isIncoming {
                MXLog.debug("[KeyVerificationVerifyByScanningViewModel] SAS transaction should be outgoing")
                self.unregisterTransactionDidStateChangeNotification()
                self.update(viewState: .error(KeyVerificationVerifyByScanningViewModelError.unknown))
            }
            
        }, failure: { [weak self] error in
            guard let self = self else {
                return
            }
            self.update(viewState: .error(error))
        })
    }
    
    // MARK: - MXKeyVerificationTransactionDidChange
    
    private func registerTransactionDidStateChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: .MXKeyVerificationTransactionDidChange, object: nil)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }
    
    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXKeyVerificationTransaction else {
            return
        }
        
        guard keyVerificationRequest.requestId == transaction.transactionId else {
            MXLog.debug("[KeyVerificationVerifyByScanningViewModel] transactionDidStateChange: Not for our transaction (\(keyVerificationRequest.requestId)): \(transaction.transactionId)")
            return
        }
        
        if let sasTransaction = transaction as? MXSASTransaction {
            sasTransactionDidStateChange(sasTransaction)
        } else if let qrCodeTransaction = transaction as? MXQRCodeTransaction {
            qrCodeTransactionDidStateChange(qrCodeTransaction)
        }
    }
    
    private func sasTransactionDidStateChange(_ transaction: MXSASTransaction) {
        switch transaction.state {
        case MXSASTransactionStateShowSAS:
            unregisterTransactionDidStateChangeNotification()
            coordinatorDelegate?.keyVerificationVerifyByScanningViewModel(self, didStartSASVerificationWithTransaction: transaction)
        case MXSASTransactionStateCancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            unregisterTransactionDidStateChangeNotification()
            update(viewState: .cancelled(cancelCode: reason, verificationKind: verificationKind))
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
    
    private func qrCodeTransactionDidStateChange(_ transaction: MXQRCodeTransaction) {
        switch transaction.state {
        case .verified:
            // Should not happen
            unregisterTransactionDidStateChangeNotification()
            coordinatorDelegate?.keyVerificationVerifyByScanningViewModelDidCancel(self)
        case .qrScannedByOther:
            unregisterTransactionDidStateChangeNotification()
            coordinatorDelegate?.keyVerificationVerifyByScanningViewModel(self, qrCodeDidScannedByOtherWithTransaction: transaction)
        case .cancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            unregisterTransactionDidStateChangeNotification()
            update(viewState: .cancelled(cancelCode: reason, verificationKind: verificationKind))
        case .cancelledByMe:
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
