// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
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

final class DeviceVerificationIncomingViewModel: DeviceVerificationIncomingViewModelType {
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXIncomingSASTransaction
    
    // MARK: Public

    let userId: String
    let userDisplayName: String?
    let avatarUrl: String?
    let deviceId: String

    let mediaManager: MXMediaManager

    weak var viewDelegate: DeviceVerificationIncomingViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationIncomingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, transaction: MXIncomingSASTransaction) {
        self.session = session
        self.transaction = transaction
        userId = otherUser.userId
        userDisplayName = otherUser.displayname
        avatarUrl = otherUser.avatarUrl
        deviceId = transaction.otherDeviceId

        mediaManager = session.mediaManager
    }

    // MARK: - Public
    
    func process(viewAction: DeviceVerificationIncomingViewAction) {
        switch viewAction {
        case .loadData:
            registerTransactionDidStateChangeNotification(transaction: transaction)
        case .accept:
            acceptIncomingDeviceVerification()
        case .cancel:
            rejectIncomingDeviceVerification()
            coordinatorDelegate?.deviceVerificationIncomingViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func acceptIncomingDeviceVerification() {
        update(viewState: .loading)
        transaction.accept()
    }

    private func rejectIncomingDeviceVerification() {
        transaction.cancel(with: MXTransactionCancelCode.user())
    }
    
    private func update(viewState: DeviceVerificationIncomingViewState) {
        viewDelegate?.deviceVerificationIncomingViewModel(self, didUpdateViewState: viewState)
    }

    // MARK: - MXKeyVerificationTransactionDidChange

    private func registerTransactionDidStateChangeNotification(transaction: MXIncomingSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXKeyVerificationTransactionDidChange, object: transaction)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXIncomingSASTransaction else {
            return
        }

        switch transaction.state {
        case MXSASTransactionStateShowSAS:
            unregisterTransactionDidStateChangeNotification()
            update(viewState: .loaded)
            coordinatorDelegate?.deviceVerificationIncomingViewModel(self, didAcceptTransaction: self.transaction)
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
