// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension ThemeService {
    
    var themeIdentifier: ThemeIdentifier? {
        guard let themeId = self.themeId else {
            return nil
        }        
        return ThemeIdentifier(rawValue: themeId)
    }
}
