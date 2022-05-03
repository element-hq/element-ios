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

@available(iOS 14, *)
typealias AuthenticationVerifyEmailViewModelType = StateStoreViewModel<AuthenticationVerifyEmailViewState,
                                                                  Never,
                                                                  AuthenticationVerifyEmailViewAction>
@available(iOS 14, *)
class AuthenticationVerifyEmailViewModel: AuthenticationVerifyEmailViewModelType, AuthenticationVerifyEmailViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((AuthenticationVerifyEmailViewModelResult) -> Void)?

    // MARK: - Setup

    init(emailAddress: String = "") {
        let viewState = AuthenticationVerifyEmailViewState(bindings: AuthenticationVerifyEmailBindings(emailAddress: emailAddress))
        super.init(initialViewState: viewState)
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationVerifyEmailViewAction) {
        switch viewAction {
        case .send:
            completion?(.send(state.bindings.emailAddress))
        case .resend:
            completion?(.resend)
        case .cancel:
            completion?(.cancel)
        }
    }
    
    func updateForSentEmail() {
        state.hasSentEmail = true
    }
}
