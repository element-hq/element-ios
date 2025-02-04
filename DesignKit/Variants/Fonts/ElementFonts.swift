// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Fonts at  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0
@objcMembers
public class ElementFonts {
    
    // MARK: - Types
    
    /// A wrapper to provide both a `UIFont` and a SwiftUI `Font` in the same type.
    /// The need for this comes from `Font` not adapting for dynamic type until the app
    /// is restarted (or working at all in Xcode Previews) when initialised from a `UIFont`
    /// (even if that font was created with the appropriate metrics).
    public struct SharedFont {
        public let uiFont: UIFont
        public let font: Font
    }
    
    // MARK: - Setup
    
    public init() {
    }
    
    // MARK: - Private
    
    /// Returns an instance of the font associated with the text style and scaled appropriately for the content size category defined in the trait collection.
    /// Keep this method private method at the moment and create a DesignKit.Fonts.TextStyle if needed.
    fileprivate func font(forTextStyle textStyle: UIFont.TextStyle, compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        return UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: traitCollection)
    }
}

// MARK: - Fonts protocol
extension ElementFonts: Fonts {
    
    public var largeTitle: SharedFont {
        let uiFont = self.font(forTextStyle: .largeTitle)
        return SharedFont(uiFont: uiFont, font: .largeTitle)
    }
    
    public var largeTitleB: SharedFont {
        let uiFont = self.largeTitle.uiFont.vc_bold
        return SharedFont(uiFont: uiFont, font: .largeTitle.bold())
    }
            
    public var title1: SharedFont {
        let uiFont = self.font(forTextStyle: .title1)
        return SharedFont(uiFont: uiFont, font: .title)
    }
    
    public var title1B: SharedFont {
        let uiFont = self.title1.uiFont.vc_bold
        return SharedFont(uiFont: uiFont, font: .title.bold())
    }
    
    public var title2: SharedFont {
        let uiFont = self.font(forTextStyle: .title2)
        return SharedFont(uiFont: uiFont, font: .title2)
    }
    
    public var title2B: SharedFont {
        let uiFont = self.title2.uiFont.vc_bold
        return SharedFont(uiFont: uiFont, font: .title2.bold())
    }
    
    public var title3: SharedFont {
        let uiFont = self.font(forTextStyle: .title3)
        return SharedFont(uiFont: uiFont, font: .title3)
    }
    
    public var title3SB: SharedFont {
        let uiFont = self.title3.uiFont.vc_semiBold
        return SharedFont(uiFont: uiFont, font: .title3.weight(.semibold))
    }
    
    public var headline: SharedFont {
        let uiFont = self.font(forTextStyle: .headline)
        return SharedFont(uiFont: uiFont, font: .headline)
    }
    
    public var subheadline: SharedFont {
        let uiFont = self.font(forTextStyle: .subheadline)
        return SharedFont(uiFont: uiFont, font: .subheadline)
    }
    
    public var body: SharedFont {
        let uiFont = self.font(forTextStyle: .body)
        return SharedFont(uiFont: uiFont, font: .body)
    }
    
    public var bodySB: SharedFont {
        let uiFont = self.body.uiFont.vc_semiBold
        return SharedFont(uiFont: uiFont, font: .body.weight(.semibold))
    }
    
    public var callout: SharedFont {
        let uiFont = self.font(forTextStyle: .callout)
        return SharedFont(uiFont: uiFont, font: .callout)
    }
    
    public var calloutSB: SharedFont {
        let uiFont = self.callout.uiFont.vc_semiBold
        return SharedFont(uiFont: uiFont, font: .callout.weight(.semibold))
    }
    
    public var footnote: SharedFont {
        let uiFont = self.font(forTextStyle: .footnote)
        return SharedFont(uiFont: uiFont, font: .footnote)
    }
    
    public var footnoteSB: SharedFont {
        let uiFont = self.footnote.uiFont.vc_semiBold
        return SharedFont(uiFont: uiFont, font: .footnote.weight(.semibold))
    }
    
    public var caption1: SharedFont {
        let uiFont = self.font(forTextStyle: .caption1)
        return SharedFont(uiFont: uiFont, font: .caption)
    }
    
    public var caption1SB: SharedFont {
        let uiFont = self.caption1.uiFont.vc_semiBold
        return SharedFont(uiFont: uiFont, font: .caption.weight(.semibold))
    }
    
    public var caption2: SharedFont {
        let uiFont = self.font(forTextStyle: .caption2)
        return SharedFont(uiFont: uiFont, font: .caption2)
    }
    
    public var caption2SB: SharedFont {
        let uiFont = self.caption2.uiFont.vc_semiBold
        return SharedFont(uiFont: uiFont, font: .caption2.weight(.semibold))
    }
}
