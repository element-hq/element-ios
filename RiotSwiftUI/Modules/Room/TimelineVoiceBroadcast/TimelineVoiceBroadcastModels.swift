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

enum TimelineVoiceBroadcastViewAction {
    case play
    case pause
}

enum TimelineVoiceBroadcastViewModelResult {
    // TODO: VB send all chunk file urls from ViewModel
    case played
    case paused
}

enum TimelineVoiceBroadcastType {
    case player
    case recorder
}

struct TimelineVoiceBroadcastDetails {
    var type: TimelineVoiceBroadcastType
    var chunks: [VoiceBroadcastChunk]
    
    init(chunks: [VoiceBroadcastChunk], type: TimelineVoiceBroadcastType) {
        self.type = type
        self.chunks = chunks
    }
}

struct TimelineVoiceBroadcastViewState: BindableState {
    var voiceBroadcast: TimelineVoiceBroadcastDetails
    var bindings: TimelineVoiceBroadcastViewStateBindings
}

struct TimelineVoiceBroadcastViewStateBindings {
    var alertInfo: AlertInfo<TimelineVoiceBroadcastAlertType>?
}

enum TimelineVoiceBroadcastAlertType {
    case failedClosingVoiceBroadcast
}

