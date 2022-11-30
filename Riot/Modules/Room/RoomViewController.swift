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
            } else if !self.send(asIRCStyleCommandIfPossible: rawTextMsg) {
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
    
    @objc func didChangeMaximisedState(_ isMaximised: Bool) {
        guard let wysiwygInputToolbar = wysiwygInputToolbar else { return }
        if isMaximised {
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
            var originalRect = roomInputToolbarContainer.convert(roomInputToolbarContainer.frame, to: view)
            var optionalTextView: UITextView?
            if wysiwygInputToolbar.isFocused {
                let textView = UITextView()
                optionalTextView = textView
                self.view.window?.addSubview(textView)
                optionalTextView?.becomeFirstResponder()
                originalRect = wysiwygInputToolbar.convert(wysiwygInputToolbar.frame, to: view)
            }
            // This tirggers a SwiftUI update that is handled correctly on iOS 16, but needs to be dispatchted async on older versions
            // Dispatching on iOS 16 instead causes some weird SwiftUI update behaviours
            if #available(iOS 16, *) {
                wysiwygInputToolbar.showKeyboard()
            } else {
                DispatchQueue.main.async {
                    wysiwygInputToolbar.showKeyboard()
                }
            }
            roomInputToolbarContainer.removeFromSuperview()
            let dimmingView = UIView()
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            // Same as the system dimming background color
            dimmingView.backgroundColor = .black.withAlphaComponent(ThemeService.shared().isCurrentThemeDark() ? 0.29 : 0.12)
            maximisedToolbarDimmingView = dimmingView
            view.addSubview(dimmingView)
            dimmingView.frame = view.bounds
            NSLayoutConstraint.activate(
                [
                    dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
                    dimmingView.leftAnchor.constraint(equalTo: view.leftAnchor),
                    dimmingView.rightAnchor.constraint(equalTo: view.rightAnchor),
                    dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ]
            )
            dimmingView.addSubview(self.roomInputToolbarContainer)
            roomInputToolbarContainer.frame = originalRect
            roomInputToolbarContainer.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
            roomInputToolbarContainer.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
            roomInputToolbarContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            UIView.animate(withDuration: kResizeComposerAnimationDuration, delay: 0, options: [.curveEaseInOut]) {
                view.layoutIfNeeded()
            }
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanRoomToolbarContainer(_ :)))
            roomInputToolbarContainer.addGestureRecognizer(panGesture)
            optionalTextView?.removeFromSuperview()
        } else {
            let originalRect = wysiwygInputToolbar.convert(wysiwygInputToolbar.frame, to: view)
            var optionalTextView: UITextView?
            if wysiwygInputToolbar.isFocused {
                let textView = UITextView()
                optionalTextView = textView
                self.view.window?.addSubview(textView)
                optionalTextView?.becomeFirstResponder()
                wysiwygInputToolbar.showKeyboard()
            }
            self.roomInputToolbarContainer.removeFromSuperview()
            maximisedToolbarDimmingView?.removeFromSuperview()
            maximisedToolbarDimmingView = nil
            self.view.insertSubview(self.roomInputToolbarContainer, belowSubview: self.overlayContainerView)
            roomInputToolbarContainer.frame = originalRect
            NSLayoutConstraint.activate(self.toolbarContainerConstraints)
            self.roomInputToolbarContainerBottomConstraint.isActive = true
            UIView.animate(withDuration: kResizeComposerAnimationDuration, delay: 0, options: [.curveEaseInOut]) {
                self.view.layoutIfNeeded()
            }
            roomInputToolbarContainer.gestureRecognizers?.removeAll()
            optionalTextView?.removeFromSuperview()
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
        guard let wysiwygInputToolbar = wysiwygInputToolbar else { return }
        switch sender.state {
        case .began:
            wysiwygTranslation = wysiwygInputToolbar.maxExpandedHeight
        case .changed:
            let translation = sender.translation(in: view.window)
            let translatedValue = wysiwygInputToolbar.maxExpandedHeight - translation.y
            wysiwygTranslation = translatedValue
            guard translatedValue <= wysiwygInputToolbar.maxExpandedHeight, translatedValue >= wysiwygInputToolbar.compressedHeight else { return }
            wysiwygInputToolbar.idealHeight = translatedValue
        case .ended:
            if wysiwygTranslation <= wysiwygInputToolbar.maxCompressedHeight {
                wysiwygInputToolbar.minimise()
            } else {
                wysiwygTranslation = wysiwygInputToolbar.maxExpandedHeight
                wysiwygInputToolbar.idealHeight = wysiwygInputToolbar.maxExpandedHeight
            }
        case .cancelled:
            wysiwygTranslation = wysiwygInputToolbar.maxExpandedHeight
            wysiwygInputToolbar.idealHeight = wysiwygInputToolbar.maxExpandedHeight
        default:
            break
        }
    }
}
