// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Structure used to pass modules to routers with pop completion blocks.
struct NavigationModule {
    /// Actual presentable of the module
    let presentable: Presentable
    
    /// Block to be called when the module is popped
    let popCompletion: (() -> Void)?
}

//  MARK: - CustomStringConvertible

extension NavigationModule: CustomStringConvertible {
    
    var description: String {
        return "NavigationModule: \(presentable), pop completion: \(String(describing: popCompletion))"
    }
    
}
