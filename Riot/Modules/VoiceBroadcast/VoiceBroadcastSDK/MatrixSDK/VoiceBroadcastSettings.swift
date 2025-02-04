// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Voice Broadcast settings.
@objcMembers
final class VoiceBroadcastSettings: NSObject {
    static let voiceBroadcastInfoContentKeyType = "io.element.voice_broadcast_info"
    
    static let voiceBroadcastContentKeyDeviceId = "device_id"
    static let voiceBroadcastContentKeyState = "state"
    static let voiceBroadcastContentKeyChunkLength = "chunk_length"
    static let voiceBroadcastContentKeyChunkType = "io.element.voice_broadcast_chunk"
    static let voiceBroadcastContentKeyChunkSequence = "sequence"
    static let voiceBroadcastContentKeyChunkLastSequence = "last_chunk_sequence"
}
