//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
