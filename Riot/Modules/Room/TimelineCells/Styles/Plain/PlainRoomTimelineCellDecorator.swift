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

@objcMembers
class PlainRoomTimelineCellDecorator: RoomTimelineCellDecorator {
    
    // MARK: - Properties
    
    // TODO: Conforms to Themable and don't use ThemeService
    var theme: Theme {
        return ThemeService.shared().theme
    }
    
    // MARK: - RoomTimelineCellDecorator
    
    func addTimestampLabelIfNeeded(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
                
        guard cellData.containsLastMessage && cellData.isCollapsableAndCollapsed == false else {
            return
        }
        
        // Display timestamp of the last message
        self.addTimestampLabel(toCell: cell, cellData: cellData)
    }

    func addTimestampLabel(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        cell.addTimestampLabel(forComponent: UInt(cellData.mostRecentComponentIndex))
    }

    func addURLPreviewView(_ urlPreviewView: URLPreviewView,
                           toCell cell: MXKRoomBubbleTableViewCell,
                           cellData: RoomBubbleCellData,
                           contentViewPositionY: CGFloat) {
        cell.addTemporarySubview(urlPreviewView)

        let cellContentView = cell.contentView

        urlPreviewView.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewView.availableWidth = cellData.maxTextViewWidth
        cellContentView.addSubview(urlPreviewView)

        var leftMargin = PlainRoomCellLayoutConstants.reactionsViewLeftMargin
        if cellData.containsBubbleComponentWithEncryptionBadge {
            leftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
        }
        
        let topMargin = contentViewPositionY + PlainRoomCellLayoutConstants.urlPreviewViewTopMargin + PlainRoomCellLayoutConstants.reactionsViewTopMargin

        // Set the preview view's origin
        NSLayoutConstraint.activate([
            urlPreviewView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: leftMargin),
            urlPreviewView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: topMargin)
        ])
    }

    func addReactionView(_ reactionsView: BubbleReactionsView,
                         toCell cell: MXKRoomBubbleTableViewCell,
                         cellData: RoomBubbleCellData,
                         contentViewPositionY: CGFloat,
                         upperDecorationView: UIView?) {

        cell.addTemporarySubview(reactionsView)

        if let reactionsDisplayable = cell as? RoomCellReactionsDisplayable {
            reactionsDisplayable.addReactionsView(reactionsView)
        } else {
            reactionsView.translatesAutoresizingMaskIntoConstraints = false

            let cellContentView = cell.contentView

            cellContentView.addSubview(reactionsView)

            var leftMargin = PlainRoomCellLayoutConstants.reactionsViewLeftMargin

            if cellData.containsBubbleComponentWithEncryptionBadge {
                leftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
            }
            
            let rightMargin = PlainRoomCellLayoutConstants.reactionsViewRightMargin
            let topMargin = PlainRoomCellLayoutConstants.reactionsViewTopMargin

            // The top constraint may need to include the URL preview view
            let topConstraint: NSLayoutConstraint
            if let upperDecorationView = upperDecorationView {
                topConstraint = reactionsView.topAnchor.constraint(equalTo: upperDecorationView.bottomAnchor, constant: topMargin)
            } else {
                topConstraint = reactionsView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: contentViewPositionY + topMargin)
            }

            NSLayoutConstraint.activate([
                reactionsView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: leftMargin),
                reactionsView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -rightMargin),
                topConstraint
            ])
        }
    }

    func addReadReceiptsView(_ readReceiptsView: MXKReceiptSendersContainer,
                             toCell cell: MXKRoomBubbleTableViewCell,
                             cellData: RoomBubbleCellData,
                             contentViewPositionY: CGFloat,
                             upperDecorationView: UIView?) {

        cell.addTemporarySubview(readReceiptsView)

        if let readReceiptsDisplayable = cell as? RoomCellReadReceiptsDisplayable {
            readReceiptsDisplayable.addReadReceiptsView(readReceiptsView)
        } else {

            let cellContentView = cell.contentView

            cellContentView.addSubview(readReceiptsView)

            // Force receipts container size
            let widthConstraint = readReceiptsView.widthAnchor.constraint(equalToConstant: PlainRoomCellLayoutConstants.readReceiptsViewWidth)
            let heightConstraint = readReceiptsView.heightAnchor.constraint(equalToConstant: PlainRoomCellLayoutConstants.readReceiptsViewHeight)

            // Force receipts container position
            let trailingConstraint = readReceiptsView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -PlainRoomCellLayoutConstants.readReceiptsViewRightMargin)

            let topMargin = PlainRoomCellLayoutConstants.readReceiptsViewTopMargin

            let topConstraint: NSLayoutConstraint
            if let upperDecorationView = upperDecorationView {
                topConstraint = readReceiptsView.topAnchor.constraint(equalTo: upperDecorationView.bottomAnchor, constant: topMargin)
            } else {
                topConstraint = readReceiptsView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: contentViewPositionY + topMargin)
            }

            NSLayoutConstraint.activate([
                widthConstraint,
                heightConstraint,
                trailingConstraint,
                topConstraint
            ])
        }
    }

    func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView,
                              toCell cell: MXKRoomBubbleTableViewCell,
                              cellData: RoomBubbleCellData,
                              contentViewPositionY: CGFloat,
                              upperDecorationView: UIView?) {

        cell.addTemporarySubview(threadSummaryView)

        if let threadSummaryDisplayable = cell as? RoomCellThreadSummaryDisplayable {
            threadSummaryDisplayable.addThreadSummaryView(threadSummaryView)
        } else {
            threadSummaryView.translatesAutoresizingMaskIntoConstraints = false

            let cellContentView = cell.contentView

            cellContentView.addSubview(threadSummaryView)

            var leftMargin = PlainRoomCellLayoutConstants.reactionsViewLeftMargin

            if cellData.containsBubbleComponentWithEncryptionBadge {
                leftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
            }

            let rightMargin = PlainRoomCellLayoutConstants.reactionsViewRightMargin
            let topMargin = PlainRoomCellLayoutConstants.threadSummaryViewTopMargin
            let height = ThreadSummaryView.contentViewHeight(forThread: threadSummaryView.thread,
                                                             fitting: cellData.maxTextViewWidth)

            // The top constraint may need to include the URL preview view
            let topConstraint: NSLayoutConstraint
            if let upperDecorationView = upperDecorationView {
                topConstraint = threadSummaryView.topAnchor.constraint(equalTo: upperDecorationView.bottomAnchor,
                                                                       constant: topMargin)
            } else {
                topConstraint = threadSummaryView.topAnchor.constraint(equalTo: cellContentView.topAnchor,
                                                                       constant: contentViewPositionY + topMargin)
            }

            NSLayoutConstraint.activate([
                threadSummaryView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor,
                                                           constant: leftMargin),
                threadSummaryView.trailingAnchor.constraint(lessThanOrEqualTo: cellContentView.trailingAnchor,
                                                            constant: -rightMargin),
                threadSummaryView.heightAnchor.constraint(equalToConstant: height),
                topConstraint
            ])
        }
    }

    func addSendStatusView(toCell cell: MXKRoomBubbleTableViewCell, withFailedEventIds failedEventIds: Set<AnyHashable>) {
        cell.updateTickView(withFailedEventIds: failedEventIds)
    }
}
