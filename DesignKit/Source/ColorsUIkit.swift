// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

/**
 ObjC class for holding colors for use in UIKit.
 */
@objcMembers public class ColorsUIKit: NSObject {
    
    public let accent: UIColor

    public let alert: UIColor

    public let primaryContent: UIColor

    public let secondaryContent: UIColor

    public let tertiaryContent: UIColor

    public let quarterlyContent: UIColor

    public let quinaryContent: UIColor

    public let separator: UIColor
    
    public let system: UIColor

    public let tile: UIColor

    public let navigation: UIColor

    public let background: UIColor
    
    public let links: UIColor

    public let namesAndAvatars: [UIColor]
    
    init(values: ColorValues) {
        accent = values.accent
        alert = values.alert
        primaryContent = values.primaryContent
        secondaryContent = values.secondaryContent
        tertiaryContent = values.tertiaryContent
        quarterlyContent = values.quarterlyContent
        quinaryContent = values.quinaryContent
        separator = values.separator
        system = values.system
        tile = values.tile
        navigation = values.navigation
        background = values.background
        links = values.links
        namesAndAvatars = values.namesAndAvatars
    }
}

