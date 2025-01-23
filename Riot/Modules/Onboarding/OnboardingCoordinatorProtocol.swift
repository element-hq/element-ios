// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `OnboardingCoordinatorProtocol` is a protocol describing a Coordinator that handle's the
/// full onboarding flow with pre-auth screens, authentication and setup screens once signed in.
protocol OnboardingCoordinatorProtocol: Coordinator, Presentable {
    var completion: (() -> Void)? { get set }
}
