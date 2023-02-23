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
        namesAndAvatars = values.namesAndAvatars.map({ Color($0) })
    }
}
