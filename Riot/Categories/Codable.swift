// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension Encodable {
    /// Convenience method to get the json string of an Encodable
    var jsonString: String? {
        let encoder = JSONEncoder()
        guard let jsonData =  try? encoder.encode(self) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
}
