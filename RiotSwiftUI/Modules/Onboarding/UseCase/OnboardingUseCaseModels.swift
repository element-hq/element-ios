//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

// MARK: View model

enum OnboardingUseCaseViewModelResult {
    case personalMessaging
    case workMessaging
    case communityMessaging
    case skipped
}

// MARK: View

struct OnboardingUseCaseViewState: BindableState { }

enum OnboardingUseCaseViewAction {
    case answer(OnboardingUseCaseViewModelResult)
}
