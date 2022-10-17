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

typealias TimelineVoiceBroadcastViewModelCallback = () -> Void

// TODO: add play pause cases
enum TimelineVoiceBroadcastViewAction { }

enum TimelineVoiceBroadcastType {
    case disclosed
    case undisclosed
}

struct TimelineVoiceBroadcastDetails {
    var closed: Bool
    var type: TimelineVoiceBroadcastType
    
    init(closed: Bool,
         type: TimelineVoiceBroadcastType) {
        self.closed = closed
        self.type = type
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

