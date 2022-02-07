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
        self.bubbleCellContentView?.decorationViewsAlignment = .right
        self.setupDecorationConstraints()
    }
    
    // MARK: - Private
    
    private func setupDecorationConstraints() {
        
        self.setupURLPreviewContentViewContraints()
        self.setupReactionsContentViewContraints()
        self.setupThreadSummaryViewContentViewContraints()
    }
    
    private func setupReactionsContentViewContraints() {
        guard let bubbleCellContentView = self.bubbleCellContentView, let reactionsContentView = bubbleCellContentView.reactionsContentView, let reactionsContainerView = bubbleCellContentView.reactionsContainerView else {
            return
        }
        
        // Remove leading constraint
        
        bubbleCellContentView.reactionsContentViewLeadingConstraint.isActive = false
        bubbleCellContentView.reactionsContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = self.setupDecorationViewLeadingContraint(containerView: reactionsContainerView, contentView: reactionsContentView)
        
        bubbleCellContentView.reactionsContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        bubbleCellContentView.reactionsContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
    }
    
    private func setupThreadSummaryViewContentViewContraints() {
        
        guard let bubbleCellContentView = self.bubbleCellContentView, let threadSummaryContentView = bubbleCellContentView.threadSummaryContentView, let threadSummaryContainerView = bubbleCellContentView.threadSummaryContainerView else {
            return
        }
        
        // Remove leading constraint
                
        bubbleCellContentView.threadSummaryContentViewLeadingConstraint.isActive = false
        bubbleCellContentView.threadSummaryContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = self.setupDecorationViewLeadingContraint(containerView: threadSummaryContainerView, contentView: threadSummaryContentView)
        
        bubbleCellContentView.threadSummaryContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        bubbleCellContentView.threadSummaryContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
    }
    
    private func setupURLPreviewContentViewContraints() {
        
        guard let bubbleCellContentView = self.bubbleCellContentView, let contentView = bubbleCellContentView.urlPreviewContentView, let containerView = bubbleCellContentView.urlPreviewContainerView else {
            return
        }
        
        // Remove leading constraint
                
        bubbleCellContentView.urlPreviewContentViewLeadingConstraint.isActive = false
        bubbleCellContentView.urlPreviewContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = self.setupDecorationViewLeadingContraint(containerView: containerView, contentView: contentView)
        
        bubbleCellContentView.urlPreviewContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        bubbleCellContentView.urlPreviewContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
    }
    
    private func setupDecorationViewLeadingContraint(containerView: UIView,
                                                      contentView: UIView) -> NSLayoutConstraint {
                                                
        let leadingConstraint = contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left)
        leadingConstraint.isActive = true
        return leadingConstraint
    }
}
