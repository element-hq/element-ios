// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import HTMLParser
import UIKit
import WysiwygComposer

extension RoomViewController {
    // MARK: - Override
    open override func mention(_ roomMember: MXRoomMember) {
        if let wysiwygInputToolbar, wysiwygInputToolbar.textFormattingEnabled {
            wysiwygInputToolbar.mention(roomMember)
            wysiwygInputToolbar.becomeFirstResponder()
        } else {
            guard let attributedText = inputToolbarView.attributedTextMessage else { return }
            let newAttributedString = NSMutableAttributedString(attributedString: attributedText)

            if attributedText.length > 0 {
                if #available(iOS 15.0, *) {
                    newAttributedString.append(PillsFormatter.mentionPill(withRoomMember: roomMember,
                                                                          isHighlighted: false,
                                                                          font: inputToolbarView.defaultFont))
                } else {
                    newAttributedString.appendString(roomMember.displayname.count > 0 ? roomMember.displayname : roomMember.userId)
                }
                newAttributedString.appendString(" ")
            } else if roomMember.userId == self.mainSession.myUser.userId {
                newAttributedString.appendString("/me ")
                newAttributedString.addAttribute(.font,
                                                 value: inputToolbarView.defaultFont,
                                                 range: .init(location: 0, length: newAttributedString.length))
            } else {
                if #available(iOS 15.0, *) {
                    newAttributedString.append(PillsFormatter.mentionPill(withRoomMember: roomMember,
                                                                          isHighlighted: false,
                                                                          font: inputToolbarView.defaultFont))
                } else {
                    newAttributedString.appendString(roomMember.displayname.count > 0 ? roomMember.displayname : roomMember.userId)
                }
                newAttributedString.appendString(": ")
            }

