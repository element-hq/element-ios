//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: View model

enum OnboardingDisplayNameViewModelResult {
    /// The user would like to save the entered display name.
    case save(String)
    /// Move on to the next screen in the flow without setting a display name.
    case skip
}

// MARK: View

struct OnboardingDisplayNameViewState: BindableState {
    var bindings: OnboardingDisplayNameBindings
    /// Any error that occurred during display name validation otherwise `nil`.
    var validationErrorMessage: String?
    
    /// The string to be displayed in the text field's footer.
    var textFieldFooterMessage: String {
        validationErrorMessage ?? VectorL10n.onboardingDisplayNameHint
    }
}

struct OnboardingDisplayNameBindings {
    /// The display name string entered by the user.
    var displayName: String
    /// The currently displayed alert's info value otherwise `nil`.
    var alertInfo: AlertInfo<Int>?
}

enum OnboardingDisplayNameViewAction {
    /// The display name needs validation.
    case validateDisplayName
    /// The user would like to save the entered display name.
    case save
    /// Move on to the next screen in the flow without setting a display name.
    case skip
}
