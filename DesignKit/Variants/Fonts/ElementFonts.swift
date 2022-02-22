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
        /// The underlying font for the `font` property. This is stored
        /// as an optional `Any` due to unavailability on iOS 12.
        private let _font: Any?
        
        @available(iOS 13.0, *)
        public var font: Font {
            _font as! Font
        }
        
        @available(iOS, deprecated: 13.0, message: "Use init(uiFont:font:) instead and remove this initialiser.")
        init(uiFont: UIFont) {
            self.uiFont = uiFont
            self._font = nil
        }
        
        @available(iOS 13.0, *)
        init(uiFont: UIFont, font: Font) {
            self.uiFont = uiFont
            self._font = font
        }
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
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .largeTitle)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var largeTitleB: SharedFont {
        let uiFont = self.largeTitle.uiFont.vc_bold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .largeTitle.bold())
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
            
    public var title1: SharedFont {
        let uiFont = self.font(forTextStyle: .title1)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .title)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var title1B: SharedFont {
        let uiFont = self.title1.uiFont.vc_bold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .title.bold())
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var title2: SharedFont {
        let uiFont = self.font(forTextStyle: .title2)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: Font(uiFont))
        } else if #available(iOS 14.0, *) {
            return SharedFont(uiFont: uiFont, font: .title2)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var title2B: SharedFont {
        let uiFont = self.title2.uiFont.vc_bold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: Font(uiFont))
        } else if #available(iOS 14.0, *) {
            return SharedFont(uiFont: uiFont, font: .title2.bold())
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var title3: SharedFont {
        let uiFont = self.font(forTextStyle: .title3)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: Font(uiFont))
        } else if #available(iOS 14.0, *) {
            return SharedFont(uiFont: uiFont, font: .title3)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var title3SB: SharedFont {
        let uiFont = self.title3.uiFont.vc_semiBold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: Font(uiFont))
        } else if #available(iOS 14.0, *) {
            return SharedFont(uiFont: uiFont, font: .title3.weight(.semibold))
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var headline: SharedFont {
        let uiFont = self.font(forTextStyle: .headline)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .headline)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var subheadline: SharedFont {
        let uiFont = self.font(forTextStyle: .subheadline)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .subheadline)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var body: SharedFont {
        let uiFont = self.font(forTextStyle: .body)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .body)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var bodySB: SharedFont {
        let uiFont = self.body.uiFont.vc_semiBold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .body.weight(.semibold))
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var callout: SharedFont {
        let uiFont = self.font(forTextStyle: .callout)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .callout)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var calloutSB: SharedFont {
        let uiFont = self.callout.uiFont.vc_semiBold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .callout.weight(.semibold))
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var footnote: SharedFont {
        let uiFont = self.font(forTextStyle: .footnote)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .footnote)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var footnoteSB: SharedFont {
        let uiFont = self.footnote.uiFont.vc_semiBold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .footnote.weight(.semibold))
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var caption1: SharedFont {
        let uiFont = self.font(forTextStyle: .caption1)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .caption)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var caption1SB: SharedFont {
        let uiFont = self.caption1.uiFont.vc_semiBold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: .caption.weight(.semibold))
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var caption2: SharedFont {
        let uiFont = self.font(forTextStyle: .caption2)
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: Font(uiFont))
        } else if #available(iOS 14.0, *) {
            return SharedFont(uiFont: uiFont, font: .caption2)
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
    
    public var caption2SB: SharedFont {
        let uiFont = self.caption2.uiFont.vc_semiBold
        
        if #available(iOS 13.0, *) {
            return SharedFont(uiFont: uiFont, font: Font(uiFont))
        } else if #available(iOS 14.0, *) {
            return SharedFont(uiFont: uiFont, font: .caption2.weight(.semibold))
        } else {
            return SharedFont(uiFont: uiFont)
        }
    }
}
