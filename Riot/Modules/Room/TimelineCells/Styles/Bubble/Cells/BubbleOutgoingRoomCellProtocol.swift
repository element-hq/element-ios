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
