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

class TextMessageOutgoingWithoutSenderInfoBubbleCell: TextMessageBaseBubbleCell, BubbleOutgoingRoomCellProtocol {
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = false
        
        setupBubbleConstraints()
        setupBubbleDecorations()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        textMessageContentView?.bubbleBackgroundView?.backgroundColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
    
    // MARK: - Private
    
    private func setupBubbleConstraints() {
        roomCellContentView?.innerContentViewLeadingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left
        roomCellContentView?.innerContentViewTrailingConstraint.constant = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
        
        guard let containerView = textMessageContentView, let bubbleBackgroundView = containerView.bubbleBackgroundView else {
            return
        }
        
        // Remove existing contraints
        
        if let bubbleBackgroundViewLeadingConstraint = textMessageContentView?.bubbleBackgroundViewLeadingConstraint {
            bubbleBackgroundViewLeadingConstraint.isActive = false
            textMessageContentView?.bubbleBackgroundViewLeadingConstraint = nil
        }
        
        if let bubbleBackgroundViewTrailingConstraint = textMessageContentView?.bubbleBackgroundViewTrailingConstraint {
            bubbleBackgroundViewTrailingConstraint.isActive = false
            textMessageContentView?.bubbleBackgroundViewTrailingConstraint = nil
        }
        
        // Setup new constraints
        
        let leadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor)
        
        let trailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
                
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint
        ])
                
        textMessageContentView?.bubbleBackgroundViewLeadingConstraint = leadingConstraint
        
        textMessageContentView?.bubbleBackgroundViewTrailingConstraint = trailingConstraint
    }
}
