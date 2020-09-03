// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Verify DeviceVerificationVerify
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
