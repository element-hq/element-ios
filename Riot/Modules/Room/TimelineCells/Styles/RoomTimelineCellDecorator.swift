// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// RoomTimelineCellDecorator enables to add decoration on a cell (reactions, read receipts, timestamp, URL preview).
@objc
protocol RoomTimelineCellDecorator {
    
    func addTimestampLabelIfNeeded(toCell cell: MXKRoomBubbleTableViewCell,
                                   cellData: RoomBubbleCellData)
    
    func addTimestampLabel(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData)
    
    func addURLPreviewView(_ urlPreviewView: URLPreviewView,
                           toCell cell: MXKRoomBubbleTableViewCell,
                           cellData: RoomBubbleCellData,
                           contentViewPositionY: CGFloat)
    
    func addReactionView(_ reactionsView: RoomReactionsView,
                         toCell cell: MXKRoomBubbleTableViewCell,
                         cellData: RoomBubbleCellData,
                         contentViewPositionY: CGFloat,
                         upperDecorationView: UIView?)
    
    func addReadReceiptsView(_ readReceiptsView: MXKReceiptSendersContainer,
                             toCell cell: MXKRoomBubbleTableViewCell,
                             cellData: RoomBubbleCellData,
                             contentViewPositionY: CGFloat,
                             upperDecorationView: UIView?)

    func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView,
                              toCell cell: MXKRoomBubbleTableViewCell,
                              cellData: RoomBubbleCellData,
                              contentViewPositionY: CGFloat,
                              upperDecorationView: UIView?)
    
    func addSendStatusView(toCell cell: MXKRoomBubbleTableViewCell,
                           withFailedEventIds failedEventIds: Set<AnyHashable>)
    
    func addReadMarkerView(_ readMarkerView: UIView,
                           toCell cell: MXKRoomBubbleTableViewCell,
                           cellData: MXKRoomBubbleCellData,
                           contentViewPositionY: CGFloat)
    
    func dissmissReadMarkerView(forCell cell: MXKRoomBubbleTableViewCell,
                                cellData: RoomBubbleCellData,
                                animated: Bool,
                                completion: @escaping () -> Void)
}
