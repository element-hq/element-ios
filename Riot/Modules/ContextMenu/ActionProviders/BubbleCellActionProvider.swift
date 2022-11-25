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
import UIKit

@objc enum BubbleCellActionType: Int {
    case reply
    case replyInThread
    case edit
    case remove
    case copy
    case quote
    case forward
    case copyLink
    case share
    case viewSource
    case report
    case resend
    case viewInRoom
    case cancelSending
    case save
    case cancelDownload
    case viewDecryptedSource
    case redact
    case endPoll
    case encryptionInfo
}

@available(iOS 13.0, *)
@objc protocol BubbleCellActionProviderDelegate: AnyObject {
    func bubbleCellActionProvider(_ actionProvider: BubbleCellActionProvider, didSelectActionWithType actionType: BubbleCellActionType, for event: MXEvent, from cell: MXKRoomBubbleTableViewCell)
    func bubbleCellActionProvider(_ actionProvider: BubbleCellActionProvider, canEndPollFor event: MXEvent) -> Bool
}

/// `BubbleCellActionProvider` provides the menu for `MXKRoomBubbleCellDataStoring` instances
@available(iOS 13.0, *)
@objcMembers
@objc class BubbleCellActionProvider: NSObject {
    
    // MARK: - Properties
    
    private let event: MXEvent
    private let cell: MXKRoomBubbleTableViewCell
    private let session: MXSession
    private let roomDataSource: MXKRoomDataSource
    private weak var delegate: BubbleCellActionProviderDelegate?
    
    private var showMoreOption: Bool {
        (event.isState() && RiotSettings.shared.roomContextualMenuShowMoreOptionForStates) || (!event.isState() && RiotSettings.shared.roomContextualMenuShowMoreOptionForMessages)
    }
    
    private var showThreadOption: Bool {
        RiotSettings.shared.enableThreads && roomDataSource.threadId == nil && event.threadId == nil
    }
    
    private var attachment: MXKAttachment? {
        cell.bubbleData.attachment
    }
    
    private var isJitsiCallEvent: Bool {
        switch event.eventType {
        case .custom:
            if event.type == kWidgetMatrixEventTypeString || event.type == kWidgetModularEventTypeString {
                let widget = Widget(widgetEvent: event, inMatrixSession: session)
                return widget?.type == kWidgetTypeJitsiV1 || widget?.type == kWidgetTypeJitsiV2
            } else {
                return false
            }
        default:
            return false
        }
    }
    
    private var isCopyEnabled: Bool {
        var isCopyEnabled = event.eventType != .pollStart && (attachment == nil || attachment?.type != .sticker)
        
        if attachment == nil && !BuildSettings.messageDetailsAllowCopyMedia {
            isCopyEnabled = false
        }
        
        if isJitsiCallEvent {
            isCopyEnabled = false
        }
        
        if isCopyEnabled {
            switch event.eventType {
            case .roomMessage:
                if event.content[kMXMessageTypeKey] as? String == kMXMessageTypeKeyVerificationRequest {
                    isCopyEnabled = false
                }
            case .keyVerificationStart, .keyVerificationAccept, .keyVerificationKey, .keyVerificationMac, .keyVerificationDone, .keyVerificationCancel:
                isCopyEnabled = false
            default:
                break
            }
        }
        
        return isCopyEnabled
    }
    
    private var mediaLoader: MXMediaLoader? {
        // Upload id is stored in attachment url (nasty trick)
        guard let uploadId = attachment?.contentURL else {
            return nil
        }
        
        return MXMediaManager.existingUploader(withId: uploadId)
    }
    
    // MARK: - Setup
    
    init(event: MXEvent, cell: MXKRoomBubbleTableViewCell, session: MXSession, roomDataSource: MXKRoomDataSource, delegate: BubbleCellActionProviderDelegate?) {
        self.event = event
        self.cell = cell
        self.roomDataSource = roomDataSource
        self.session = session
        self.delegate = delegate
    }
    
    // MARK: - RoomActionProviderProtocol
    
