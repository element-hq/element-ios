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
