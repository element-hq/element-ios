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

/// Provides utilities funcs to handle Pills inside attributed strings.
@available (iOS 15.0, *)
@objcMembers
class StringPillsUtils: NSObject {
    // MARK: - Private Constants
    private enum Constants {
        // TODO: replace this with a solution handling any kind of custom permalinks.
        static let matrixToURL: String = "https://matrix.to/#/"
    }

    // MARK: - Internal Methods
    /// Insert text attachments for pills inside given message attributed string.
    ///
    /// - Parameters:
    ///   - attributedString: message string to update
    ///   - session: current session
    ///   - roomState: room state for message
    /// - Returns: new attributed string with pills
    static func insertPills(in attributedString: NSAttributedString,
                            withSession session: MXSession,
                            andRoomState roomState: MXRoomState) -> NSAttributedString {
        let newAttr = NSMutableAttributedString(attributedString: attributedString)
        let totalRange = NSRange(location: 0, length: newAttr.length)

        newAttr.vc_enumerateAttribute(.link, in: totalRange) { (url: URL, range: NSRange, _) in
            if url.absoluteString.starts(with: Constants.matrixToURL) {
                let userId = String(url.absoluteString.dropFirst(Constants.matrixToURL.count))
                if let roomMember = roomState.members.member(withUserId: userId) {
                    let isCurrentUser = roomMember.userId == session.myUserId
                    let attachmentString = mentionPill(withRoomMember: roomMember,
                                                       andUrl: url,
                                                       isCurrentUser: isCurrentUser)
                    newAttr.replaceCharacters(in: range, with: attachmentString)
                }
            }
        }

        return newAttr
    }

    /// Creates an attributed string containing a pill for given room member.
    ///
    /// - Parameters:
    ///   - roomMember: the room member
    ///   - url: url to room member profile
    ///   - isCurrentUser: true to indicate that the room member is the current user
    /// - Returns: attributed string with a pill attachment and a link
    static func mentionPill(withRoomMember roomMember: MXRoomMember,
                            andUrl url: URL,
                            isCurrentUser: Bool) -> NSAttributedString {
        let attachment = PillTextAttachment(withRoomMember: roomMember, isCurrentUser: isCurrentUser)
        let string = NSMutableAttributedString(attachment: attachment)
        string.addAttribute(.link, value: url, range: .init(location: 0, length: string.length))
        return string
    }
}
