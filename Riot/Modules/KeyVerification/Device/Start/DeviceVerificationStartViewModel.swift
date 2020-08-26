// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
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

final class DeviceVerificationStartViewModel: DeviceVerificationStartViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let verificationManager: MXKeyVerificationManager
    private let otherUser: MXUser
    private let otherDevice: MXDeviceInfo

    private var transaction: MXSASTransaction!
    
    // MARK: Public

    weak var viewDelegate: DeviceVerificationStartViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationStartViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, otherDevice: MXDeviceInfo) {
        self.session = session
        self.verificationManager = session.crypto.keyVerificationManager
        self.otherUser = otherUser
        self.otherDevice = otherDevice
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationStartViewAction) {
        switch viewAction {
        case .beginVerifying:
            self.beginVerifying()
        case .verifyUsingLegacy:
           self.cancelTransaction()
           self.update(viewState: .verifyUsingLegacy(self.session, self.otherDevice))
        case .verifiedUsingLegacy:
            self.coordinatorDelegate?.deviceVerificationStartViewModelDidUseLegacyVerification(self)
        case .cancel:
            self.cancelTransaction()
            self.coordinatorDelegate?.deviceVerificationStartViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func beginVerifying() {
        self.update(viewState: .loading)

        self.verificationManager.beginKeyVerification(withUserId: self.otherUser.userId, andDeviceId: self.otherDevice.deviceId, method: MXKeyVerificationMethodSAS, success: { [weak self] (transaction) in

            guard let sself = self else {
                return
            }
            guard let sasTransaction: MXOutgoingSASTransaction = transaction as? MXOutgoingSASTransaction  else {
                return
            }

            sself.transaction = sasTransaction

            sself.update(viewState: .loaded)
            sself.registerTransactionDidStateChangeNotification(transaction: sasTransaction)
        }, failure: {[weak self]  error in
            self?.update(viewState: .error(error))
        })
    }

    private func cancelTransaction() {
        guard let transaction = self.transaction  else {
            return
        }

        transaction.cancel(with: MXTransactionCancelCode.user())
    }
    
    private func update(viewState: DeviceVerificationStartViewState) {
        self.viewDelegate?.deviceVerificationStartViewModel(self, didUpdateViewState: viewState)
    }


    // MARK: - MXKeyVerificationTransactionDidChange

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
            self.coordinatorDelegate?.deviceVerificationStartViewModel(self, didCompleteWithOutgoingTransaction: transaction)
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
