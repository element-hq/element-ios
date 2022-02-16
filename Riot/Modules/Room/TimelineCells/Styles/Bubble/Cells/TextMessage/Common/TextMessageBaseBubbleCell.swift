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
        
        bubbleCellContentView?.innerContentViewBottomContraint.constant = BubbleRoomCellLayoutConstants.innerContentViewMargins.bottom
        
        let textMessageContentView = TextMessageBubbleCellContentView.instantiate()
                
        contentView.vc_addSubViewMatchingParent(textMessageContentView)
        
        self.textMessageContentView = textMessageContentView
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        if let messageTextView = self.messageTextView {
            messageTextView.tintColor = theme.tintColor
        }
    }
}

// MARK: - RoomCellTimestampDisplayable
extension TextMessageBaseBubbleCell: TimestampDisplayable {
    
    func addTimestampView(_ timestampView: UIView) {
        guard let messageBubbleBackgroundView = self.textMessageContentView?.bubbleBackgroundView else {
            return
        }
        messageBubbleBackgroundView.removeTimestampView()
        messageBubbleBackgroundView.addTimestampView(timestampView)
    }
    
    func removeTimestampView() {
        guard let messageBubbleBackgroundView = self.textMessageContentView?.bubbleBackgroundView else {
            return
        }
        messageBubbleBackgroundView.removeTimestampView()
    }
}
