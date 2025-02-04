//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias OnboardingCongratulationsViewModelType = StateStoreViewModel<OnboardingCongratulationsViewState, OnboardingCongratulationsViewAction>

class OnboardingCongratulationsViewModel: OnboardingCongratulationsViewModelType, OnboardingCongratulationsViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((OnboardingCongratulationsViewModelResult) -> Void)?

    // MARK: - Setup

    init(userId: String, personalizationDisabled: Bool = false) {
        super.init(initialViewState: OnboardingCongratulationsViewState(userId: userId,
                                                                        personalizationDisabled: personalizationDisabled))
    }

    // MARK: - Public

    override func process(viewAction: OnboardingCongratulationsViewAction) {
        switch viewAction {
        case .personaliseProfile:
            completion?(.personalizeProfile)
        case .takeMeHome:
            completion?(.takeMeHome)
        }
    }
}
