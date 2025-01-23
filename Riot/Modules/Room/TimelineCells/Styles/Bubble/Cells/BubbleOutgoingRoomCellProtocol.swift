// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol BubbleOutgoingRoomCellProtocol: BubbleRoomCellProtocol {
        
}

// MARK: - Default implementation
extension BubbleOutgoingRoomCellProtocol {
    
    // MARK: - Public
    
    func setupBubbleDecorations() {
        self.roomCellContentView?.decorationViewsAlignment = .right
        self.setupDecorationConstraints()
    }
    
    // MARK: - Private
    
    private func setupDecorationConstraints() {
        
        self.setupURLPreviewContentViewContraints()
        self.setupReactionsContentViewContraints()
        self.setupThreadSummaryViewContentViewContraints()
    }
    
    private func setupReactionsContentViewContraints() {
        guard let roomCellContentView = self.roomCellContentView, let reactionsContentView = roomCellContentView.reactionsContentView, let reactionsContainerView = roomCellContentView.reactionsContainerView else {
            return
        }
        
        // Remove leading constraint
        
        roomCellContentView.reactionsContentViewLeadingConstraint.isActive = false
        roomCellContentView.reactionsContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = self.setupDecorationViewLeadingContraint(containerView: reactionsContainerView, contentView: reactionsContentView)
        
        roomCellContentView.reactionsContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        roomCellContentView.reactionsContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
    }
    
    private func setupThreadSummaryViewContentViewContraints() {
        
        guard let roomCellContentView = self.roomCellContentView, let threadSummaryContentView = roomCellContentView.threadSummaryContentView, let threadSummaryContainerView = roomCellContentView.threadSummaryContainerView else {
            return
        }
        
        // Remove leading constraint
                
        roomCellContentView.threadSummaryContentViewLeadingConstraint.isActive = false
        roomCellContentView.threadSummaryContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = self.setupDecorationViewLeadingContraint(containerView: threadSummaryContainerView, contentView: threadSummaryContentView)
        
        roomCellContentView.threadSummaryContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        roomCellContentView.threadSummaryContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
        
        // Update bottom constraint
                
        roomCellContentView.threadSummaryContentViewBottomConstraint.constant = BubbleRoomCellLayoutConstants.threadSummaryViewMargins.bottom
    }
    
    private func setupURLPreviewContentViewContraints() {
        
        guard let roomCellContentView = self.roomCellContentView, let contentView = roomCellContentView.urlPreviewContentView, let containerView = roomCellContentView.urlPreviewContainerView else {
            return
        }
        
        // Remove leading constraint
                
        roomCellContentView.urlPreviewContentViewLeadingConstraint.isActive = false
        roomCellContentView.urlPreviewContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = self.setupDecorationViewLeadingContraint(containerView: containerView, contentView: contentView)
        
        roomCellContentView.urlPreviewContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        roomCellContentView.urlPreviewContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
    }
    
    private func setupDecorationViewLeadingContraint(containerView: UIView,
                                                      contentView: UIView) -> NSLayoutConstraint {
                                                
        let leadingConstraint = contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left)
        leadingConstraint.isActive = true
        return leadingConstraint
    }
}
