//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
