// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents the homeserver configuration (usually based on HS Well-Known or hardcoded values in the project)
@objcMembers
final class HomeserverConfiguration: NSObject {
    
    // Note: Use an object per configuration subject when there is multiple properties related
    let jitsi: HomeserverJitsiConfiguration
    let encryption: HomeserverEncryptionConfiguration
    let tileServer: HomeserverTileServerConfiguration
    
    init(jitsi: HomeserverJitsiConfiguration,
         encryption: HomeserverEncryptionConfiguration,
         tileServer: HomeserverTileServerConfiguration) {
        self.jitsi = jitsi
        self.encryption = encryption
        self.tileServer = tileServer
    }
}
