// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `HomeserverTileServerConfiguration` defines tile server configuration to be used by the mapping library
@objcMembers
final class HomeserverTileServerConfiguration: NSObject {
    let mapStyleURL: URL
    
    init(mapStyleURL: URL) {
        self.mapStyleURL = mapStyleURL
    }
}
