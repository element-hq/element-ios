// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftBase32

final class Base32Coder {
    
    static func encodedString(_ string: String, padding: Bool = true) -> String {
        let encodedString = string.base32EncodedString
        return padding ? encodedString : encodedString.replacingOccurrences(of: "=", with: "")
    }
}
