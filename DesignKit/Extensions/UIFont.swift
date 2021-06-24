// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
