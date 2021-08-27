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
import SwiftUI

public protocol DesignKitFontType { }

extension UIFont: DesignKitFontType { }

extension Font : DesignKitFontType { }


/// Describe fonts used in the application.
/// Font names are based on Element typograhy  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0 which is based on Apple font text styles (UIFont.TextStyle): https://developer.apple.com/documentation/uikit/uifonttextstyle
/// Create a custom TextStyle enum (like DesignKit.Fonts.TextStyle) is also a possiblity
public protocol Fonts {
    
    /// The font for large titles.
    var largeTitle: DesignKitFontType { get }
    
    /// `largeTitle` with a Bold weight.
    var largeTitleB: DesignKitFontType { get }
    
    /// The font for first-level hierarchical headings.
    var title1: DesignKitFontType { get }
        
    /// `title1` with a Bold weight.
    var title1B: DesignKitFontType { get }
    
    /// The font for second-level hierarchical headings.
    var title2: DesignKitFontType { get }
    
    /// `title2` with a Bold weight.
    var title2B: DesignKitFontType { get }
    
    /// The font for third-level hierarchical headings.
    var title3: DesignKitFontType { get }
    
    /// `title3` with a Semi Bold weight.
    var title3SB: DesignKitFontType { get }
    
    /// The font for headings.
    var headline: DesignKitFontType { get }
    
    /// The font for subheadings.
    var subheadline: DesignKitFontType { get }
    
    /// The font for body text.
    var body: DesignKitFontType { get }
    
    /// `body` with a Semi Bold weight.
    var bodySB: DesignKitFontType { get }
    
    /// The font for callouts.
    var callout: DesignKitFontType { get }
    
    /// `callout` with a Semi Bold weight.
    var calloutSB: DesignKitFontType { get }
    
    /// The font for footnotes.
    var footnote: DesignKitFontType { get }
    
    /// `footnote` with a Semi Bold weight.
    var footnoteSB: DesignKitFontType { get }
    
    /// The font for standard captions.
    var caption1: DesignKitFontType { get }

    /// `caption1` with a Semi Bold weight.
    var caption1SB: DesignKitFontType { get }
    
    /// The font for alternate captions.
    var caption2: DesignKitFontType { get }
    
    /// `caption2` with a Semi Bold weight.
    var caption2SB: DesignKitFontType { get }
}
