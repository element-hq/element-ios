// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixSDK

extension MXSession {
    
    /// Convenient getter to retrieve VoiceBroadcastService associated to the session
    @objc var voiceBroadcastService: VoiceBroadcastService? {
        return VoiceBroadcastServiceProvider.shared.currentVoiceBroadcastService
    }
    
    /// Initialize VoiceBroadcastService
    @objc public func getOrCreateVoiceBroadcastService(for room: MXRoom, completion: @escaping (VoiceBroadcastService?) -> Void) {
        VoiceBroadcastServiceProvider.shared.getOrCreateVoiceBroadcastService(for: room, completion: completion)
    }
    
    @objc public func tearDownVoiceBroadcastService() {
        VoiceBroadcastServiceProvider.shared.tearDownVoiceBroadcastService()
    }
}
