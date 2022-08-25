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
import UIKit

/**
 ObjC class for holding fonts for use in UIKit.
 */
@objcMembers public class FontsUIKit: NSObject, Fonts {
    public var largeTitle: UIFont
    
    public var largeTitleB: UIFont
    
    public var title1: UIFont
    
    public var title1B: UIFont
    
    public var title2: UIFont
    
    public var title2B: UIFont
    
    public var title3: UIFont
    
    public var title3SB: UIFont
    
    public var headline: UIFont
    
    public var subheadline: UIFont
    
    public var body: UIFont
    
    public var bodySB: UIFont
    
    public var callout: UIFont
    
    public var calloutSB: UIFont
    
    public var footnote: UIFont
    
    public var footnoteSB: UIFont
    
    public var caption1: UIFont
    
    public var caption1SB: UIFont
    
    public var caption2: UIFont
    
    public var caption2SB: UIFont
    
    public init(values: ElementFonts) {
        largeTitle = values.largeTitle.uiFont
        largeTitleB = values.largeTitleB.uiFont
        title1 = values.title1.uiFont
        title1B = values.title1B.uiFont
        title2 = values.title2.uiFont
        title2B = values.title2B.uiFont
        title3 = values.title3.uiFont
        title3SB = values.title3SB.uiFont
        headline = values.headline.uiFont
        subheadline = values.subheadline.uiFont
        body = values.body.uiFont
        bodySB = values.bodySB.uiFont
        callout = values.callout.uiFont
        calloutSB = values.calloutSB.uiFont
        footnote = values.footnote.uiFont
        footnoteSB = values.footnoteSB.uiFont
        caption1 = values.caption1.uiFont
        caption1SB = values.caption1SB.uiFont
        caption2 = values.caption2.uiFont
        caption2SB = values.caption2SB.uiFont
    }
}