    var menu: UIMenu {
        if event.sentState == MXEventSentStateFailed {
            return UIMenu(children: [
                resendAction,
                removeAction,
                editAction,
                copyAction
            ])
        }
        
        var mainActions: [UIMenuElement] = [replyAction]
        
        if showThreadOption {
            mainActions.append(replyInThreadAction)
        }
        
        mainActions.append(editAction)
        
        if isCopyEnabled {
            mainActions.append(copyAction)
        }

        if let attachment = attachment {
            // Forwarding for already sent attachments
            if event.sentState == MXEventSentStateSent &&
                (attachment.type == .file || attachment.type == .image || attachment.type == .video || attachment.type == .voiceMessage) {
                mainActions.append(forwardAction)
            }
            
            if attachment.type != .sticker && BuildSettings.messageDetailsAllowShare {
                mainActions.append(shareAction)
            }
        } else {
            if event.sentState == MXEventSentStateSent && event.eventType != .pollStart && event.location == nil {
                mainActions.append(forwardAction)
            }

            if !isJitsiCallEvent && BuildSettings.messageDetailsAllowShare && event.eventType != .pollStart {
                mainActions.append(shareAction)
            }
        }

        if event.sentState == MXEventSentStateSent {
            if event.eventType == .pollStart && event.sender == session.myUserId
                && delegate?.bubbleCellActionProvider(self, canEndPollFor: event) == true {
                mainActions.append(endPollAction)
            }
        }

        if let moreMenu = moreMenu {
            mainActions.append(moreMenu)
        }

        return UIMenu(children: mainActions)
    }
    
    private var moreMenu: UIMenu? {
        guard showMoreOption else {
            return nil
        }
        
        var moreActions: [UIMenuElement] = []
        
        if roomDataSource.threadId != nil && event.eventId == roomDataSource.threadId {
            //  if in the thread and selected event is the root event
            //  add "View in room" action
            moreActions.append(viewInRoomAction)
        }
        
        if let attachment = attachment {
            if BuildSettings.messageDetailsAllowSave && (attachment.type == .image || attachment.type == .video) {
                moreActions.append(saveAction)
            }
            
            if event.sentState == MXEventSentStatePreparing || event.sentState == MXEventSentStateEncrypting || event.sentState == MXEventSentStateSending {
                if mediaLoader != nil {
                    moreActions.append(cancelSendingAction)
                }
            }
        } else {
            if !isJitsiCallEvent && event.eventType != .pollStart {
                moreActions.append(quoteAction)
            }
            
            if event.sentState == MXEventSentStatePreparing || event.sentState == MXEventSentStateEncrypting || event.sentState == MXEventSentStateSending {
                moreActions.append(cancelSendingAction)
            }
        }
        
        if event.sentState == MXEventSentStateSent {
            // Check whether download is in progress
            if event.isMediaAttachment() && mediaLoader != nil {
                moreActions.append(cancelDownloadAction)
            }
            
            if BuildSettings.messageDetailsAllowPermalink {
                moreActions.append(copyLinkAction)
            }
            
            if BuildSettings.messageDetailsAllowViewSource {
                moreActions.append(viewSourceAction)
                if event.isEncrypted && event.clear != nil {
                    moreActions.append(viewDecryptedSourceAction)
                }
            }
            
            if !isJitsiCallEvent && roomDataSource.room.summary.isEncrypted {
                moreActions.append(encryptionInfoAction)
            }

            // Do not allow to redact the event that enabled encryption (m.room.encryption)
            // because it breaks everything
            if event.eventType != .roomEncryption {
                moreActions.append(redactAction)
            }
            
            if event.sender != session.myUserId && RiotSettings.shared.roomContextualMenuShowReportContentOption {
                moreActions.append(reportAction)
            }
        }
        
        return UIMenu(
            title: VectorL10n.more,
            image: UIImage(systemName: "ellipsis"),
            children: moreActions
        )
    }
    
    // MARK: - Private
    
