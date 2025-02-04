// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
