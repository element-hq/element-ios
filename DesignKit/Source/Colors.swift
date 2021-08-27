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
import SwiftUI

public protocol DesignKitColorType { }

extension UIColor: DesignKitColorType { }

extension Color : DesignKitColorType { }

/// Colors at https://www.figma.com/file/X4XTH9iS2KGJ2wFKDqkyed/Compound?node-id=1255%3A1104
public protocol Colors {
    
    /// - Focused/Active states
    /// - CTAs
    var accent: DesignKitColorType { get }
    
    /// - Error messages
    /// - Content requiring user attention
    /// - Notification, alerts
    var alert: DesignKitColorType { get }
    
    /// - Text
    /// - Icons
    var primaryContent: DesignKitColorType { get }
    
    /// - Text
    /// - Icons
    var secondaryContent: DesignKitColorType { get }
    
    /// - Text
    /// - Icons
    var tertiaryContent: DesignKitColorType { get }
    
    /// - Text
    /// - Icons
    var quarterlyContent: DesignKitColorType { get }
    
    /// - Text
    /// - Icons
    var quinaryContent: DesignKitColorType { get }
    
    /// Separating line
    var separator: DesignKitColorType { get }
    
    //  Cards, tiles
    var tile: DesignKitColorType { get }
    
    /// Top navigation background on iOS
    var navigation: DesignKitColorType { get }
    
    /// Background UI color
    var background: DesignKitColorType { get }
    
    /// - Names in chat timeline
    /// - Avatars default states that include first name letter
    var namesAndAvatars: [DesignKitColorType] { get }
    
}
