// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public class VoiceBroadcastChunk: NSObject {
    public private(set) var voiceBroadcastInfoEventId: String
    public private(set) var sequence: UInt
    public private(set) var attachment: MXKAttachment
    public private(set) var duration: UInt
    
    public init(voiceBroadcastInfoEventId: String,
                sequence: UInt,
                attachment: MXKAttachment,
                duration: UInt) {
        self.voiceBroadcastInfoEventId = voiceBroadcastInfoEventId
        self.sequence = sequence
        self.attachment = attachment
        self.duration = duration
    }
    
    public static func == (lhs: VoiceBroadcastChunk, rhs: VoiceBroadcastChunk) -> Bool {
        return lhs.voiceBroadcastInfoEventId == rhs.voiceBroadcastInfoEventId && lhs.sequence == rhs.sequence
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? VoiceBroadcastChunk else {
            return false
        }
        
        return self.voiceBroadcastInfoEventId == object.voiceBroadcastInfoEventId && self.sequence == object.sequence
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.sequence)
        hasher.combine(self.voiceBroadcastInfoEventId)
        return hasher.finalize()
    }
}
