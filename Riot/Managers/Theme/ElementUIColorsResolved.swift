// 
// Copyright 2022 New Vector Ltd
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
import DesignTokens

extension UIColor {
    /// The colors from DesignKit, resolved for light mode only.
    static let elementLight = ElementUIColorsResolved(dynamicColors: element, userInterfaceStyle: .light)
    /// The colors from DesignKit, resolved for dark mode only.
    static let elementDark = ElementUIColorsResolved(dynamicColors: element, userInterfaceStyle: .dark)
}

/// The dynamic colors from DesignKit, resolved to light or dark mode for use in the UIKit themes.
///
/// As Element doesn't (currently) update the app's `UIUserInterfaceStyle` when selecting
/// a custom theme, the dynamic colors provided by DesignKit need resolving for each theme to
/// prevent them from respecting the interface style and rendering in the wrong style.
@objcMembers public class ElementUIColorsResolved: NSObject {
    // MARK: Compound
    public let accent: UIColor
    public let alert: UIColor
    public let primaryContent: UIColor
    public let secondaryContent: UIColor
    public let tertiaryContent: UIColor
    public let quaternaryContent: UIColor
    public let quinaryContent: UIColor
    public let system: UIColor
    public let background: UIColor
    
    public let namesAndAvatars: [UIColor]
    
    // MARK: Legacy
    public let quarterlyContent: UIColor
    public let navigation: UIColor
    public let tile: UIColor
    public let separator: UIColor
    
    // MARK: Setup
    public init(dynamicColors: ElementUIColors, userInterfaceStyle: UIUserInterfaceStyle) {
        let traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        
        self.accent = dynamicColors.accent.resolvedColor(with: traitCollection)
        self.alert = dynamicColors.alert.resolvedColor(with: traitCollection)
        self.primaryContent = dynamicColors.primaryContent.resolvedColor(with: traitCollection)
        self.secondaryContent = dynamicColors.secondaryContent.resolvedColor(with: traitCollection)
        self.tertiaryContent = dynamicColors.tertiaryContent.resolvedColor(with: traitCollection)
        self.quaternaryContent = dynamicColors.quaternaryContent.resolvedColor(with: traitCollection)
        self.quinaryContent = dynamicColors.quinaryContent.resolvedColor(with: traitCollection)
        self.system = dynamicColors.system.resolvedColor(with: traitCollection)
        self.background = dynamicColors.background.resolvedColor(with: traitCollection)
        
        self.namesAndAvatars = dynamicColors.contentAndAvatars
        
        // Legacy colours
        self.quarterlyContent = dynamicColors.quaternaryContent.resolvedColor(with: traitCollection)
        self.navigation = dynamicColors.system.resolvedColor(with: traitCollection)
        
        if userInterfaceStyle == .light {
            self.tile = UIColor(rgb: 0xF3F8FD)
            self.separator = dynamicColors.quinaryContent.resolvedColor(with: traitCollection)
        } else {
            self.tile = dynamicColors.quinaryContent.resolvedColor(with: traitCollection)
            self.separator = dynamicColors.system.resolvedColor(with: traitCollection)
        }
        
        super.init()
    }
}
