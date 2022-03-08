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

    func addReactionView(_ reactionsView: RoomReactionsView,
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
    
    func addReadMarkerView(_ readMarkerView: UIView,
                           toCell cell: MXKRoomBubbleTableViewCell,
                           cellData: MXKRoomBubbleCellData,
                           contentViewPositionY: CGFloat) {
        
        if let readMarkerDisplayable = cell as? RoomCellReadMarkerDisplayable {
            
            readMarkerDisplayable.addReadMarkerView(readMarkerView)
            
        } else {
            guard let overlayContainer = cell.bubbleOverlayContainer else {
                return
            }
            
            // The read marker is added into the overlay container.
            // CAUTION: Keep disabled the user interaction on this container to not disturb tap gesture handling.
            overlayContainer.backgroundColor = UIColor.clear
            overlayContainer.alpha = 1
            overlayContainer.isUserInteractionEnabled = false
            overlayContainer.isHidden = false
            
            // Add read marker to overlayContainer
            readMarkerView.translatesAutoresizingMaskIntoConstraints = false
            overlayContainer.addSubview(readMarkerView)
            cell.readMarkerView = readMarkerView
            
            // Force read marker constraints
            let topConstraint = readMarkerView.topAnchor.constraint(equalTo: overlayContainer.topAnchor, constant: contentViewPositionY - PlainRoomCellLayoutConstants.readMarkerViewHeight)
            
            let leadingConstraint = readMarkerView.leadingAnchor.constraint(equalTo: overlayContainer.leadingAnchor)
            
            let trailingConstraint = readMarkerView.trailingAnchor.constraint(equalTo: overlayContainer.trailingAnchor)
            
            let heightConstraint = readMarkerView.heightAnchor.constraint(equalToConstant: PlainRoomCellLayoutConstants.readMarkerViewHeight)
            
            NSLayoutConstraint.activate([topConstraint,
                                         leadingConstraint,
                                         trailingConstraint,
                                         heightConstraint])
            
            cell.readMarkerViewTopConstraint = topConstraint
            cell.readMarkerViewLeadingConstraint = leadingConstraint
            cell.readMarkerViewTrailingConstraint = trailingConstraint
            cell.readMarkerViewHeightConstraint = heightConstraint
        }
    }
    
    func dissmissReadMarkerView(forCell cell: MXKRoomBubbleTableViewCell,
                                cellData: RoomBubbleCellData,
                                animated: Bool,
                                completion: @escaping () -> Void) {
        
        guard let readMarkerView = cell.readMarkerView, let readMarkerContainerView = readMarkerView.superview else {
            return
        }
        
        // Do not display the marker if this is the last message.
        if animated == false || (cellData.containsLastMessage && readMarkerView.tag == cellData.mostRecentComponentIndex) {
            readMarkerView.isHidden = true
            completion()
        } else {
            readMarkerView.isHidden = false
            
            // Animate the layout to hide the read marker
            DispatchQueue.main.async {
                
                let readMarkerContainerViewHalfWidth = readMarkerContainerView.frame.size.width/2
                
                cell.readMarkerViewLeadingConstraint?.constant = readMarkerContainerViewHalfWidth
                cell.readMarkerViewTrailingConstraint?.constant = -readMarkerContainerViewHalfWidth
                                
                UIView.animate(withDuration: 1.5,
                               delay: 0.3,
                               options: [.beginFromCurrentState, .curveEaseIn]) {
                    
                    readMarkerView.alpha = 0
                    readMarkerContainerView.layoutIfNeeded()
                    
                } completion: { finished in
                    readMarkerView.isHidden = true
                    readMarkerView.alpha = 1
                    
                    completion()
                }
            }
        }
    }
}
