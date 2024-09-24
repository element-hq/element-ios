// File created from ScreenTemplate
// $ createScreen.sh DeviceVerification/Start DeviceVerificationStart
/*
 Copyright 2017-2024 New Vector Ltd
 
 SPDX-License-Identifier: AGPL-3.0-only
 Please see LICENSE in the repository root for full details.
 */

import Foundation

final class DeviceVerificationStartViewModel: DeviceVerificationStartViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let verificationManager: MXKeyVerificationManager
    private let otherUser: MXUser
    private let otherDevice: MXDeviceInfo

    private var request: MXKeyVerificationRequest?
    
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
           self.cancelRequest()
           self.update(viewState: .verifyUsingLegacy(self.session, self.otherDevice))
        case .verifiedUsingLegacy:
            self.coordinatorDelegate?.deviceVerificationStartViewModelDidUseLegacyVerification(self)
        case .cancel:
            self.cancelRequest()
            self.coordinatorDelegate?.deviceVerificationStartViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func beginVerifying() {
        self.update(viewState: .loading)

        self.verificationManager.requestVerificationByToDevice(withUserId: otherUser.userId, deviceIds: [otherDevice.deviceId], methods: [MXKeyVerificationMethodSAS], success: { [weak self] request in
            guard let self = self else {
                return
            }

            self.request = request

            self.update(viewState: .loaded)
            self.registerKeyVerificationRequestDidChangeNotification(for: request)
        }, failure: {[weak self]  error in
            self?.update(viewState: .error(error))
        })
    }

    private func cancelRequest() {
        request?.cancel(with: MXTransactionCancelCode.user(), success: nil)
    }
    
    private func update(viewState: DeviceVerificationStartViewState) {
        self.viewDelegate?.deviceVerificationStartViewModel(self, didUpdateViewState: viewState)
    }


    // MARK: - MXKeyVerificationRequestDidChange

    private func registerKeyVerificationRequestDidChangeNotification(for request: MXKeyVerificationRequest) {
        NotificationCenter.default.addObserver(self, selector: #selector(requestDidStateChange(notification:)), name: .MXKeyVerificationRequestDidChange, object: request)
    }
    
    private func unregisterKeyVerificationRequestDidChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationRequestDidChange, object: nil)
    }
    
    @objc private func requestDidStateChange(notification: Notification) {
        guard let request = notification.object as? MXKeyVerificationRequest, request.requestId == self.request?.requestId else {
            return
        }

        switch request.state {
        case MXKeyVerificationRequestStateAccepted, MXKeyVerificationRequestStateReady:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.coordinatorDelegate?.deviceVerificationStartViewModel(self, otherDidAcceptRequest: request)
            
        case MXKeyVerificationRequestStateCancelled:
            guard let reason = request.reasonCancelCode else {
                return
            }
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .cancelled(reason))
        case MXKeyVerificationRequestStateCancelledByMe:
            guard let reason = request.reasonCancelCode else {
                return
            }
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .cancelledByMe(reason))
        case MXKeyVerificationRequestStateExpired:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .error(UserVerificationStartViewModelError.keyVerificationRequestExpired))
        default:
            break
        }
    }
}
