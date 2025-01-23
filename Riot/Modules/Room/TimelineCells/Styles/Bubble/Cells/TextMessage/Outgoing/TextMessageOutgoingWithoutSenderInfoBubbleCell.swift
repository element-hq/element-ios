// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class TextMessageOutgoingWithoutSenderInfoBubbleCell: TextMessageBaseBubbleCell, BubbleOutgoingRoomCellProtocol {    
    
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
        
        self.setupBubbleConstraints()
        self.setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.textMessageContentView?.bubbleBackgroundView?.backgroundColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
    
    override func render(_ cellData: MXKCellData!) {
        // This cell displays an outgoing message without any sender information.
        // However, we need to set the following properties to our cellData, otherwise, to make room for the timestamp, a whitespace could be added when calculating the position of the components.
        // If we don't, the component frame calculation will not work for this cell.
        (cellData as? RoomBubbleCellData)?.shouldHideSenderName = false
        (cellData as? RoomBubbleCellData)?.shouldHideSenderInformation = false
        super.render(cellData)
    }
    
    // MARK: - Private
    
    private func setupBubbleConstraints() {
        
        self.roomCellContentView?.innerContentViewLeadingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left
        self.roomCellContentView?.innerContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
        
        guard let containerView = self.textMessageContentView, let bubbleBackgroundView = containerView.bubbleBackgroundView else {
            return
        }
        
        // Remove existing contraints
        
        if let bubbleBackgroundViewLeadingConstraint = self.textMessageContentView?.bubbleBackgroundViewLeadingConstraint {
            bubbleBackgroundViewLeadingConstraint.isActive = false
            self.textMessageContentView?.bubbleBackgroundViewLeadingConstraint = nil
        }
        
        if let bubbleBackgroundViewTrailingConstraint = self.textMessageContentView?.bubbleBackgroundViewTrailingConstraint {
            bubbleBackgroundViewTrailingConstraint.isActive = false
            self.textMessageContentView?.bubbleBackgroundViewTrailingConstraint = nil
        }
        
        // Setup new constraints
        
        let leadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
        
        let trailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
                
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint
        ])
                
        self.textMessageContentView?.bubbleBackgroundViewLeadingConstraint = leadingConstraint
        
        self.textMessageContentView?.bubbleBackgroundViewTrailingConstraint = trailingConstraint
    }
}
