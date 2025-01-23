// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/**
 Struct for holding fonts for use in SwiftUI.
 */
public struct FontSwiftUI: Fonts {
    
    public let uiFonts: FontsUIKit
    
    public var largeTitle: Font
    
    public var largeTitleB: Font
    
    public var title1: Font
    
    public var title1B: Font
    
    public var title2: Font
    
    public var title2B: Font
    
    public var title3: Font
    
    public var title3SB: Font
    
    public var headline: Font
    
    public var subheadline: Font
    
    public var body: Font
    
    public var bodySB: Font
    
    public var callout: Font
    
    public var calloutSB: Font
    
    public var footnote: Font
    
    public var footnoteSB: Font
    
    public var caption1: Font
    
    public var caption1SB: Font
    
    public var caption2: Font
    
    public var caption2SB: Font
    
    public init(values: ElementFonts) {
        self.uiFonts = FontsUIKit(values: values)
        
        self.largeTitle = values.largeTitle.font
        self.largeTitleB = values.largeTitleB.font
        self.title1 = values.title1.font
        self.title1B = values.title1B.font
        self.title2 = values.title2.font
        self.title2B = values.title2B.font
        self.title3 = values.title3.font
        self.title3SB = values.title3SB.font
        self.headline = values.headline.font
        self.subheadline = values.subheadline.font
        self.body = values.body.font
        self.bodySB = values.bodySB.font
        self.callout = values.callout.font
        self.calloutSB = values.calloutSB.font
        self.footnote = values.footnote.font
        self.footnoteSB = values.footnoteSB.font
        self.caption1 = values.caption1.font
        self.caption1SB = values.caption1SB.font
        self.caption2 = values.caption2.font
        self.caption2SB = values.caption2SB.font
    }
}
