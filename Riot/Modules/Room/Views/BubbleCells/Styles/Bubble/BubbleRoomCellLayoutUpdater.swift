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

import UIKit

@objcMembers
class BubbleRoomCellLayoutUpdater: RoomCellLayoutUpdating {
    
    // MARK: - Properties
    
    private var theme: Theme
    
    private var incomingColor: UIColor {
        return self.theme.colors.system
    }
    
    private var outgoingColor: UIColor {
        return self.theme.colors.accent.withAlphaComponent(0.10)
    }
    
    // MARK: - Setup
    
    init(theme: Theme) {
        self.theme = theme
    }
    
    // MARK: - Public
    
    func updateLayoutIfNeeded(for cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) {
        
        if cellData.isSenderCurrentUser {
            self.updateLayout(forOutgoingTextMessageCell: cell, andCellData: cellData)
        } else {
            self.updateLayout(forIncomingTextMessageCell: cell, andCellData: cellData)
        }
    }
            
    func updateLayout(forIncomingTextMessageCell cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) {
        
        if let messageBubbleBackgroundView = cell.messageBubbleBackgroundView {
            
            if self.canUseBubbleBackground(forCell: cell, withCellData: cellData) {
                
                messageBubbleBackgroundView.isHidden = false
                
                self.updateMessageBubbleBackgroundView(messageBubbleBackgroundView, withCell: cell, andCellData: cellData)
            } else {
                messageBubbleBackgroundView.isHidden = true
            }
        }
    }
    
    func updateLayout(forOutgoingTextMessageCell cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) {

        if let messageBubbleBackgroundView = cell.messageBubbleBackgroundView {
            
            if self.canUseBubbleBackground(forCell: cell, withCellData: cellData) {
                
                messageBubbleBackgroundView.isHidden = false
                
                self.updateMessageBubbleBackgroundView(messageBubbleBackgroundView, withCell: cell, andCellData: cellData)
            } else {
                messageBubbleBackgroundView.isHidden = true
            }
        }
    }
    
    func setupLayout(forIncomingTextMessageCell cell: MXKRoomBubbleTableViewCell) {
        
        self.setupIncomingMessageTextViewMargins(for: cell)
        
        self.addBubbleBackgroundViewToCell(cell, backgroundColor: self.incomingColor)
        
        cell.setNeedsUpdateConstraints()
    }
    
    func setupLayout(forOutgoingTextMessageCell cell: MXKRoomBubbleTableViewCell) {
        
        self.setupOutgoingMessageTextViewMargins(for: cell)
        
        // Hide avatar view
        cell.pictureView?.isHidden = true
        
        self.addBubbleBackgroundViewToCell(cell, backgroundColor: self.outgoingColor)
        
        cell.setNeedsUpdateConstraints()
    }
    
    func setupLayout(forOutgoingFileAttachmentCell cell: MXKRoomBubbleTableViewCell) {
                
        // Hide avatar view
        cell.pictureView?.isHidden = true
        
        self.setupOutgoingFileAttachViewMargins(for: cell)
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        self.theme = theme
    }
    
    // MARK: - Private
    
    // MARK: Bubble background view
    
    private func createBubbleBackgroundView(with backgroundColor: UIColor) -> RoomMessageBubbleBackgroundView {
        
        let bubbleBackgroundView = RoomMessageBubbleBackgroundView()
        bubbleBackgroundView.backgroundColor = backgroundColor
        
        return bubbleBackgroundView
    }
    
    private func addBubbleBackgroundViewToCell(_ bubbleCell: MXKRoomBubbleTableViewCell, backgroundColor: UIColor) {
        
        guard let messageTextView =  bubbleCell.messageTextView else {
            return
        }
        
        let topMargin: CGFloat = 0.0
        let leftMargin: CGFloat = 5.0
        let rightMargin: CGFloat = 45.0 // Add extra space for timestamp
                        
        let bubbleBackgroundView = self.createBubbleBackgroundView(with: backgroundColor)
        
        bubbleCell.contentView.insertSubview(bubbleBackgroundView, at: 0)
        
        let topAnchor = messageTextView.topAnchor
        let leadingAnchor = messageTextView.leadingAnchor
        let trailingAnchor = messageTextView.trailingAnchor
        
        bubbleBackgroundView.updateHeight(messageTextView.frame.height)
        
        NSLayoutConstraint.activate([
            bubbleBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: topMargin),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -leftMargin),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: rightMargin)
        ])
    }
    
    private func canUseBubbleBackground(forCell cell: MXKRoomBubbleTableViewCell, withCellData cellData: MXKRoomBubbleCellData) -> Bool {

        guard let firstComponent = cellData.getFirstBubbleComponentWithDisplay(), let firstEvent = firstComponent.event else {
            return false
        }
        
        switch firstEvent.eventType {
        case .roomMessage:
            if let messageTypeString = firstEvent.content["msgtype"] as? String {
                
                let messageType = MXMessageType(identifier: messageTypeString)
                
                switch messageType {
                case .text, .emote, .file:
                    return true
                default:
                    break
                }
            }
        default:
            break
        }
        
        return false
    }
    
    private func getTextMessageHeight(for cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) -> CGFloat? {

        guard let roomBubbleCellData = cellData as? RoomBubbleCellData,
                let lastBubbleComponent = cellData.getLastBubbleComponentWithDisplay(),
                let firstComponent = roomBubbleCellData.getFirstBubbleComponentWithDisplay() else {
            return nil
        }

        let bubbleHeight: CGFloat

        let lastEventId = lastBubbleComponent.event.eventId
        let lastMessageBottomPosition = cell.bottomPosition(ofEvent: lastEventId)

        let firstEventId = firstComponent.event.eventId
        let firstMessageTopPosition = cell.topPosition(ofEvent: firstEventId)

        let additionalContentHeight = roomBubbleCellData.additionalContentHeight

        bubbleHeight = lastMessageBottomPosition - firstMessageTopPosition - additionalContentHeight

        guard bubbleHeight >= 0 else {
            return nil
        }

        return bubbleHeight
    }
    
    // TODO: Improve text message height calculation
    // This method is closer to final result but lack of stability because of extra vertical space not handled here.
