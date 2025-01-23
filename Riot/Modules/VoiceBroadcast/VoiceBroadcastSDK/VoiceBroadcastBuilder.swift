// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
