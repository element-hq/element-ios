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

class TextMessageIncomingBubbleCell: TextMessageBaseBubbleCell {
    
    // MARK: - Constants
    
    // TODO: Use global constants
    private enum BubbleMargins {
        static let leading: CGFloat = 0
        static let trailing: CGFloat = 80
    }
    
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        bubbleCellContentView?.showSenderInfo = true

        self.setupBubbleConstraints()
        self.setupDecorationConstraints()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        self.textMessageContentView?.bubbleBackgroundView?.backgroundColor = theme.roomCellIncomingBubbleBackgroundColor
    }
    
    // MARK: - Private
    
    private func setupBubbleConstraints() {
        
        self.textMessageContentView?.bubbleBackgroundViewLeadingConstraint.constant = BubbleMargins.leading
        
        let innerContentViewTrailingMargin = self.bubbleCellContentView?.innerContentViewTrailingConstraint.constant ?? 0
        
        self.textMessageContentView?.bubbleBackgroundViewTrailingConstraint.constant = BubbleMargins.trailing - innerContentViewTrailingMargin
        
    }
    
    private func setupDecorationConstraints() {
        
        self.setupReactionsContentViewContraints()
    }
    
    private func setupReactionsContentViewContraints () {
        
        self.bubbleCellContentView?.reactionsContentViewTrailingConstraint.constant = BubbleMargins.trailing
    }
}
