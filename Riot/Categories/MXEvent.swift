// 
// Copyright 2021 New Vector Ltd
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
import MatrixSDK

extension MXEvent {
    
    /// Get MXMessageType if any
    var messageType: MXMessageType? {
        guard let messageTypeString = self.content["msgtype"] as? String else {
            return nil
        }
        return MXMessageType(identifier: messageTypeString)
    }

    /// Lightweight version of the receiver, in which reply-specific keys are stripped. Returns the same event with the receiver if not a reply event.
    /// Should be used only to update formatting behavior.
    var replyStrippedVersion: MXEvent {
        if self.isReply(), let newMessage = self.copy() as? MXEvent {
            var jsonDict = newMessage.isEncrypted ? newMessage.clear?.jsonDictionary() : newMessage.jsonDictionary()
            if var content = jsonDict?["content"] as? [String: Any] {
                content.removeValue(forKey: "format")
                content.removeValue(forKey: "formatted_body")
                content.removeValue(forKey: kMXEventRelationRelatesToKey)
                if let replyText = MXReplyEventParser().parse(newMessage)?.bodyParts.replyText {
                    content["body"] = replyText
                }
                jsonDict?["content"] = content
            }
            return MXEvent(fromJSON: jsonDict)
        } else {
            return self
        }
    }
}
