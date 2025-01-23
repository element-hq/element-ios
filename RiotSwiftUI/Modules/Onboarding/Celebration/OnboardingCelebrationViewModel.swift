//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias OnboardingCelebrationViewModelType = StateStoreViewModel<OnboardingCelebrationViewState, OnboardingCelebrationViewAction>

class OnboardingCelebrationViewModel: OnboardingCelebrationViewModelType, OnboardingCelebrationViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: (() -> Void)?

    // MARK: - Setup

    init() {
        super.init(initialViewState: OnboardingCelebrationViewState())
    }

    // MARK: - Public

    override func process(viewAction: OnboardingCelebrationViewAction) {
        switch viewAction {
        case .complete:
            completion?()
        }
    }
}
