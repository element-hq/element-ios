// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

enum VoiceBroadcastPlaybackViewAction {
    case play
    case pause
    case sliderChange(didChange: Bool)
    case backward
    case forward
    case redact
}

enum VoiceBroadcastPlaybackState {
    case stopped
    case buffering
    case playing
    case paused
    case error
}

struct VoiceBroadcastPlaybackDetails {
    let senderDisplayName: String?
    let avatarData: AvatarInputProtocol
}

struct VoiceBroadcastPlayingState {
    var duration: Float
    var elapsedTimeLabel: String?
    var remainingTimeLabel: String?
    var isLive: Bool
    var canMoveForward: Bool
    var canMoveBackward: Bool
}

struct VoiceBroadcastPlaybackDecryptionState {
    var errorCount: Int
}

struct VoiceBroadcastPlaybackViewState: BindableState {
    var details: VoiceBroadcastPlaybackDetails
    var broadcastState: VoiceBroadcastInfoState
    var playbackState: VoiceBroadcastPlaybackState
    var playingState: VoiceBroadcastPlayingState
    var bindings: VoiceBroadcastPlaybackViewStateBindings
    var decryptionState: VoiceBroadcastPlaybackDecryptionState
    var showPlaybackError: Bool
}

struct VoiceBroadcastPlaybackViewStateBindings {
    var progress: Float
}

