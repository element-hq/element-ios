//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

// MARK: View model

enum OnboardingCongratulationsViewModelResult {
    case personalizeProfile
    case takeMeHome
}

// MARK: View

struct OnboardingCongratulationsViewState: BindableState {
    let userId: String
    let personalizationDisabled: Bool
    
    var messageString: NSAttributedString {
        let message = VectorL10n.onboardingCongratulationsMessage(userId)
        
        let attributedMessage = NSMutableAttributedString(string: message)
        let range = (message as NSString).range(of: userId)
        if range.location != NSNotFound {
            attributedMessage.addAttributes([.font: UIFont.preferredFont(forTextStyle: .body).vc_bold], range: range)
        }
        
        return attributedMessage
    }
}

enum OnboardingCongratulationsViewAction {
    case personaliseProfile
    case takeMeHome
}
