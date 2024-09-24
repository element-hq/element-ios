// File created from ScreenTemplate
// $ createScreen.sh KeyVerification/Common/ScanConfirmation KeyVerificationScanConfirmation
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyVerificationScanConfirmationViewModel: KeyVerificationScanConfirmationViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXQRCodeTransaction
    private let codeScanning: KeyVerificationScanning
    private let verificationKind: KeyVerificationKind
    
    private var isScanning: Bool {
        if case .scannedOtherQRCode = self.codeScanning {
            return true
        }
        return false
    }
    
    // MARK: Public

    weak var viewDelegate: KeyVerificationScanConfirmationViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationScanConfirmationViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession,
         transaction: MXQRCodeTransaction,
         codeScanning: KeyVerificationScanning,
         verificationKind: KeyVerificationKind) {
        self.session = session
        self.transaction = transaction
        self.codeScanning = codeScanning
        self.verificationKind = verificationKind
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationScanConfirmationViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .acknowledgeOtherScannedMyCode(let otherHasScannedMyCode):
            self.transaction.otherUserScannedMyQrCode(otherHasScannedMyCode)
            if otherHasScannedMyCode == false {                self.coordinatorDelegate?.keyVerificationScanConfirmationViewModelDidCancel(self)
            } else {
                self.update(viewState: .loading)
            }
        case .cancel:
            self.cancel()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        let otherUserId = self.transaction.otherUserId
        let otherUser = self.session.user(withUserId: otherUserId)
        let otherDisplayName = otherUser?.displayname ?? otherUserId
        
        let viewData = KeyVerificationScanConfirmationViewData(isScanning: self.isScanning, verificationKind: self.verificationKind, otherDisplayName: otherDisplayName)
        self.update(viewState: .loaded(viewData))
        
        self.registerTransactionDidStateChangeNotification()
        
        if case .scannedOtherQRCode(let qrCodeData) = self.codeScanning {
            self.transaction.userHasScannedOtherQrCodeData(qrCodeData)
        }
    }
    
    private func update(viewState: KeyVerificationScanConfirmationViewState) {
        self.viewDelegate?.keyVerificationScanConfirmationViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancel() {
        self.transaction.cancel(with: MXTransactionCancelCode.user())
        self.coordinatorDelegate?.keyVerificationScanConfirmationViewModelDidCancel(self)
    }
    
    // MARK: - MXKeyVerificationTransactionDidChange
    
    private func registerTransactionDidStateChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: .MXKeyVerificationTransactionDidChange, object: self.transaction)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }
    
    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXQRCodeTransaction else {
            return
        }

        switch transaction.state {
        case .verified:
            self.unregisterTransactionDidStateChangeNotification()
            self.coordinatorDelegate?.keyVerificationScanConfirmationViewModelDidComplete(self)
        case .cancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .cancelled(reason))
        case .cancelledByMe:
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
