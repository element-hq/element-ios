// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol VoiceBroadcastRecorderServiceDelegate: AnyObject {
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateState state: VoiceBroadcastRecorderState)
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateRemainingTime remainingTime: UInt)
}

protocol VoiceBroadcastRecorderServiceProtocol {
    /// Service delegate
    var serviceDelegate: VoiceBroadcastRecorderServiceDelegate? { get set }
    
    /// Returns if a voice broadcast is currently recording.
    var isRecording: Bool { get }

    /// Start voice broadcast recording.
    func startRecordingVoiceBroadcast()

    /// Stop voice broadcast recording.
    func stopRecordingVoiceBroadcast()

    /// Pause voice broadcast recording.
    func pauseRecordingVoiceBroadcast()

    /// Resume voice broadcast recording after paused it.
    func resumeRecordingVoiceBroadcast()
    
    /// Cancel voice broadcast recording after redacted it.
    func cancelRecordingVoiceBroadcast()
    
    /// Pause voice broadcast recording without sending pending events.
    func pauseOnErrorRecordingVoiceBroadcast()
}
