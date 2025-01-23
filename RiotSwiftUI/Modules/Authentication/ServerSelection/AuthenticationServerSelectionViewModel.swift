//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
        case .downloadReplacementApp(let replacementApp):
            Task { await callback?(.downloadReplacementApp(replacementApp)) }
        }
    }
    
    @MainActor func displayError(_ type: AuthenticationServerSelectionErrorType) {
        switch type {
        case .footerMessage(let message):
            withAnimation {
                state.footerError = .message(message)
            }
        case .openURLAlert:
            state.bindings.alertInfo = AlertInfo(id: .openURLAlert, title: VectorL10n.roomMessageUnableOpenLinkErrorMessage)
        case .requiresReplacementApp:
            withAnimation {
                state.footerError = .sunsetBanner
            }
        }
    }
    
    // MARK: - Private
    
    /// Clear any errors shown in the text field footer.
    @MainActor private func clearFooterError() {
        guard state.footerError != nil else { return }
        withAnimation { state.footerError = nil }
    }
}
