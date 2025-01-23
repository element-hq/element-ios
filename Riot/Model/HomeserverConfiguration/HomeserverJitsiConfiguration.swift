// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `HomeserverJitsiConfiguration` gives Jitsi widget configuration used by homeserver
@objcMembers
final class HomeserverJitsiConfiguration: NSObject {
    let serverDomain: String?
    let serverURL: URL?
    let useFor1To1Calls: Bool
    
    init(serverDomain: String?, serverURL: URL?, useFor1To1Calls: Bool?) {
        self.serverDomain = serverDomain
        self.serverURL = serverURL
        self.useFor1To1Calls = useFor1To1Calls ?? false
        
        super.init()
    }
}
