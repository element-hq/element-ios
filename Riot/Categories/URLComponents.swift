// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension URLComponents {
    
    func vc_getQueryItem(with name: String) -> URLQueryItem? {
        return self.queryItems?.first(where: { $0.name == name })
    }
    
    func vc_getQueryItemValue(for name: String) -> String? {
        return self.vc_getQueryItem(with: name)?.value
    }
}
