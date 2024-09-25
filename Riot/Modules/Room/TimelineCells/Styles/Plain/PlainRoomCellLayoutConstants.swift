/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
