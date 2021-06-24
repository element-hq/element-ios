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

/// Describe fonts used in the application.
/// Font names are based on Element typograhy  https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1362%3A0 which is based on Apple font text styles (UIFont.TextStyle): https://developer.apple.com/documentation/uikit/uifonttextstyle
/// Create a custom TextStyle enum (like DesignKit.Fonts.TextStyle) is also a possiblity
@objc public protocol Fonts {
    
    /// The font for large titles.
    var largeTitle: UIFont { get }
    
    /// `largeTitle` with a Bold weight.
    var largeTitleB: UIFont { get }
    
    /// The font for first-level hierarchical headings.
    var title1: UIFont { get }
        
    /// `title1` with a Bold weight.
    var title1B: UIFont { get }
    
    /// The font for second-level hierarchical headings.
    var title2: UIFont { get }
    
    /// `title2` with a Bold weight.
    var title2B: UIFont { get }
    
    /// The font for third-level hierarchical headings.
    var title3: UIFont { get }
    
    /// `title3` with a Semi Bold weight.
    var title3SB: UIFont { get }
    
    /// The font for headings.
    var headline: UIFont { get }
    
    /// The font for subheadings.
    var subheadline: UIFont { get }
    
    /// The font for body text.
    var body: UIFont { get }
    
    /// `body` with a Semi Bold weight.
    var bodySB: UIFont { get }
    
    /// The font for callouts.
    var callout: UIFont { get }
    
    /// `callout` with a Semi Bold weight.
    var calloutSB: UIFont { get }
    
    /// The font for footnotes.
    var footnote: UIFont { get }
    
    /// `footnote` with a Semi Bold weight.
    var footnoteSB: UIFont { get }
    
    /// The font for standard captions.
    var caption1: UIFont { get }

    /// `caption1` with a Semi Bold weight.
    var caption1SB: UIFont { get }
    
    /// The font for alternate captions.
    var caption2: UIFont { get }
    
    /// `caption2` with a Semi Bold weight.
    var caption2SB: UIFont { get }
}
