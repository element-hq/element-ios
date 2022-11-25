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
import Combine
import UIKit

@available(iOS 14.0, *)
class MessageContextMenuService: MessageContextMenuServiceProtocol {
    
    // MARK: - Properties
    
    private let defaultReactions = ["👍", "👎", "😄", "🎉", "😕", "❤️", "🚀", "👀"]

    // MARK: Private
    
    private let session: MXSession
    private let event: MXEvent
    private let cell: MXKRoomBubbleTableViewCell
    private let roomDataSource: MXKRoomDataSource
    private let canEndPoll: Bool
    private let aggregatedReactions: MXAggregatedReactions?

    // MARK: Public
    
    private(set) var menuSubject: CurrentValueSubject<[MessageContextMenuItem], Never>
    private(set) var previewImageSubject: CurrentValueSubject<UIImage?, Never>
    private(set) var reactionSubject: CurrentValueSubject<[MessageReactionMenuItem], Never>
    private(set) var initialFrameSubject: CurrentValueSubject<CGRect, Never>

    // MARK: - Setup
    
    init(session: MXSession, event: MXEvent, cell: MXKRoomBubbleTableViewCell, roomDataSource: MXKRoomDataSource, canEndPoll: Bool) {
        self.session = session
        self.event = event
        self.cell = cell
        self.roomDataSource = roomDataSource
        self.canEndPoll = canEndPoll
        self.menuSubject = CurrentValueSubject([])
        self.reactionSubject = CurrentValueSubject([])
        self.aggregatedReactions = session.aggregations.aggregatedReactions(onEvent: event.eventId, inRoom: roomDataSource.roomId)

        if let view = cell.previewableView {
            initialFrameSubject = CurrentValueSubject(view.superview?.convert(view.frame, to: nil) ?? .zero)
            let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
            let image = renderer.image { ctx in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
            previewImageSubject = CurrentValueSubject(image)
        } else {
            initialFrameSubject = CurrentValueSubject(.zero)
            previewImageSubject = CurrentValueSubject(nil)
        }
        
        updateMenu()
        populateReactions()
    }
    
    // MARK: - Menu Builder
    
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
    
    // MARK: - Private
    
    private func populateReactions() {
        let reactionCounts = self.aggregatedReactions?.withNonZeroCount()?.reactions ?? []
        
        var quickReactionsWithUserReactedFlag: [String: Bool] = Dictionary(uniqueKeysWithValues: defaultReactions.map { ($0, false) })
        
        reactionCounts.forEach { (reactionCount) in
            if let hasUserReacted = quickReactionsWithUserReactedFlag[reactionCount.reaction], hasUserReacted == false {
                quickReactionsWithUserReactedFlag[reactionCount.reaction] = reactionCount.myUserHasReacted
            }
        }
        
        let reactionMenuItemViewDatas: [MessageReactionMenuItem] = defaultReactions.map { reaction -> MessageReactionMenuItem in
            let isSelected = quickReactionsWithUserReactedFlag[reaction] ?? false
            return MessageReactionMenuItem(emoji: reaction, isSelected: isSelected)
        }
        
        reactionSubject.send(reactionMenuItemViewDatas)
    }

    // MARK: - RoomActionProviderProtocol
    
    private func updateMenu() {
        if event.sentState == MXEventSentStateFailed {
            menuSubject.send([
                resendAction,
                removeAction,
                editAction,
                copyAction
            ])
        }
        
        var mainActions: [MessageContextMenuItem] = [replyAction]
        
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

        if event.sentState == MXEventSentStateSent && event.eventType == .pollStart && event.sender == session.myUserId && canEndPoll {
            mainActions.append(endPollAction)
        }

        if let moreMenu = moreMenu {
            mainActions.append(moreMenu)
        }

        menuSubject.send(mainActions)
    }
    
    private var moreMenu: MessageContextMenuItem? {
        guard showMoreOption else {
            return nil
        }
        
        var moreActions: [MessageContextMenuItem] = []
        
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
        
        return MessageContextMenuItem(
            title: VectorL10n.more,
            type: .more,
            image: UIImage(systemName: "ellipsis"),
            children: moreActions
        )
    }
    
    // MARK: - Private
    
    private var encryptionInfoAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionViewEncryption,
            type: .encryptionInfo,
            image: UIImage(systemName: "lock.circle"))
    }
    
    private var endPollAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionEndPoll,
            type: .endPoll,
            image: UIImage(systemName: "chart.bar.fill"))
    }
    
    private var redactAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: event.eventType == .pollStart ? VectorL10n.roomEventActionRemovePoll : VectorL10n.roomEventActionRedact,
            type: .redact,
            image: UIImage(systemName: "trash"),
            attributes: [.destructive])
    }
    
    private var cancelDownloadAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionCancelDownload,
            type: .cancelDownload,
            image: UIImage(systemName: "xmark.rectangle.portrait"))
    }
    
    private var saveAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionSave,
            type: .save,
            image: UIImage(systemName: "square.and.arrow.down"))
    }
    
    private var cancelSendingAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionCancelSend,
            type: .cancelSending,
            image: UIImage(systemName: "xmark.circle"),
            attributes: [.destructive])
    }
    
    private var viewInRoomAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionViewInRoom,
            type: .viewInRoom,
            image: UIImage(systemName: "eye"))
    }
    
    private var resendAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.retry,
            type: .resend,
            image: UIImage(systemName: "arrow.2.circlepath"))
    }
    
    private var replyAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomActionReply,
            type: .reply,
            image: UIImage(systemName: "arrowshape.turn.up.backward"))
    }
    
    private var replyInThreadAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionReplyInThread,
            type: .replyInThread,
            image: UIImage(systemName: "captions.bubble"))
    }
    
    private var editAction: MessageContextMenuItem {
        return MessageContextMenuItem(
            title: VectorL10n.roomEventActionEdit,
            type: .edit,
            image: UIImage(systemName: "pencil"),
            attributes: event.sender != session.myUserId ? [.disabled] : [])
    }
    
    private var removeAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.remove,
            type: .remove,
            image: UIImage(systemName: "trash"),
            attributes: [.destructive])
    }
    
    private var copyAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.copyButtonName,
            type: .copy,
            image: UIImage(systemName: "doc.on.doc"))
    }
    
    private var quoteAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionQuote,
            type: .quote,
            image: UIImage(systemName: "text.quote"))
    }
    
    private var forwardAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionForward,
            type: .forward,
            image: UIImage(systemName: "arrowshape.turn.up.forward"))
    }
    
    private var copyLinkAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionPermalink,
            type: .copyLink,
            image: UIImage(systemName: "link"))
    }
    
    private var shareAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionShare,
            type: .share,
            image: UIImage(systemName: "square.and.arrow.up"))
    }
    
    private var viewSourceAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionViewSource,
            type: .viewSource,
            image: UIImage(systemName: "chevron.left.slash.chevron.right"))
    }
    
    private var viewDecryptedSourceAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionViewDecryptedSource,
            type: .viewDecryptedSource,
            image: UIImage(systemName: "chevron.left.slash.chevron.right"))
    }
    
    private var reportAction: MessageContextMenuItem {
        MessageContextMenuItem(
            title: VectorL10n.roomEventActionReport,
            type: .report,
            image: UIImage(systemName: "exclamationmark.bubble"),
            attributes: [.destructive])
    }
}
