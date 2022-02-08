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
        return self.theme.roomCellIncomingBubbleBackgroundColor
    }
    
    private var outgoingColor: UIColor {
        return self.theme.roomCellOutgoingBubbleBackgroundColor
    }
    
    // MARK: - Setup
    
    init(theme: Theme) {
        self.theme = theme
    }
    
    // MARK: - Public
    
    func updateLayoutIfNeeded(for cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) {
        
        if cellData.isIncoming {
            self.updateLayout(forIncomingTextMessageCell: cell, andCellData: cellData)
        } else {
            self.updateLayout(forOutgoingTextMessageCell: cell, andCellData: cellData)
        }
    }
            
    func updateLayout(forIncomingTextMessageCell cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) {
        
    }
    
    func updateLayout(forOutgoingTextMessageCell cell: MXKRoomBubbleTableViewCell, andCellData cellData: MXKRoomBubbleCellData) {

    }
    
    func setupLayout(forIncomingTextMessageCell cell: MXKRoomBubbleTableViewCell) {
        
        self.setupIncomingMessageTextViewMargins(for: cell)
        
        cell.setNeedsUpdateConstraints()
    }
    
    func setupLayout(forOutgoingTextMessageCell cell: MXKRoomBubbleTableViewCell) {
        
        self.setupOutgoingMessageTextViewMargins(for: cell)
        
        // Hide avatar view
        cell.pictureView?.isHidden = true
        
        cell.setNeedsUpdateConstraints()
    }
    
    func setupLayout(forOutgoingFileAttachmentCell cell: MXKRoomBubbleTableViewCell) {
                
        // Hide avatar view
        cell.pictureView?.isHidden = true
        
        self.setupOutgoingFileAttachViewMargins(for: cell)
    }
    
    func setupLayout(forIncomingFileAttachmentCell cell: MXKRoomBubbleTableViewCell) {

        self.setupIncomingFileAttachViewMargins(for: cell)
    }
    
    func updateLayout(forSelectedStickerCell cell: RoomSelectedStickerBubbleCell) {
        
        if cell.bubbleData.isIncoming {
            self.setupLayout(forIncomingFileAttachmentCell: cell)
        } else {
            self.setupLayout(forOutgoingFileAttachmentCell: cell)
            cell.userNameLabel?.isHidden = true
            cell.pictureView?.isHidden = true
        }
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        self.theme = theme
    }
    
    // MARK: - Private
    
    // MARK: Text message
    
    private func getIncomingMessageTextViewInsets(from bubbleCell: MXKRoomBubbleTableViewCell) -> UIEdgeInsets {
        
        let bubbleBgRightMargin: CGFloat = 45
        let messageViewMarginTop: CGFloat
        let messageViewMarginBottom: CGFloat = -2.0
        let messageViewMarginLeft: CGFloat = 3.0
        let messageViewMarginRight: CGFloat = 80 + bubbleBgRightMargin
        
        if bubbleCell.userNameLabel != nil {
            messageViewMarginTop = 10.0
        } else {
            messageViewMarginTop = 0.0
        }
        
        let messageViewInsets = UIEdgeInsets(top: messageViewMarginTop, left: messageViewMarginLeft, bottom: messageViewMarginBottom, right: messageViewMarginRight)
        
        return messageViewInsets
    }
    
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
        
        let innerContentLeftMargin: CGFloat = 57
        let leftMargin: CGFloat = 80.0 + innerContentLeftMargin
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
    
    // MARK: File attachment
    
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
        
        cell.attachViewTrailingConstraint = rightConstraint
    }
    
    private func setupIncomingFileAttachViewMargins(for cell: MXKRoomBubbleTableViewCell) {
        
        guard let attachmentView = cell.attachmentView,
              cell.attachViewLeadingConstraint == nil || cell.attachViewLeadingConstraint.isActive == false else {
            return
        }
        
        if let attachViewTrailingConstraint = cell.attachViewTrailingConstraint {
            attachViewTrailingConstraint.isActive = false
            cell.attachViewTrailingConstraint = nil
        }

        let contentView = cell.contentView
        
        // TODO: Use constants
        let leftMargin: CGFloat = 67

        let leftConstraint = attachmentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -leftMargin)

        NSLayoutConstraint.activate([
            leftConstraint
        ])
        
        cell.attachViewLeadingConstraint = leftConstraint
    }
}
