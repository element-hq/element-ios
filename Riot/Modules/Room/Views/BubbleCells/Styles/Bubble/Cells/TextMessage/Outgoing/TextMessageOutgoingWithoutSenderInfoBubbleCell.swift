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

class TextMessageOutgoingWithoutSenderInfoBubbleCell: TextMessageBaseBubbleCell {
    
    // MARK: - Constants
    
    // TODO: Use global constants
    private enum BubbleMargins {
        static let leading: CGFloat = 80.0
        static let trailing: CGFloat = 34.0
    }
    
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        bubbleCellContentView?.showSenderInfo = false
                
        self.setupBubbleConstraints()
        self.setupDecorationConstraints()
    }
    
    // MARK: - Private
    
    private func setupBubbleConstraints() {
        
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
        
        let leadingConstraint = bubbleBackgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: BubbleMargins.leading)
        
        let trailingConstraint = bubbleBackgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0)
                
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint
        ])
                
        self.textMessageContentView?.bubbleBackgroundViewLeadingConstraint = leadingConstraint
        
        self.textMessageContentView?.bubbleBackgroundViewTrailingConstraint = trailingConstraint
    }
    
    private func setupDecorationConstraints() {
        
        self.setupReactionsContentViewContraints()
    }
    
    private func setupReactionsContentViewContraints () {
        guard let bubbleCellContentView = self.bubbleCellContentView, let reactionsContentView = bubbleCellContentView.reactionsContentView, let reactionsContainerView = bubbleCellContentView.reactionsContainerView else {
            return
        }
        
        // Remove leading constraint
        
        bubbleCellContentView.reactionsContentViewLeadingConstraint.isActive = false
        bubbleCellContentView.reactionsContentViewLeadingConstraint = nil
        
        // Setup new leading constraint
        
        let leadingConstraint = reactionsContentView.leadingAnchor.constraint(equalTo: reactionsContainerView.leadingAnchor, constant: BubbleMargins.leading)
        
        leadingConstraint.isActive = true
        
        bubbleCellContentView.reactionsContentViewLeadingConstraint = leadingConstraint
        
        // Update trailing constraint
                                
        bubbleCellContentView.reactionsContentViewTrailingConstraint.constant = BubbleMargins.trailing
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.textMessageContentView?.bubbleBackgroundView?.backgroundColor = theme.roomCellOutgoingBubbleBackgroundColor
    }
    
    override func addReactionsView(_ reactionsView: UIView) {
        
        super.addReactionsView(reactionsView)
        
        if let bubbleReactionsView = reactionsView as? BubbleReactionsView {
            bubbleReactionsView.alignment = .right
        }
    }
    
    override func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView) {
        
        guard let bubbleCellContentView = self.bubbleCellContentView, let containerView = bubbleCellContentView.threadSummaryContainerView else {
            return
        }
        
        containerView.vc_removeAllSubviews()
        
        containerView.addSubview(threadSummaryView)
        
        NSLayoutConstraint.activate([
            threadSummaryView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: BubbleMargins.trailing),
            threadSummaryView.topAnchor.constraint(equalTo: containerView.topAnchor),
            threadSummaryView.heightAnchor.constraint(equalToConstant: RoomBubbleCellLayout.threadSummaryViewHeight),
            threadSummaryView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            threadSummaryView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                        constant: -BubbleMargins.trailing)
        ])
        containerView.isHidden = false
    }
}
