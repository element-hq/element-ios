// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

protocol VoiceBroadcastRecorderServiceDelegate: AnyObject {
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateState state: VoiceBroadcastRecorderState)
    func voiceBroadcastRecorderService(_ service: VoiceBroadcastRecorderServiceProtocol, didUpdateRemainingTime remainingTime: UInt)
}

protocol VoiceBroadcastRecorderServiceProtocol {
    /// Service delegate
    var serviceDelegate: VoiceBroadcastRecorderServiceDelegate? { get set }
    
    /// Start voice broadcast recording.
    func startRecordingVoiceBroadcast()

    /// Stop voice broadcast recording.
    func stopRecordingVoiceBroadcast()

    /// Pause voice broadcast recording.
    func pauseRecordingVoiceBroadcast()

    /// Resume voice broadcast recording after paused it.
    func resumeRecordingVoiceBroadcast()
}
