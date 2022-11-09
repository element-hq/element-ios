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


    /// Send the formatted text message and its raw counterpat to the room
    ///
    /// - Parameter rawTextMsg: the raw text message
    /// - Parameter htmlMsg: the html text message
    @objc func sendFormattedTextMessage(_ rawTextMsg: String, htmlMsg: String) {
        let eventModified = self.roomDataSource.event(withEventId: customizedRoomDataSource?.selectedEventId)
        self.setupRoomDataSource { roomDataSource in
            guard let roomDataSource = roomDataSource as? RoomDataSource else { return }
            if self.wysiwygInputToolbar?.sendMode == .reply, let eventModified = eventModified {
                roomDataSource.sendReply(to: eventModified, rawText: rawTextMsg, htmlText: htmlMsg) { response in
                    switch response {
                    case .success:
                        break
                    case .failure:
                        MXLog.error("[RoomViewController] sendFormattedTextMessage failed while updating event", context: [
                            "event_id": eventModified.eventId
                        ])
                    }
                }
            } else if self.wysiwygInputToolbar?.sendMode == .edit, let eventModified = eventModified {
                roomDataSource.replaceFormattedTextMessage(
                    for: eventModified,
                    rawText: rawTextMsg,
                    html: htmlMsg,
                    success: { _ in
                        //
                    },
                    failure: { _ in
                        MXLog.error("[RoomViewController] sendFormattedTextMessage failed while updating event", context: [
                            "event_id": eventModified.eventId
                        ])
                })
            } else {
                roomDataSource.sendFormattedTextMessage(rawTextMsg, html: htmlMsg) { response in
                    switch response {
                    case .success:
                        break
                    case .failure:
                        MXLog.error("[RoomViewController] sendFormattedTextMessage failed")
                    }
                }
            }

            if self.customizedRoomDataSource?.selectedEventId != nil {
                self.cancelEventSelection()
            }
        }
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

    @objc func togglePlainTextMode() {
        RiotSettings.shared.enableWysiwygTextFormatting.toggle()
        wysiwygInputToolbar?.textFormattingEnabled.toggle()
    }
    
    @objc func didChangeMaximisedState(_ state: Bool) {
        if state {
            var view: UIView!
            // iPhone
            if let navView = self.navigationController?.navigationController?.view {
                view = navView
            // iPad
            } else if let navView = self.navigationController?.view {
                view = navView
            } else {
                return
            }
            let originalRect = roomInputToolbarContainer.convert(roomInputToolbarContainer.frame, to: view)
            self.roomInputToolbarContainer.removeFromSuperview()
            let dimmingView = UIView(frame: view.bounds)
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            view.addSubview(dimmingView)
            dimmingView.addSubview(self.roomInputToolbarContainer)
            roomInputToolbarContainer.frame = originalRect
            self.roomInputToolbarContainer.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
            self.roomInputToolbarContainer.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
            self.roomInputToolbarContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                view.layoutIfNeeded()
            }
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanRoomToolbarContainer(_ :)))
            roomInputToolbarContainer.addGestureRecognizer(panGesture)
        } else {
            let superView = self.roomInputToolbarContainer.superview
            self.roomInputToolbarContainer.removeFromSuperview()
            superView?.removeFromSuperview()
            self.view.insertSubview(self.roomInputToolbarContainer, belowSubview: self.overlayContainerView)
            NSLayoutConstraint.activate(self.toolbarContainerConstraints)
            self.roomInputToolbarContainerBottomConstraint.isActive = true
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.view.layoutIfNeeded()
            }
            roomInputToolbarContainer.gestureRecognizers?.removeAll()
        }
    }
    
    @objc func setMaximisedToolbarIsHiddenIfNeeded(_ isHidden: Bool) {
        if wysiwygInputToolbar?.isMaximised == true {
            roomInputToolbarContainer.superview?.isHidden = isHidden
        }
    }
}

// MARK: - Private Helpers
private extension RoomViewController {
    var inputToolbar: RoomInputToolbarView? {
        return self.inputToolbarView as? RoomInputToolbarView
    }
    
    var wysiwygInputToolbar: WysiwygInputToolbarView? {
        return self.inputToolbarView as? WysiwygInputToolbarView
    }
    
    @objc private func didPanRoomToolbarContainer(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            originalMaximisedToolbarCenter = roomInputToolbarContainer.center
        case .changed:
            let translation = sender.translation(in: view)
            guard originalMaximisedToolbarCenter.y + translation.y > originalMaximisedToolbarCenter.y else { return }
            roomInputToolbarContainer.center = CGPoint(x: originalMaximisedToolbarCenter.x,
                                          y: originalMaximisedToolbarCenter.y + translation.y)
        case .ended, .cancelled:
            if roomInputToolbarContainer.center.y > originalMaximisedToolbarCenter.y + roomInputToolbarContainer.frame.height / 4 {
                wysiwygInputToolbar?.minimise()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut]) {
                    self.roomInputToolbarContainer.center = self.originalMaximisedToolbarCenter
                }
            }
        default:
            break
        }
    }

}
