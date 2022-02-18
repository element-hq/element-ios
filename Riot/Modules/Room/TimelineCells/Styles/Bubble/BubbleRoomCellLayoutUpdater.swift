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
    
    func maximumTextViewWidth(for cell: MXKRoomBubbleTableViewCell, cellData: MXKCellData, maximumCellWidth: CGFloat) -> CGFloat {
        
        guard cell.messageTextView != nil else {
            return 0
        }
        
        let maxTextViewWidth: CGFloat
        
        let textViewleftMargin: CGFloat
        let textViewRightMargin: CGFloat
        
        if let roomBubbleCellData = cellData as? RoomBubbleCellData, cell is MXKRoomIncomingTextMsgBubbleCell || cell is MXKRoomOutgoingTextMsgBubbleCell {
            
            if roomBubbleCellData.isIncoming {
                let textViewInsets = self.getIncomingMessageTextViewInsets(from: cell)
                
                textViewleftMargin = cell.msgTextViewLeadingConstraint.constant + textViewInsets.left
                // Right inset is in fact margin in this case
                textViewRightMargin = textViewInsets.right
            } else {
                let textViewMargins = self.getOutgoingMessageTextViewMargins(from: cell)
                
                textViewleftMargin = textViewMargins.left
                textViewRightMargin = textViewMargins.right
            }
        } else {
            textViewleftMargin = cell.msgTextViewLeadingConstraint.constant
            textViewRightMargin = cell.msgTextViewTrailingConstraint.constant
        }
        
        maxTextViewWidth = maximumCellWidth - (textViewleftMargin + textViewRightMargin)
        
        guard maxTextViewWidth >= 0 else {
            return 0
        }
        
        guard maxTextViewWidth <= maximumCellWidth else {
            return maxTextViewWidth
        }
        
        return maxTextViewWidth
    }
    
    // MARK: Themable
    
    func update(theme: Theme) {
        self.theme = theme
    }
    
    // MARK: - Private
    
    // MARK: Text message
    
    private func getIncomingMessageTextViewInsets(from bubbleCell: MXKRoomBubbleTableViewCell) -> UIEdgeInsets {
        
        let messageViewMarginTop: CGFloat = 0
        let messageViewMarginBottom: CGFloat = 0
        let messageViewMarginLeft: CGFloat = 0
        let messageViewMarginRight: CGFloat = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right + BubbleRoomCellLayoutConstants.bubbleTextViewInsets.right
        
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
        
        // Right inset is in fact margin in this case
        cell.msgTextViewTrailingConstraint.constant = messageViewInsets.right
    }
    
    private func getOutgoingMessageTextViewMargins(from bubbleCell: MXKRoomBubbleTableViewCell) -> UIEdgeInsets {
        
        let messageViewMarginTop: CGFloat = 0
        let messageViewMarginBottom: CGFloat = 0
        let messageViewMarginLeft = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left + BubbleRoomCellLayoutConstants.bubbleTextViewInsets.left
        
        let messageViewMarginRight = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right + BubbleRoomCellLayoutConstants.bubbleTextViewInsets.right
            
        let messageViewInsets = UIEdgeInsets(top: messageViewMarginTop, left: messageViewMarginLeft, bottom: messageViewMarginBottom, right: messageViewMarginRight)
                
        return messageViewInsets
    }
    
    private func setupOutgoingMessageTextViewMargins(for cell: MXKRoomBubbleTableViewCell) {
        
        guard let messageTextView = cell.messageTextView else {
            return
        }
        
        let contentView = cell.contentView
        
        let messageViewMargins = self.getOutgoingMessageTextViewMargins(from: cell)
        
        cell.msgTextViewLeadingConstraint.isActive = false
        cell.msgTextViewTrailingConstraint.isActive = false
        
        let leftConstraint = messageTextView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: messageViewMargins.left)
        
        let rightConstraint = messageTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -messageViewMargins.right)
        
        NSLayoutConstraint.activate([
            leftConstraint,
            rightConstraint
        ])

        cell.msgTextViewLeadingConstraint = leftConstraint
        cell.msgTextViewTrailingConstraint = rightConstraint
        
        cell.msgTextViewBottomConstraint.constant += messageViewMargins.bottom
    }
    
    // MARK: File attachment
    
    private func setupOutgoingFileAttachViewMargins(for cell: MXKRoomBubbleTableViewCell) {
        
        guard let attachmentView = cell.attachmentView else {
            return
        }

        let contentView = cell.contentView
                
        let rightMargin = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right

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
        
        let leftMargin: CGFloat = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left

        let leftConstraint = attachmentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: leftMargin)

        NSLayoutConstraint.activate([
            leftConstraint
        ])
        
        cell.attachViewLeadingConstraint = leftConstraint
    }
}
