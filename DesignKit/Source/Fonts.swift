// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Describe fonts used in the application.
/// Font names are based on Element typograhy  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0 which is based on Apple font text styles (UIFont.TextStyle): https://developer.apple.com/documentation/uikit/uifonttextstyle
/// Create a custom TextStyle enum (like DesignKit.Fonts.TextStyle) is also a possiblity
public protocol Fonts {
    
    associatedtype FontType
    
    /// The font for large titles.
    var largeTitle: FontType { get }
    
    /// `largeTitle` with a Bold weight.
    var largeTitleB: FontType { get }
    
    /// The font for first-level hierarchical headings.
    var title1: FontType { get }
        
    /// `title1` with a Bold weight.
    var title1B: FontType { get }
    
    /// The font for second-level hierarchical headings.
    var title2: FontType { get }
    
    /// `title2` with a Bold weight.
    var title2B: FontType { get }
    
    /// The font for third-level hierarchical headings.
    var title3: FontType { get }
    
    /// `title3` with a Semi Bold weight.
    var title3SB: FontType { get }
    
    /// The font for headings.
    var headline: FontType { get }
    
    /// The font for subheadings.
    var subheadline: FontType { get }
    
    /// The font for body text.
    var body: FontType { get }
    
    /// `body` with a Semi Bold weight.
    var bodySB: FontType { get }
    
    /// The font for callouts.
    var callout: FontType { get }
    
    /// `callout` with a Semi Bold weight.
    var calloutSB: FontType { get }
    
    /// The font for footnotes.
    var footnote: FontType { get }
    
    /// `footnote` with a Semi Bold weight.
    var footnoteSB: FontType { get }
    
    /// The font for standard captions.
    var caption1: FontType { get }

    /// `caption1` with a Semi Bold weight.
    var caption1SB: FontType { get }
    
    /// The font for alternate captions.
    var caption2: FontType { get }
    
    /// `caption2` with a Semi Bold weight.
    var caption2SB: FontType { get }
}
