//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol OnboardingDisplayNameViewModelProtocol {
    var completion: ((OnboardingDisplayNameViewModelResult) -> Void)? { get set }
    var context: OnboardingDisplayNameViewModelType.Context { get }
    
    /// Update the view model to show that an error has occurred.
    /// - Parameter error: The error to be displayed or `nil` to display a generic alert.
    func processError(_ error: NSError?)
}
