// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

extension MXBeaconInfoSummaryProtocol {
    
    /// Indicate true if a beacon info summary can be displayed on a map
    var isDisplayable: Bool {
        return self.isActive && self.lastBeacon != nil
    }
}
