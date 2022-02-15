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
    
    // Text message bubbles margins from cell content view
    
    static let outgoingBubbleBackgroundMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 80, bottom: 0, right: 34)

    static let incomingBubbleBackgroundMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 80)
    
    static let bubbleTextViewInsets: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 45)
    
    // Voice message
    
    static let voiceMessagePlaybackViewRightMargin: CGFloat = 40
    
    // Polls
    
    static let pollBubbleBackgroundInsets: UIEdgeInsets = UIEdgeInsets(top: 2, left: 10, bottom: 0, right: 10)

    // Decoration margins
    
    static let threadSummaryViewMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
}
