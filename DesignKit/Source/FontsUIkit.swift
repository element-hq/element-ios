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
        self.largeTitle = values.largeTitle.uiFont
        self.largeTitleB = values.largeTitleB.uiFont
        self.title1 = values.title1.uiFont
        self.title1B = values.title1B.uiFont
        self.title2 = values.title2.uiFont
        self.title2B = values.title2B.uiFont
        self.title3 = values.title3.uiFont
        self.title3SB = values.title3SB.uiFont
        self.headline = values.headline.uiFont
        self.subheadline = values.subheadline.uiFont
        self.body = values.body.uiFont
        self.bodySB = values.bodySB.uiFont
        self.callout = values.callout.uiFont
        self.calloutSB = values.calloutSB.uiFont
        self.footnote = values.footnote.uiFont
        self.footnoteSB = values.footnoteSB.uiFont
        self.caption1 = values.caption1.uiFont
        self.caption1SB = values.caption1SB.uiFont
        self.caption2 = values.caption2.uiFont
        self.caption2SB = values.caption2SB.uiFont
    }
}
