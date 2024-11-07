// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit
import SwiftUI

/// Dark theme colors.
public class DarkColors {
    private static let values = ColorValues(
        accent: UIColor(rgb:0x0DBD8B),
        alert: UIColor(rgb:0xFF4B55),
        primaryContent: UIColor(rgb:0xFFFFFF),
        secondaryContent: UIColor(rgb:0xA9B2BC),
        tertiaryContent: UIColor(rgb:0x8E99A4),
        quarterlyContent: UIColor(rgb:0x6F7882),
        quinaryContent: UIColor(rgb:0x394049),
        separator: UIColor(rgb:0x21262C),
        system: UIColor(rgb:0x21262C),
        tile: UIColor(rgb:0x394049),
        navigation: UIColor(rgb:0x21262C),
        background: UIColor(rgb:0x15191E),
        ems: UIColor(rgb: 0x7E69FF),
        links: UIColor(rgb: 0x0086E6),
        namesAndAvatars: [
            UIColor(rgb:0x368BD6),
            UIColor(rgb:0xAC3BA8),
            UIColor(rgb:0x03B381),
            UIColor(rgb:0xE64F7A),
            UIColor(rgb:0xFF812D),
            UIColor(rgb:0x2DC2C5),
            UIColor(rgb:0x5C56F5),
            UIColor(rgb:0x74D12C)
        ]
    )
    
    public static var uiKit = ColorsUIKit(values: values)
    public static var swiftUI = ColorSwiftUI(values: values)
}
