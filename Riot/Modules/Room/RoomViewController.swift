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

import UIKit

extension RoomViewController {
    // MARK: - Override
    open override func mention(_ roomMember: MXRoomMember) {
        guard let inputToolbar = inputToolbar else {
            return
        }

        let newAttributedString = NSMutableAttributedString(attributedString: inputToolbar.attributedTextMessage)

        if inputToolbar.attributedTextMessage.length > 0 {
            if #available(iOS 15.0, *) {
                newAttributedString.append(PillsFormatter.mentionPill(withRoomMember: roomMember,
                                                                      isHighlighted: false,
                                                                      font: inputToolbar.textDefaultFont))
            } else {
                newAttributedString.appendString(roomMember.displayname.count > 0 ? roomMember.displayname : roomMember.userId)
            }
            newAttributedString.appendString(" ")
        } else if roomMember.userId == self.mainSession.myUser.userId {
            newAttributedString.appendString("/me ")
        } else {
            if #available(iOS 15.0, *) {
                newAttributedString.append(PillsFormatter.mentionPill(withRoomMember: roomMember,
                                                                      isHighlighted: false,
                                                                      font: inputToolbar.textDefaultFont))
            } else {
                newAttributedString.appendString(roomMember.displayname.count > 0 ? roomMember.displayname : roomMember.userId)
            }
            newAttributedString.appendString(": ")
        }

        inputToolbar.attributedTextMessage = newAttributedString
        inputToolbar.becomeFirstResponder()
    }


    /// Send given attributed text message to the room
    /// 
    /// - Parameter attributedTextMsg: the attributed text message
    @objc func sendAttributedTextMessage(_ attributedTextMsg: NSAttributedString) {
        let eventModified = self.roomDataSource.event(withEventId: customizedRoomDataSource?.selectedEventId)
        self.setupRoomDataSource { roomDataSource in
            guard let roomDataSource = roomDataSource as? RoomDataSource else { return }

            if self.inputToolbar?.sendMode == .reply, let eventModified = eventModified {
                roomDataSource.sendReply(to: eventModified,
                                         withAttributedTextMessage: attributedTextMsg) { response in
                    switch response {
                    case .success:
                        break
                    case .failure:
                        MXLog.error("[RoomViewController] sendAttributedTextMessage failed while updating event", context: [
                            "event_id": eventModified.eventId
                        ])
                    }
                }
            } else if self.inputToolbar?.sendMode == .edit, let eventModified = eventModified {
                roomDataSource.replaceAttributedTextMessage(
                    for: eventModified,
                    withAttributedTextMessage: attributedTextMsg,
                    success: { _ in
                        //
                    },
                    failure: { _ in
                        MXLog.error("[RoomViewController] sendAttributedTextMessage failed while updating event", context: [
                            "event_id": eventModified.eventId
                        ])
                })
            } else {
                roomDataSource.sendAttributedTextMessage(attributedTextMsg) { response in
                    switch response {
                    case .success:
                        break
                    case .failure:
                        MXLog.error("[RoomViewController] sendAttributedTextMessage failed")
                    }
                }
            }

            if self.customizedRoomDataSource?.selectedEventId != nil {
                self.cancelEventSelection()
            }
        }
    }
}

// MARK: - Private Helpers
private extension RoomViewController {
    var inputToolbar: RoomInputToolbarView? {
        return self.inputToolbarView as? RoomInputToolbarView
    }
}
