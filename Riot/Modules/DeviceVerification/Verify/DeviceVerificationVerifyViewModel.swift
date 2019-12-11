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

final class DeviceVerificationVerifyViewModel: DeviceVerificationVerifyViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXSASTransaction
    
    // MARK: Public

    weak var viewDelegate: DeviceVerificationVerifyViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationVerifyViewModelCoordinatorDelegate?
    var emojis: [MXEmojiRepresentation]?
    var decimal: String?

    // MARK: - Setup
    
    init(session: MXSession, transaction: MXSASTransaction) {
        self.session = session
        self.transaction = transaction
        self.emojis = self.transaction.sasEmoji
        self.decimal = self.transaction.sasDecimal
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationVerifyViewAction) {
        switch viewAction {
        case .loadData:
            self.registerTransactionDidStateChangeNotification(transaction: transaction)
        case .confirm:
            self.confirmTransaction()
        case .complete:
            self.coordinatorDelegate?.deviceVerificationVerifyViewModelDidComplete(self)
        case .cancel:
            self.cancelTransaction()
            self.coordinatorDelegate?.deviceVerificationVerifyViewModelDidCancel(self)
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
    
    private func update(viewState: DeviceVerificationVerifyViewState) {
        self.viewDelegate?.deviceVerificationVerifyViewModel(self, didUpdateViewState: viewState)
    }

    // MARK: - MXDeviceVerificationTransactionDidChange

    private func registerTransactionDidStateChangeNotification(transaction: MXSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXDeviceVerificationTransactionDidChange, object: transaction)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXDeviceVerificationTransactionDidChange, object: nil)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXSASTransaction else {
            return
        }

        switch transaction.state {
        case MXSASTransactionStateVerified:
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.deviceVerificationVerifyViewModelDidComplete(self)
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
