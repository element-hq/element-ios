// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum VoiceBroadcastRecorderViewAction {
    case start
    case stop
    case pause
    case resume
    case pauseOnError
}

enum VoiceBroadcastRecorderState {
    case started
    case stopped
    case paused
    case resumed
    case error
}

struct VoiceBroadcastRecorderDetails {
    let senderDisplayName: String?
    let avatarData: AvatarInputProtocol
}

struct VoiceBroadcastRecordingState {
    var remainingTime: UInt
    var remainingTimeLabel: String
}

struct VoiceBroadcastRecorderViewState: BindableState {
    var details: VoiceBroadcastRecorderDetails
    var recordingState: VoiceBroadcastRecorderState
    var currentRecordingState: VoiceBroadcastRecordingState
    var bindings: VoiceBroadcastRecorderViewStateBindings
}

struct VoiceBroadcastRecorderViewStateBindings {
}
