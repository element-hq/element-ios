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
