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

class TextMessageBaseBubbleCell: SizableBaseBubbleCell, RoomCellURLPreviewDisplayable, BubbleCellReactionsDisplayable, BubbleCellThreadSummaryDisplayable, BubbleCellReadReceiptsDisplayable {
    
    // MARK: - Properties
    
    weak var textMessageContentView: TextMessageBubbleCellContentView?
        
    override var messageTextView: UITextView! {
        get {
            return self.textMessageContentView?.textView
        }
        set { }
    }
    
    // MARK: - Overrides
    
    override func setupViews() {
        super.setupViews()
        
        bubbleCellContentView?.backgroundColor = .clear
        
        guard let contentView = bubbleCellContentView?.innerContentView else {
            return
        }
        
        // TODO: Use constants
        
        let messageLeftMargin: CGFloat = 48
        
        bubbleCellContentView?.innerContentViewLeadingConstraint.constant = messageLeftMargin
        
        self.bubbleCellContentView?.innerContentViewBottomContraint.constant = 5.0
        
        self.bubbleCellContentView?.innerContentViewTrailingConstraint.constant = 34.0
        
        let textMessageContentView = TextMessageBubbleCellContentView.instantiate()
                
        contentView.vc_addSubViewMatchingParent(textMessageContentView)
        
        self.textMessageContentView = textMessageContentView
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        if let messageTextView = self.messageTextView {
            messageTextView.tintColor = theme.tintColor
        }
        
//        self.setupDebug()
    }
    
    // MARK: - Private
    
    private func setupDebug() {
        
        self.bubbleCellContentView?.innerContentView.backgroundColor = .yellow
        
        self.bubbleCellContentView?.layer.borderWidth = 1.0
        self.bubbleCellContentView?.layer.borderColor = UIColor.red.cgColor
        
        self.textMessageContentView?.layer.borderColor = UIColor.blue.cgColor
        self.textMessageContentView?.layer.borderWidth = 1.0
        
        
        self.bubbleCellContentView?.readReceiptsContainerView.layer.borderColor = UIColor.yellow.cgColor
        self.bubbleCellContentView?.readReceiptsContainerView.layer.borderWidth = 1.0
        
        self.bubbleCellContentView?.reactionsContainerView.layer.borderColor = UIColor.blue.cgColor
        self.bubbleCellContentView?.reactionsContainerView.layer.borderWidth = 1.0
        
        self.bubbleCellContentView?.threadSummaryContainerView.layer.borderColor = UIColor.purple.cgColor
        self.bubbleCellContentView?.threadSummaryContainerView.layer.borderWidth = 1.0
    }
}

// MARK: - RoomCellTimestampDisplayable
extension TextMessageBaseBubbleCell: TimestampDisplayable {
    
    func addTimestampView(_ timestampView: UIView) {
        guard let messageBubbleBackgroundView = self.textMessageContentView?.bubbleBackgroundView else {
            return
        }
        messageBubbleBackgroundView.addTimestampView(timestampView)
    }
    
    func removeTimestampView() {
        guard let messageBubbleBackgroundView = self.textMessageContentView?.bubbleBackgroundView else {
            return
        }
        messageBubbleBackgroundView.removeTimestampView()
    }
}
