//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

typealias OnboardingUseCaseViewModelType = StateStoreViewModel<OnboardingUseCaseViewState, OnboardingUseCaseViewAction>

class OnboardingUseCaseViewModel: OnboardingUseCaseViewModelType, OnboardingUseCaseViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((OnboardingUseCaseViewModelResult) -> Void)?

    // MARK: - Setup

    init() {
        super.init(initialViewState: OnboardingUseCaseViewState())
    }

    // MARK: - Public

    override func process(viewAction: OnboardingUseCaseViewAction) {
        switch viewAction {
        case .answer(let result):
            completion?(result)
        }
    }
}
