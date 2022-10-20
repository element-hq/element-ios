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
import SwiftUI

enum VoiceBroadcastPlaybackViewAction {
    case play
    case playLive
    case pause
}

enum VoiceBroadcastPlaybackState {
    case stopped
    case buffering
    case playing
    case playingLive
    case paused
    case error
}

struct VoiceBroadcastPlaybackDetails {
    let senderDisplayName: String?
}

enum VoiceBroadcastState {
    case unknown
    case stopped
    case live
    case paused
}

struct VoiceBroadcastPlaybackViewState: BindableState {
    var details: VoiceBroadcastPlaybackDetails
    var broadcastState: VoiceBroadcastState
    var playbackState: VoiceBroadcastPlaybackState
    var bindings: VoiceBroadcastPlaybackViewStateBindings
}

struct VoiceBroadcastPlaybackViewStateBindings {
    // TODO: Neeeded?
    var alertInfo: AlertInfo<VoiceBroadcastPlaybackAlertType>?
}

enum VoiceBroadcastPlaybackAlertType {
    // TODO: What is it?
    case failedClosingVoiceBroadcast
}

