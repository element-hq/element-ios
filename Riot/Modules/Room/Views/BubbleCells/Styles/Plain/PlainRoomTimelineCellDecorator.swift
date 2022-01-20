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

        var leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin
        if cellData.containsBubbleComponentWithEncryptionBadge {
            leftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
        }
        
        let topMargin = contentViewPositionY + RoomBubbleCellLayout.urlPreviewViewTopMargin + RoomBubbleCellLayout.reactionsViewTopMargin

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

        if let reactionsDisplayable = cell as? BubbleCellReactionsDisplayable {
            reactionsDisplayable.addReactionsView(reactionsView)
        } else {
            reactionsView.translatesAutoresizingMaskIntoConstraints = false

            let cellContentView = cell.contentView

            cellContentView.addSubview(reactionsView)

            var leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin

            if cellData.containsBubbleComponentWithEncryptionBadge {
                leftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            let rightMargin = RoomBubbleCellLayout.reactionsViewRightMargin
            let topMargin = RoomBubbleCellLayout.reactionsViewTopMargin

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

        if let readReceiptsDisplayable = cell as? BubbleCellReadReceiptsDisplayable {
            readReceiptsDisplayable.addReadReceiptsView(readReceiptsView)
        } else {

            let cellContentView = cell.contentView

            cellContentView.addSubview(readReceiptsView)

            // Force receipts container size
            let widthConstraint = readReceiptsView.widthAnchor.constraint(equalToConstant: RoomBubbleCellLayout.readReceiptsViewWidth)
            let heightConstraint = readReceiptsView.heightAnchor.constraint(equalToConstant: RoomBubbleCellLayout.readReceiptsViewHeight)

            // Force receipts container position
            let trailingConstraint = readReceiptsView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -RoomBubbleCellLayout.readReceiptsViewRightMargin)

            let topMargin = RoomBubbleCellLayout.readReceiptsViewTopMargin

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

    func addSendStatusView(toCell cell: MXKRoomBubbleTableViewCell, withFailedEventIds failedEventIds: Set<AnyHashable>) {
        cell.updateTickView(withFailedEventIds: failedEventIds)
    }
}