            inputToolbarView.attributedTextMessage = newAttributedString
            inputToolbarView.becomeFirstResponder()
        }
    }

    @objc func setCommand(_ command: String) {
        if let wysiwygInputToolbar, wysiwygInputToolbar.textFormattingEnabled {
            wysiwygInputToolbar.command(command)
            wysiwygInputToolbar.becomeFirstResponder()
        } else {
            guard let attributedText = inputToolbarView.attributedTextMessage else { return }

            let newAttributedString = NSMutableAttributedString(attributedString: attributedText)
            newAttributedString.append(NSAttributedString(string: "\(command) ",
                                                          attributes: [.font: inputToolbarView.defaultFont]))

            inputToolbarView.attributedTextMessage = newAttributedString
            inputToolbarView.becomeFirstResponder()
        }
    }


    /// Send the formatted text message and its raw counterpart to the room
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
            if let optionalTextView {
                // This tirggers a SwiftUI update that is handled correctly on iOS 16, but needs to be dispatchted async on older versions
                // Dispatching on iOS 16 instead causes some weird SwiftUI update behaviours
                if #available(iOS 16, *) {
                    wysiwygInputToolbar.showKeyboard()
                } else {
                    DispatchQueue.main.async {
                        wysiwygInputToolbar.showKeyboard()
                    }
                }
                optionalTextView.removeFromSuperview()
            }
        } else {
            let originalRect = wysiwygInputToolbar.convert(wysiwygInputToolbar.frame, to: view)
            var optionalTextView: UITextView?
            if wysiwygInputToolbar.isFocused {
                let textView = UITextView()
                optionalTextView = textView
                self.view.window?.addSubview(textView)
                optionalTextView?.becomeFirstResponder()
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
            if let optionalTextView {
                wysiwygInputToolbar.showKeyboard()
                optionalTextView.removeFromSuperview()
            }
        }
    }
    
    @objc func setMaximisedToolbarIsHiddenIfNeeded(_ isHidden: Bool) {
        if wysiwygInputToolbar?.isMaximised == true {
            roomInputToolbarContainer.superview?.isHidden = isHidden
        }
    }
    
    @objc func didSendLinkAction(_ linkAction: LinkActionWrapper) {
        let presenter = ComposerLinkActionBridgePresenter(linkAction: linkAction)
        presenter.delegate = self
        composerLinkActionBridgePresenter = presenter
        presenter.present(from: self, animated: true)
    }
    
    @objc func showWaitingOtherParticipantHeader() {
        let controller = VectorHostingController(rootView: RoomWaitingForMembers())
        guard let headerView = controller.view else {
            return
        }
        self.waitingOtherParticipantViewController = controller
        self.addChild(controller)
                
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.vc_addSubViewMatchingParent(headerView, withInsets: UIEdgeInsets(top: 9, left: 9, bottom: -9, right: -9))

        self.bubblesTableView.tableHeaderView = containerView
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: self.bubblesTableView.centerXAnchor),
            containerView.widthAnchor.constraint(equalTo: self.bubblesTableView.widthAnchor),
            containerView.topAnchor.constraint(equalTo: self.bubblesTableView.topAnchor)
        ])
        controller.didMove(toParent: self)
        
        self.bubblesTableView.tableHeaderView?.layoutIfNeeded()
    }
    
    @objc func hideWaitingOtherParticipantHeader() {
        guard let waitingOtherParticipantViewController else {
            return
        }
        waitingOtherParticipantViewController.removeFromParent()
        self.bubblesTableView.tableHeaderView = nil
        waitingOtherParticipantViewController.didMove(toParent: nil)
        self.waitingOtherParticipantViewController = nil
    }
    
    @objc func waitForOtherParticipant(_ wait: Bool) {
        self.isWaitingForOtherParticipants = wait
        if wait {
            showWaitingOtherParticipantHeader()
        } else {
            hideWaitingOtherParticipantHeader()
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

extension RoomViewController: ComposerLinkActionBridgePresenterDelegate {
    func didRequestLinkOperation(_ linkOperation: WysiwygLinkOperation) {
        dismissPresenter { [weak self] in
            self?.wysiwygInputToolbar?.performLinkOperation(linkOperation)
        }
    }
    
    func didDismissInteractively() {
        cleanup()
    }
    
    func didCancel() {
        dismissPresenter(completion: nil)
    }
    
    private func dismissPresenter(completion: (() -> Void)?) {
        self.composerLinkActionBridgePresenter?.dismiss(animated: true) { [weak self] in
            completion?()
            self?.cleanup()
        }
    }
    
    private func cleanup() {
        composerLinkActionBridgePresenter = nil
    }
}

// MARK: - PermalinkReplacer
extension RoomViewController: MentionReplacer {
    public func replacementForMention(_ url: String, text: String) -> NSAttributedString? {
        guard #available(iOS 15.0, *),
              let url = URL(string: url),
              let session = roomDataSource.mxSession,
              let eventFormatter = roomDataSource.eventFormatter,
              let roomState = roomDataSource.roomState else {
            return nil
        }

        return PillsFormatter.mentionPill(withUrl: url,
                                          andLabel: text,
                                          session: session,
                                          eventFormatter: eventFormatter,
                                          roomState: roomState)
    }

    public func postProcessMarkdown(in attributedString: NSAttributedString) -> NSAttributedString {
        guard #available(iOS 15.0, *),
              let roomDataSource,
              let session = roomDataSource.mxSession,
              let eventFormatter = roomDataSource.eventFormatter,
              let roomState = roomDataSource.roomState else {
            return attributedString
        }
        return PillsFormatter.insertPills(in: attributedString,
                                          withSession: session,
                                          eventFormatter: eventFormatter,
                                          roomState: roomState,
                                          font: inputToolbarView.defaultFont)
    }

    public func restoreMarkdown(in attributedString: NSAttributedString) -> String {
        if #available(iOS 15.0, *) {
            return PillsFormatter.stringByReplacingPills(in: attributedString, mode: .markdown)
        } else {
            return attributedString.string
        }
    }
}

// MARK: - VoiceBroadcast
extension RoomViewController {
    @objc func stopUncompletedVoiceBroadcastIfNeeded() {
        self.roomDataSource?.room.stopUncompletedVoiceBroadcastIfNeeded()
    }
}
