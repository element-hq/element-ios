// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/**
 Struct for holding colors for use in SwiftUI.
 */
public struct ColorSwiftUI: Colors {
    
    public let accent: Color
    
    public let alert: Color
    
    public let primaryContent: Color
    
    public let secondaryContent: Color
    
    public let tertiaryContent: Color
    
    public let quarterlyContent: Color
    
    public let quinaryContent: Color
    
    public let separator: Color
    
    public var system: Color
    
    public let tile: Color
    
    public let navigation: Color
    
    public let background: Color
    
    public var ems: Color
    
    public let links: Color
    
    public let namesAndAvatars: [Color]
        
    init(values: ColorValues) {
        accent = Color(values.accent)
        alert = Color(values.alert)
        primaryContent = Color(values.primaryContent)
        secondaryContent = Color(values.secondaryContent)
        tertiaryContent = Color(values.tertiaryContent)
        quarterlyContent = Color(values.quarterlyContent)
        quinaryContent = Color(values.quinaryContent)
        separator = Color(values.separator)
        system = Color(values.system)
        tile = Color(values.tile)
        navigation = Color(values.navigation)
        background = Color(values.background)
        ems = Color(values.ems)
        links = Color(values.links)
        namesAndAvatars = values.namesAndAvatars.map({ Color($0) })
    }
}
