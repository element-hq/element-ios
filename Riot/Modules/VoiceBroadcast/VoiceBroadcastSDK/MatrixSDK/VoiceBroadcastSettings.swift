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
