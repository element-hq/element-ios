// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

public extension UIFont {
    
    // MARK: - Convenient methods
    
    /// Update current font with a SymbolicTraits
    func vc_withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0) // Size 0 means keep the size as it is
    }
    
    /// Update current font with a given Weight
    func vc_withWeight(weight: Weight) -> UIFont {
        // Add the font weight to the descriptor
        let weightedFontDescriptor = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight
            ]
        ])
        return UIFont(descriptor: weightedFontDescriptor, size: 0)
    }
    
    // MARK: - Shortcuts
    
    var vc_bold: UIFont {
        return self.vc_withTraits(.traitBold)
    }
    
    var vc_semiBold: UIFont {
        return self.vc_withWeight(weight: .semibold)
    }

    var vc_italic: UIFont {
        return self.vc_withTraits(.traitItalic)
    }
}
