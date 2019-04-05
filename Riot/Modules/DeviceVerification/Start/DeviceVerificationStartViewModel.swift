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
    private let verificationManager: MXDeviceVerificationManager
    private let otherUser: MXUser
    private let otherDevice: MXDeviceInfo
    
    // MARK: Public
    
    var message: String?

    weak var viewDelegate: DeviceVerificationStartViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationStartViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, otherDevice: MXDeviceInfo) {
        self.session = session
        self.verificationManager = session.crypto.deviceVerificationManager
        self.otherUser = otherUser
        self.otherDevice = otherDevice
        self.message = nil
    }
    
    deinit {
    }
    
    // MARK: - Public
    
    func process(viewAction: DeviceVerificationStartViewAction) {
        switch viewAction {
        case .useLegacyVerification:
            self.coordinatorDelegate?.deviceVerificationStartViewModelUseLegacyVerification(self)
        case .beginVerifying:
            self.beginVerifying()
        case .cancel:
            self.coordinatorDelegate?.deviceVerificationStartViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func beginVerifying() {

        self.update(viewState: .loading)

        self.verificationManager.beginKeyVerification(withUserId: self.otherUser.userId, andDeviceId: self.otherDevice.deviceId, method: kMXKeyVerificationMethodSAS, complete: { [weak self] (transaction) in

            guard let sself = self else {
                return
            }
            guard let sasTransaction: MXOutgoingSASTransaction = transaction as? MXOutgoingSASTransaction  else {
                return
            }

            sself.message = transaction?.description

            sself.registerTransactionDidStateChangeNotification(transaction: sasTransaction)
            sself.update(viewState: .loaded)

            print("\(String(describing: transaction))")
        })
    }
    
    private func update(viewState: DeviceVerificationStartViewState) {
        self.viewDelegate?.deviceVerificationStartViewModel(self, didUpdateViewState: viewState)
    }


    // MARK: - MXDeviceVerificationTransactionDidChange

    private func registerTransactionDidStateChangeNotification(transaction: MXOutgoingSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXDeviceVerificationTransactionDidChange, object: transaction)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXOutgoingSASTransaction else {
            return
        }

        // TODO: To remove
        self.message = transaction.description
        self.update(viewState: .loaded)

        switch transaction.state {
        case MXOutgoingSASTransactionStateShowSAS:
            self.message = transaction.sasEmoji?.description
            self.coordinatorDelegate?.deviceVerificationStartViewModel(self, didCompleteWithOutgoingTransaction: transaction)
        case MXOutgoingSASTransactionStateCancelled:
            self.coordinatorDelegate?.deviceVerificationStartViewModel(self, didTransactionCancelled: transaction)
        default:
            break
        }
    }
}
