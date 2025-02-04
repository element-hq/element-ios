// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ThemeIdentifier: String, RawRepresentable {
    case light = "default"
    case dark = "dark"
    case black = "black"
    
    init?(rawValue: String) {
        switch rawValue {
        case "default":
            self = .light
        case "dark":
            self = .dark
        case "black":
            self = .black
        default:
            return nil
        }
    }
}
