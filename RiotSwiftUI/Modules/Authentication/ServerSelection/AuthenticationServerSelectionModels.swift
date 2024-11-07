//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: View model

enum AuthenticationServerSelectionViewModelResult {
    /// The user would like to use the homeserver at the given address.
    case confirm(homeserverAddress: String)
    /// Dismiss the view without using the entered address.
    case dismiss
}

// MARK: View

struct AuthenticationServerSelectionViewState: BindableState {
    /// View state that can be bound to from SwiftUI.
    var bindings: AuthenticationServerSelectionBindings
    /// An error message to be shown in the text field footer.
    var footerErrorMessage: String?
    /// The flow that the screen is being used for.
    let flow: AuthenticationFlow
    /// Whether the screen is presented modally or within a navigation stack.
    var hasModalPresentation: Bool
    
    var headerTitle: String {
        flow == .login ? VectorL10n.authenticationServerSelectionLoginTitle : VectorL10n.authenticationServerSelectionRegisterTitle
    }
    
    var headerMessage: String {
        flow == .login ? VectorL10n.authenticationServerSelectionLoginMessage : VectorL10n.authenticationServerSelectionRegisterMessage
    }
    
    /// The title shown on the confirm button.
    var buttonTitle: String {
        hasModalPresentation ? VectorL10n.confirm : VectorL10n.next
    }
    
    /// The text field is showing an error.
    var isShowingFooterError: Bool {
        footerErrorMessage != nil
    }
    
    /// Whether it is possible to continue when tapping the confirmation button.
    var hasValidationError: Bool {
        bindings.homeserverAddress.isEmpty || isShowingFooterError
    }
}

struct AuthenticationServerSelectionBindings {
    /// The homeserver address input by the user.
    var homeserverAddress: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<AuthenticationServerSelectionErrorType>?
}

enum AuthenticationServerSelectionViewAction {
    /// The user would like to use the homeserver at the input address.
    case confirm
    /// Dismiss the view without using the entered address.
    case dismiss
    /// Clear any errors shown in the text field footer.
    case clearFooterError
}

enum AuthenticationServerSelectionErrorType: Hashable {
    /// An error message to be shown in the text field footer.
    case footerMessage(String)
    /// An error occurred when trying to open the EMS link
    case openURLAlert
}
