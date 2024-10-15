//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

typealias AuthenticationServerSelectionViewModelType = StateStoreViewModel<AuthenticationServerSelectionViewState, AuthenticationServerSelectionViewAction>

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
