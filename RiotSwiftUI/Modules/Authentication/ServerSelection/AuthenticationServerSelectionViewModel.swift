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

typealias AuthenticationServerSelectionViewModelType = StateStoreViewModel<AuthenticationServerSelectionViewState,
                                                                           Never,
                                                                           AuthenticationServerSelectionViewAction>

class AuthenticationServerSelectionViewModel: AuthenticationServerSelectionViewModelType, AuthenticationServerSelectionViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var callback: (@MainActor (AuthenticationServerSelectionViewModelResult) -> Void)?

    // MARK: - Setup

    init(homeserverAddress: String, flow: AuthenticationFlow, hasModalPresentation: Bool) {
        let bindings = AuthenticationServerSelectionBindings(homeserverAddress: homeserverAddress)
        super.init(initialViewState: AuthenticationServerSelectionViewState(bindings: bindings,
                                                                            flow: flow,
                                                                            hasModalPresentation: hasModalPresentation))
    }

    // MARK: - Public

    override func process(viewAction: AuthenticationServerSelectionViewAction) {
        switch viewAction {
        case .confirm:
            Task { await callback?(.confirm(homeserverAddress: state.bindings.homeserverAddress)) }
        case .dismiss:
            Task { await callback?(.dismiss) }
        case .clearFooterError:
            Task { await clearFooterError() }
        }
    }
    
    @MainActor func displayError(_ type: AuthenticationServerSelectionErrorType) {
        switch type {
        case .footerMessage(let message):
            withAnimation {
                state.footerErrorMessage = message
            }
        case .openURLAlert:
            state.bindings.alertInfo = AlertInfo(id: .openURLAlert, title: VectorL10n.roomMessageUnableOpenLinkErrorMessage)
        }
    }
    
    // MARK: - Private
    
    /// Clear any errors shown in the text field footer.
    @MainActor private func clearFooterError() {
        guard state.footerErrorMessage != nil else { return }
        withAnimation { state.footerErrorMessage = nil }
    }
}