    private var encryptionInfoAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionViewEncryption,
            image: UIImage(systemName: "lock.circle")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .encryptionInfo, for: self.event, from: self.cell)
        }
    }
    
    private var endPollAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionEndPoll,
            image: UIImage(systemName: "chart.bar.fill")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .endPoll, for: self.event, from: self.cell)
        }
    }
    
    private var redactAction: UIAction {
        UIAction(
            title: event.eventType == .pollStart ? VectorL10n.roomEventActionRemovePoll : VectorL10n.roomEventActionRedact,
            image: UIImage(systemName: "trash"),
            attributes: [.destructive]) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .redact, for: self.event, from: self.cell)
        }
    }
    
    private var cancelDownloadAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionCancelDownload,
            image: UIImage(systemName: "xmark.rectangle.portrait")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .cancelDownload, for: self.event, from: self.cell)
        }
    }
    
    private var saveAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionSave,
            image: UIImage(systemName: "square.and.arrow.down")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .save, for: self.event, from: self.cell)
        }
    }
    
    private var cancelSendingAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionCancelSend,
            image: UIImage(systemName: "xmark.circle"),
            attributes: [.destructive]) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .cancelSending, for: self.event, from: self.cell)
        }
    }
    
    private var viewInRoomAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionViewInRoom,
            image: UIImage(systemName: "eye")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .viewInRoom, for: self.event, from: self.cell)
        }
    }
    
    private var resendAction: UIAction {
        UIAction(
            title: VectorL10n.retry,
            image: UIImage(systemName: "arrow.2.circlepath")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .resend, for: self.event, from: self.cell)
        }
    }
    
    private var replyAction: UIAction {
        UIAction(
            title: VectorL10n.roomActionReply,
            image: UIImage(systemName: "arrowshape.turn.up.backward")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .reply, for: self.event, from: self.cell)
        }
    }
    
    private var replyInThreadAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionReplyInThread,
            image: UIImage(systemName: "captions.bubble")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .replyInThread, for: self.event, from: self.cell)
        }
    }
    
    private var editAction: UIAction {
        let action = UIAction(
            title: VectorL10n.roomEventActionEdit,
            image: UIImage(systemName: "pencil")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .edit, for: self.event, from: self.cell)
        }
        if event.sender != session.myUserId {
            action.attributes = [.disabled]
        }
        return action
    }
    
    private var removeAction: UIAction {
        UIAction(
            title: VectorL10n.remove,
            image: UIImage(systemName: "trash"),
            attributes: [.destructive]) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .remove, for: self.event, from: self.cell)
        }
    }
    
    private var copyAction: UIAction {
        UIAction(
            title: VectorL10n.copyButtonName,
            image: UIImage(systemName: "doc.on.doc")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .copy, for: self.event, from: self.cell)
        }
    }
    
    private var quoteAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionQuote,
            image: UIImage(systemName: "text.quote")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .quote, for: self.event, from: self.cell)
        }
    }
    
    private var forwardAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionForward,
            image: UIImage(systemName: "arrowshape.turn.up.forward")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .forward, for: self.event, from: self.cell)
        }
    }
    
    private var copyLinkAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionPermalink,
            image: UIImage(systemName: "link")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .copyLink, for: self.event, from: self.cell)
        }
    }
    
    private var shareAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionShare,
            image: UIImage(systemName: "square.and.arrow.up")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .share, for: self.event, from: self.cell)
        }
    }
    
    private var viewSourceAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionViewSource,
            image: UIImage(systemName: "chevron.left.slash.chevron.right")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .viewSource, for: self.event, from: self.cell)
        }
    }
    
    private var viewDecryptedSourceAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionViewDecryptedSource,
            image: UIImage(systemName: "chevron.left.slash.chevron.right")) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .viewDecryptedSource, for: self.event, from: self.cell)
        }
    }
    
    private var reportAction: UIAction {
        UIAction(
            title: VectorL10n.roomEventActionReport,
            image: UIImage(systemName: "exclamationmark.bubble"),
            attributes: [.destructive]) { [weak self] action in
                guard let self = self else { return }
                self.delegate?.bubbleCellActionProvider(self, didSelectActionWithType: .report, for: self.event, from: self.cell)
        }
    }
}
