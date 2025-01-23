// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension VoiceBroadcastInfo {
    // MARK: - Constants
    
    // MARK: - Public
    
    @objc static func isStarted(for name: String) -> Bool {
        return name == VoiceBroadcastInfoState.started.rawValue
    }
    
    @objc static func isStopped(for name: String) -> Bool {
        return name == VoiceBroadcastInfoState.stopped.rawValue
    }
    
    @objc static func startedValue() -> String {
        return VoiceBroadcastInfoState.started.rawValue
    }
    
    @objc static func pausedValue() -> String {
        return VoiceBroadcastInfoState.paused.rawValue
    }
    
    @objc static func resumedValue() -> String {
        return VoiceBroadcastInfoState.resumed.rawValue
    }
    
    @objc static func stoppedValue() -> String {
        return VoiceBroadcastInfoState.stopped.rawValue
    }
}
