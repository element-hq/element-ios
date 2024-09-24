// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Incoming DeviceVerificationIncoming
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class DeviceVerificationIncomingViewModel: DeviceVerificationIncomingViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let transaction: MXSASTransaction
    
    // MARK: Public

    let userId: String
    let userDisplayName: String?
    let avatarUrl: String?
    let deviceId: String

    let mediaManager: MXMediaManager

    weak var viewDelegate: DeviceVerificationIncomingViewModelViewDelegate?
    weak var coordinatorDelegate: DeviceVerificationIncomingViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, otherUser: MXUser, transaction: MXSASTransaction) {
        self.session = session
        self.transaction = transaction
        self.userId = otherUser.userId
        self.userDisplayName = otherUser.displayname
        self.avatarUrl = otherUser.avatarUrl
        self.deviceId = transaction.otherDeviceId

        self.mediaManager = session.mediaManager
    }

    // MARK: - Public
    
    func process(viewAction: DeviceVerificationIncomingViewAction) {
        switch viewAction {
        case .loadData:
            self.registerTransactionDidStateChangeNotification(transaction: transaction)
        case .accept:
            self.acceptIncomingDeviceVerification()
        case .cancel:
            self.rejectIncomingDeviceVerification()
            self.coordinatorDelegate?.deviceVerificationIncomingViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func acceptIncomingDeviceVerification() {
        self.update(viewState: .loading)
        self.transaction.accept()
    }

    private func rejectIncomingDeviceVerification() {
        self.transaction.cancel(with: MXTransactionCancelCode.user())
    }
    
    private func update(viewState: DeviceVerificationIncomingViewState) {
        self.viewDelegate?.deviceVerificationIncomingViewModel(self, didUpdateViewState: viewState)
    }

    // MARK: - MXKeyVerificationTransactionDidChange

    private func registerTransactionDidStateChangeNotification(transaction: MXSASTransaction) {
        NotificationCenter.default.addObserver(self, selector: #selector(transactionDidStateChange(notification:)), name: NSNotification.Name.MXKeyVerificationTransactionDidChange, object: transaction)
    }
    
    private func unregisterTransactionDidStateChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationTransactionDidChange, object: nil)
    }

    @objc private func transactionDidStateChange(notification: Notification) {
        guard let transaction = notification.object as? MXSASTransaction, transaction.isIncoming else {
            return
        }

        switch transaction.state {
        case MXSASTransactionStateShowSAS:
            self.unregisterTransactionDidStateChangeNotification()
            self.update(viewState: .loaded)
            self.coordinatorDelegate?.deviceVerificationIncomingViewModel(self, didAcceptTransaction: self.transaction)
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
