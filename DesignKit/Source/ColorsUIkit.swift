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
        namesAndAvatars = values.namesAndAvatars
    }
}

