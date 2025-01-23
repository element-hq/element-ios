// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    
    @objc
    var isTimelinePollEvent: Bool {
        switch eventType {
        case .pollStart, .pollEnd:
            return true
        default:
            return false
        }
    }
}
