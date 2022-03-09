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