//    private func getTextMessageHeight(for cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) -> CGFloat? {
//
//        guard let roomBubbleCellData = cellData as? RoomBubbleCellData,
//              let firstComponent = roomBubbleCellData.getFirstBubbleComponentWithDisplay() else {
//                  return nil
//              }
//
//        let bubbleHeight: CGFloat
//
//        let componentIndex = cellData.bubbleComponentIndex(forEventId: firstComponent.event.eventId)
//
//        let componentFrame = cell.componentFrameInContentView(for: componentIndex)
//
//        bubbleHeight = componentFrame.height
//
//        guard bubbleHeight >= 0 else {
//            return nil
//        }
//
//        return bubbleHeight
//    }
    
    private func getMessageBubbleBackgroundHeight(for cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) -> CGFloat? {

        var finalBubbleHeight: CGFloat?
        let extraMargin: CGFloat = 4.0

        if let bubbleHeight = self.getTextMessageHeight(for: cell, andCellData: cellData) {
            finalBubbleHeight = bubbleHeight + extraMargin

        } else if let messageTextViewHeight = cell.messageTextView?.frame.height {

            finalBubbleHeight = messageTextViewHeight + extraMargin
        }

        return finalBubbleHeight
    }
    
    @discardableResult
    private func updateMessageBubbleBackgroundView(_ roomMessageBubbleBackgroundView: RoomMessageBubbleBackgroundView, withCell cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) -> Bool {
        
        if let bubbleHeight = self.getMessageBubbleBackgroundHeight(for: cell, andCellData: cellData) {
            return roomMessageBubbleBackgroundView.updateHeight(bubbleHeight)
        } else {
            return false
        }
    }
    
    private func getIncomingMessageTextViewInsets(from bubbleCell: MXKRoomBubbleTableViewCell) -> UIEdgeInsets {
        
        let messageViewMarginTop: CGFloat
        let messageViewMarginBottom: CGFloat = -2.0
        let messageViewMarginLeft: CGFloat = 3.0
        let messageViewMarginRight: CGFloat = 80
        
        if bubbleCell.userNameLabel != nil {
            messageViewMarginTop = 10.0
        } else {
            messageViewMarginTop = 0.0
        }
        
        let messageViewInsets = UIEdgeInsets(top: messageViewMarginTop, left: messageViewMarginLeft, bottom: messageViewMarginBottom, right: messageViewMarginRight)
        
        return messageViewInsets
    }
    
    // MARK: Text message
    
    private func setupIncomingMessageTextViewMargins(for cell: MXKRoomBubbleTableViewCell) {
        
        guard cell.messageTextView != nil else {
            return
        }
        
        let messageViewInsets = self.getIncomingMessageTextViewInsets(from: cell)
        
        cell.msgTextViewBottomConstraint.constant += messageViewInsets.bottom
        cell.msgTextViewTopConstraint.constant += messageViewInsets.top
        cell.msgTextViewLeadingConstraint.constant += messageViewInsets.left
        cell.msgTextViewTrailingConstraint.constant += messageViewInsets.right
    }
    
    private func setupOutgoingMessageTextViewMargins(for cell: MXKRoomBubbleTableViewCell) {
        
        guard let messageTextView = cell.messageTextView else {
            return
        }
        
        let contentView = cell.contentView
        
        let leftMargin: CGFloat = 80.0
        let rightMargin: CGFloat = 78.0
        let bottomMargin: CGFloat = -2.0
        
        cell.msgTextViewLeadingConstraint.isActive = false
        cell.msgTextViewTrailingConstraint.isActive = false
        
        let leftConstraint = messageTextView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: leftMargin)
        
        let rightConstraint = messageTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -rightMargin)
        
        NSLayoutConstraint.activate([
            leftConstraint,
            rightConstraint
        ])

        cell.msgTextViewLeadingConstraint = leftConstraint
        cell.msgTextViewTrailingConstraint = rightConstraint
        
        cell.msgTextViewBottomConstraint.constant += bottomMargin
    }
    
    private func setupOutgoingFileAttachViewMargins(for cell: MXKRoomBubbleTableViewCell) {
        
        guard let attachmentView = cell.attachmentView else {
            return
        }

        let contentView = cell.contentView
        
        // TODO: Use constants
        // Same as URL preview
        let rightMargin: CGFloat = 34.0

        if let attachViewLeadingConstraint = cell.attachViewLeadingConstraint {
            attachViewLeadingConstraint.isActive = false
            cell.attachViewLeadingConstraint = nil
        }

        let rightConstraint = attachmentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -rightMargin)

        NSLayoutConstraint.activate([
            rightConstraint
        ])
    }
}
