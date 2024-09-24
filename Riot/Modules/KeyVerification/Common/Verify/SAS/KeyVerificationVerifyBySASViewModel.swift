// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
/*
 Copyright 2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class KeyVerificationVerifyBySASViewModel: KeyVerificationVerifyBySASViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXSASTransaction
    
    // MARK: Public

    weak var viewDelegate: KeyVerificationVerifyBySASViewModelViewDelegate?
    weak var coordinatorDelegate: KeyVerificationVerifyBySASViewModelCoordinatorDelegate?
    
    let emojis: [MXEmojiRepresentation]?
    let decimal: String?
    let verificationKind: KeyVerificationKind

    // MARK: - Setup
    
    init(session: MXSession, transaction: MXSASTransaction, verificationKind: KeyVerificationKind) {
        self.session = session
        self.transaction = transaction
        self.emojis = self.transaction.sasEmoji
        self.decimal = self.transaction.sasDecimal
        self.verificationKind = verificationKind
    }
    
    // MARK: - Public
    
    func process(viewAction: KeyVerificationVerifyBySASViewAction) {
        switch viewAction {
        case .loadData:
            self.registerTransactionDidStateChangeNotification(transaction: transaction)
        case .confirm:
            self.confirmTransaction()
        case .complete:
            self.coordinatorDelegate?.keyVerificationVerifyViewModelDidComplete(self)
        case .cancel:
            self.cancelTransaction()
            self.coordinatorDelegate?.keyVerificationVerifyViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func confirmTransaction() {
        self.update(viewState: .loading)

        self.transaction.confirmSASMatch()
    }

    private func cancelTransaction() {
        self.transaction.cancel(with: MXTransactionCancelCode.user())
    }
    
    private func update(viewState: KeyVerificationVerifyViewState) {
        self.viewDelegate?.keyVerificationVerifyBySASViewModel(self, didUpdateViewState: viewState)
    }

    // MARK: - MXKeyVerificationTransactionDidChange

    private func registerTransactionDidStateChangeNotification(transaction: MXSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXKeyVerificationTransactionDidChange, object: transaction)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXSASTransaction else {
            return
        }

        switch transaction.state {
        case MXSASTransactionStateVerified:
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.keyVerificationVerifyViewModelDidComplete(self)
        case MXSASTransactionStateCancelled:
            guard let reason = transaction.reasonCancelCode else {
                return
            }
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .cancelled(reason))
        case MXSASTransactionStateError:
            guard let error = transaction.error else {
                return
            }
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .error(error))
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
