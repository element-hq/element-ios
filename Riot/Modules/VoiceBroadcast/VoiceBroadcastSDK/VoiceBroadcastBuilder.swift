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

struct VoiceBroadcastBuilder {
    
    func build(mediaManager: MXMediaManager,
               voiceBroadcastStartEventId: String,
               voiceBroadcastInvoiceBroadcastStartEventContent: VoiceBroadcastInfo,
               events: [MXEvent],
               currentUserIdentifier: String,
               hasBeenEdited: Bool = false) -> VoiceBroadcast {
        
        var voiceBroadcast = VoiceBroadcast()
        
        let chunks = Set(events.compactMap { event in
            buildChunk(event: event, mediaManager: mediaManager, voiceBroadcastStartEventId: voiceBroadcastStartEventId)
        })
        
        voiceBroadcast.chunks = chunks
        voiceBroadcast.duration = chunks.reduce(0) { $0 + $1.duration}
        
        return voiceBroadcast
    }
    
    func buildChunk(event: MXEvent, mediaManager: MXMediaManager, voiceBroadcastStartEventId: String) -> VoiceBroadcastChunk? {
        guard let attachment = MXKAttachment(event: event, andMediaManager: mediaManager),
              let chunkInfo = event.content[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkType] as? [String: UInt],
              let sequence = chunkInfo[VoiceBroadcastSettings.voiceBroadcastContentKeyChunkSequence],
              let audio = event.content[kMXMessageContentKeyExtensibleAudioMSC1767] as? [String: UInt],
              let duration = audio[kMXMessageContentKeyExtensibleAudioDuration] else {
            return nil
        }
        
        return VoiceBroadcastChunk(voiceBroadcastInfoEventId: voiceBroadcastStartEventId, sequence: sequence, attachment: attachment, duration: duration)
    }
}
