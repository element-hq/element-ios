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
