//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias AuthenticationVerifyMsisdnViewModelType = StateStoreViewModel<AuthenticationVerifyMsisdnViewState, AuthenticationVerifyMsisdnViewAction>

class AuthenticationVerifyMsisdnViewModel: AuthenticationVerifyMsisdnViewModelType, AuthenticationVerifyMsisdnViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationVerifyMsisdnViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserver: AuthenticationHomeserverViewData, phoneNumber: String = "", otp: String = "") {
        let viewState = AuthenticationVerifyMsisdnViewState(homeserver: .mockMatrixDotOrg,
                                                            bindings: AuthenticationVerifyMsisdnBindings(phoneNumber: phoneNumber, otp: otp))
        super.init(initialViewState: viewState)
    }

    // MARK: - Public
    
    override func process(viewAction: AuthenticationVerifyMsisdnViewAction) {
        switch viewAction {
        case .send:
            Task { await callback?(.send(state.bindings.phoneNumber)) }
        case .submitOTP:
            Task { await callback?(.submitOTP(state.bindings.otp)) }
        case .resend:
            Task { await callback?(.resend) }
        case .cancel:
            Task { await callback?(.cancel) }
        case .goBack:
            Task { await callback?(.goBack) }
        }
    }
    
    @MainActor func updateForSentSMS() {
        state.hasSentSMS = true
    }

    @MainActor func goBackToMsisdnForm() {
        state.hasSentSMS = false
        state.bindings.otp = ""
    }
    
    @MainActor func displayError(_ type: AuthenticationVerifyMsisdnErrorType) {
        switch type {
        case .mxError(let message):
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: message)
        case .invalidPhoneNumber:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: VectorL10n.error,
                                                 message: VectorL10n.authenticationVerifyMsisdnInvalidPhoneNumber)
        case .unknown:
            state.bindings.alertInfo = AlertInfo(id: type)
        }
    }
}
