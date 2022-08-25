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
        uiFonts = FontsUIKit(values: values)
        
        largeTitle = values.largeTitle.font
        largeTitleB = values.largeTitleB.font
        title1 = values.title1.font
        title1B = values.title1B.font
        title2 = values.title2.font
        title2B = values.title2B.font
        title3 = values.title3.font
        title3SB = values.title3SB.font
        headline = values.headline.font
        subheadline = values.subheadline.font
        body = values.body.font
        bodySB = values.bodySB.font
        callout = values.callout.font
        calloutSB = values.calloutSB.font
        footnote = values.footnote.font
        footnoteSB = values.footnoteSB.font
        caption1 = values.caption1.font
        caption1SB = values.caption1SB.font
        caption2 = values.caption2.font
        caption2SB = values.caption2SB.font
    }
}
