// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class TextMessageBaseBubbleCell: SizableBaseRoomCell, RoomCellURLPreviewDisplayable, RoomCellReactionsDisplayable, RoomCellThreadSummaryDisplayable, RoomCellReadReceiptsDisplayable, RoomCellReadMarkerDisplayable {
    
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
        
        roomCellContentView?.backgroundColor = .clear
        
        roomCellContentView?.innerContentViewBottomContraint.constant = BubbleRoomCellLayoutConstants.innerContentViewMargins.bottom
        roomCellContentView?.userNameLabelBottomConstraint.constant = BubbleRoomCellLayoutConstants.senderNameLabelMargins.bottom

        let textMessageContentView = TextMessageBubbleCellContentView.instantiate()

        roomCellContentView?.innerContentView.vc_addSubViewMatchingParent(textMessageContentView)
        
        self.textMessageContentView = textMessageContentView
        
        // Setup messageTextView property first before running `setupMessageTextView` method
        super.setupViews()
    }
    
    override func setupMessageTextViewLongPressGesture() {
        // Do nothing, otherwise default setup prevent link tap
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
