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

import Combine
import SwiftUI

typealias OnboardingDisplayNameViewModelType = StateStoreViewModel<OnboardingDisplayNameViewState, OnboardingDisplayNameViewAction>

class OnboardingDisplayNameViewModel: OnboardingDisplayNameViewModelType, OnboardingDisplayNameViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((OnboardingDisplayNameViewModelResult) -> Void)?

    // MARK: - Setup
    
    init(displayName: String = "") {
        super.init(initialViewState: OnboardingDisplayNameViewState(bindings: OnboardingDisplayNameBindings(displayName: displayName)))
        validateDisplayName()
    }
    
    // MARK: - Public

    override func process(viewAction: OnboardingDisplayNameViewAction) {
        switch viewAction {
        case .validateDisplayName:
            validateDisplayName()
        case .save:
            completion?(.save(state.bindings.displayName))
        case .skip:
            completion?(.skip)
        }
    }
    
    func processError(_ error: NSError?) {
        state.bindings.alertInfo = AlertInfo(error: error)
    }
    
    // MARK: - Private
    
    /// Checks for a display name that exceeds 256 characters and updates the footer error if needed.
    private func validateDisplayName() {
        if state.bindings.displayName.count > 256 {
            guard state.validationErrorMessage == nil else { return }
            state.validationErrorMessage = VectorL10n.onboardingDisplayNameMaxLength
        } else if state.validationErrorMessage != nil {
            state.validationErrorMessage = nil
        }
    }
}
