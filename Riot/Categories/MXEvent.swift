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

extension MXEvent {
    /// Gets the first URL contained in a text message event's body.
    /// - Returns: A URL if detected, otherwise nil.
    @objc func vc_firstURLInBody() -> NSURL? {
        // Only get URLs for un-redacted message events that are text, notice or emote.
        guard isRedactedEvent() == false,
              eventType == .roomMessage,
              let messageType = content["msgtype"] as? String,
              messageType == kMXMessageTypeText || messageType == kMXMessageTypeNotice || messageType == kMXMessageTypeEmote
        else { return nil }
        
        // Make sure not to parse any quoted reply text.
        let body: String?
        if isReply() {
            body = MXReplyEventParser().parse(self).bodyParts.replyText
        } else {
            body = content["body"] as? String
        }
        
        // Find the first url and make sure it's https or http.
        guard let textMessage = body,
              let url = textMessage.vc_firstURLDetected(),
              url.scheme == "https" || url.scheme == "http"
        else { return nil }
        
        return url
    }
}
