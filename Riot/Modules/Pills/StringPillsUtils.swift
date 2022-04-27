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

@available (iOS 15.0, *)
@objcMembers
class StringPillsUtils: NSObject {
    // MARK: - Private Constants
    private enum Constants {
        // TODO: replace this with a solution handling any kind of custom permalinks.
        static let matrixToURL: String = "https://matrix.to/#/"
    }

    // MARK: - Internal Methods
    static func insertPills(in attributedString: NSAttributedString,
                            withRoomState roomState: MXRoomState) -> NSAttributedString {
        // TODO: Improve algorithm & cleanup this method
        let newAttr = NSMutableAttributedString(attributedString: attributedString)
        var lastIndex: Int = 0

        while lastIndex < newAttr.length {
            var url: NSURL?
            let linkRange = newAttr.rangeOfLink(at: UInt(lastIndex), url: &url)

            guard let url = url,
                  // FIXME: remove this check if only encrypted message replacer sets non-URL objects in NSLink attributes
                  url.isKind(of: NSURL.self),
                  let absoluteString = url.absoluteString,
                  absoluteString.starts(with: Constants.matrixToURL)
            else {
                lastIndex += 1
                continue
            }
            
            let userId = String(absoluteString.dropFirst(Constants.matrixToURL.count))
            
            if linkRange.length > 0 {
                guard let roomMember = roomState.members.member(withUserId: userId) else {
                    lastIndex += linkRange.length
                    continue
                }
                let attachmentString = PillSnapshoter.mentionPill(withRoomMember: roomMember, andUrl: url as URL)
                newAttr.replaceCharacters(in: linkRange, with: attachmentString)
                lastIndex += attachmentString.length
            } else {
                lastIndex += 1
            }
        }
        
        return newAttr
    }
}
