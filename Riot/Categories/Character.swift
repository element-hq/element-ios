/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension Character {
    var vc_unicodeScalarCodePoint: UInt32 {
        return self.unicodeScalars[self.unicodeScalars.startIndex].value
    }
}
