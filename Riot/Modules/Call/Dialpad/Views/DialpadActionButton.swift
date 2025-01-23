// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Dialpad action button type
@objc enum DialpadActionButtonType: Int {
    case backspace
    case call
}

/// Action button class for Dialpad screen
class DialpadActionButton: DialpadButton {

    var type: DialpadActionButtonType = .backspace
    
    override func update(theme: Theme) {
        switch type {
        case .backspace:
            backgroundColor = .clear
            tintColor = theme.colors.tertiaryContent
        case .call:
            backgroundColor = theme.colors.accent
            tintColor = .white
        }
    }

}
