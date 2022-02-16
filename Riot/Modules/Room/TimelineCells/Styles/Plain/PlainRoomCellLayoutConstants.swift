/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// Plain room cells layout constants
@objcMembers
final class PlainRoomCellLayoutConstants: NSObject {
    
    /// Inner content view margins
    static let innerContentViewMargins: UIEdgeInsets = UIEdgeInsets(top: 0, left: 57, bottom: 0.0, right: 0)
    
    // Reactions
    
    static let reactionsViewTopMargin: CGFloat = 1.0
    static let reactionsViewLeftMargin: CGFloat = 55.0
    static let reactionsViewRightMargin: CGFloat = 15.0
    
    // Read receipts
    
    static let readReceiptsViewTopMargin: CGFloat = 5.0
    static let readReceiptsViewRightMargin: CGFloat = 6.0
    static let readReceiptsViewHeight: CGFloat = 16.0
    static let readReceiptsViewWidth: CGFloat = 150.0
    
    // Read marker
    
    static let readMarkerViewHeight: CGFloat = 2.0
    
    // Timestamp
    
    static let timestampLabelHeight: CGFloat = 18.0
    static let timestampLabelWidth: CGFloat = 39.0
    
    // Others
    
    static let encryptedContentLeftMargin: CGFloat = 15.0
    static let urlPreviewViewTopMargin: CGFloat = 8.0
    
    // Threads
    
    static let threadSummaryViewTopMargin: CGFloat = 8.0
    static let threadSummaryViewHeight: CGFloat = 40.0
    static let fromAThreadViewTopMargin: CGFloat = 8.0
}
