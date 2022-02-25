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


/// Bubble style room cell layout constants
@objcMembers
final class BubbleRoomCellLayoutConstants: NSObject {
    
    /// Inner content view margins
    static let innerContentViewMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5.0, right: 0)
    
    // Sender name margins
    
    static let senderNameLabelMargins: UIEdgeInsets = UIEdgeInsets(top: 10, left: 0, bottom: 0.0, right: 0)
    
    // Text message bubbles margins from cell content view
    
    static let outgoingBubbleBackgroundMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 34)

    static let incomingBubbleBackgroundMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 80)
    
    static let bubbleTextViewInsets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 12, right: 5)
    
    static let bubbleCornerRadius: CGFloat = 12.0
    
    // Voice message
    
    static let voiceMessagePlaybackViewRightMargin: CGFloat = 40
    
    // Polls
    
    static let pollBubbleBackgroundInsets: UIEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 0, right: 10)

    // Decoration margins
    
    // Timestamp margins
    
    /// Timestamp margins for sticker cell, margin is relative to the image view
    static let stickerTimestampViewMargins = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: -27) // Right margin is not reliable there, if the text size change this one is not working anymore
    
    /// Timestamp margins inside bubble
    static let bubbleTimestampViewMargins = UIEdgeInsets(top: 0, left: 0, bottom: 4.0, right: 8.0)
    
    static let reactionsViewMargins = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        
    static let threadSummaryViewMargins: UIEdgeInsets = UIEdgeInsets(top: 8.0, left: 0, bottom: 5, right: 0)
}
