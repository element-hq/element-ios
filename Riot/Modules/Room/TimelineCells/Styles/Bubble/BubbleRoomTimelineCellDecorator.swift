// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class BubbleRoomTimelineCellDecorator: PlainRoomTimelineCellDecorator {
        
    override func addTimestampLabelIfNeeded(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        
        guard self.canShowTimestamp(forCellData: cellData) else {
            return
        }
        
        self.addTimestampLabel(toCell: cell, cellData: cellData)
    }
        
    override func addTimestampLabel(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        
        guard let timestampLabel = self.createTimestampLabel(for: cellData) else {
            super.addTimestampLabel(toCell: cell, cellData: cellData)
            return
        }
        
        if let timestampDisplayable = cell as? TimestampDisplayable {
            
            timestampDisplayable.addTimestampView(timestampLabel)
            
        } else if cellData.isAttachmentWithThumbnail {
                                                 
            if cellData.attachment?.type == .sticker,
               let attachmentView = cell.attachmentView {
                
                // Prevent overlap with send status icon
                let bottomMargin: CGFloat = BubbleRoomCellLayoutConstants.stickerTimestampViewMargins.bottom
                let rightMargin: CGFloat = BubbleRoomCellLayoutConstants.stickerTimestampViewMargins.right
                
                self.addTimestampLabel(timestampLabel,
                                       to: cell,
                                       on: cell.contentView,
                                       constrainingView: attachmentView,
                                       rightMargin: rightMargin,
                                       bottomMargin: bottomMargin)
                
            } else if let attachmentView = cell.attachmentView {
                // For media with thumbnail cells, add timestamp inside thumbnail
                
                timestampLabel.textColor = self.theme.baseIconPrimaryColor
                
                self.addTimestampLabel(timestampLabel,
                                       to: cell,
                                       on: cell.contentView,
                                       constrainingView: attachmentView)
                
            } else {
                super.addTimestampLabel(toCell: cell, cellData: cellData)
            }
        } else if let voiceMessageCell = cell as? VoiceMessagePlainCell, let playbackView = voiceMessageCell.playbackController?.playbackView {
            
            // Add timestamp on cell inherting from VoiceMessageBubbleCell
            
            self.addTimestampLabel(timestampLabel,
                                   to: cell,
                                   on: cell.contentView,
                                   constrainingView: playbackView)
            
        } else if let fileWithoutThumbnailCell = cell as? FileWithoutThumbnailBaseBubbleCell, let fileAttachementView = fileWithoutThumbnailCell.fileAttachementView {
            
            // Add timestamp on cell inherting from VoiceMessageBubbleCell
            
            self.addTimestampLabel(timestampLabel,
                                   to: cell,
                                   on: fileAttachementView,
                                   constrainingView: fileAttachementView)
            
        } else {
            super.addTimestampLabel(toCell: cell, cellData: cellData)
        }
    }
    
    override func addReactionView(_ reactionsView: RoomReactionsView,
                                  toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData, contentViewPositionY: CGFloat, upperDecorationView: UIView?) {
        
        if let reactionsDisplayable = cell as? RoomCellReactionsDisplayable {
            reactionsDisplayable.addReactionsView(reactionsView)
            return
        }
        
        cell.addTemporarySubview(reactionsView)
        
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        
        let cellContentView = cell.contentView
        
        cellContentView.addSubview(reactionsView)
                
        let topMargin: CGFloat = PlainRoomCellLayoutConstants.reactionsViewTopMargin
        let leftMargin: CGFloat
        let rightMargin: CGFloat
                
        // Incoming message
        if cellData.isIncoming {
            
            var incomingLeftMargin = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left
            
            if cellData.containsBubbleComponentWithEncryptionBadge {
                incomingLeftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
            }
            
            leftMargin = incomingLeftMargin
            
            rightMargin = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
            
        } else {
            // Outgoing message
            
            reactionsView.alignment = .right
                        
            var outgoingLeftMargin = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left
            
            if cellData.containsBubbleComponentWithEncryptionBadge {
                outgoingLeftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
            }
            
            leftMargin = outgoingLeftMargin
                        
            rightMargin = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
        }
        
        let leadingConstraint = reactionsView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: leftMargin)
        
        let trailingConstraint = reactionsView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -rightMargin)
        
        let topConstraint: NSLayoutConstraint
        if let upperDecorationView = upperDecorationView {
            topConstraint = reactionsView.topAnchor.constraint(equalTo: upperDecorationView.bottomAnchor, constant: topMargin)
        } else {
            topConstraint = reactionsView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: contentViewPositionY + topMargin)
        }
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            topConstraint
        ])
    }
    
    override func addURLPreviewView(_ urlPreviewView: URLPreviewView,
                                    toCell cell: MXKRoomBubbleTableViewCell,
                                    cellData: RoomBubbleCellData,
                                    contentViewPositionY: CGFloat) {
        
        if let urlPreviewDisplayable = cell as? RoomCellURLPreviewDisplayable {
            urlPreviewView.translatesAutoresizingMaskIntoConstraints = false
            urlPreviewDisplayable.addURLPreviewView(urlPreviewView)
        } else {
            cell.addTemporarySubview(urlPreviewView)
            
            let cellContentView = cell.contentView
            
            urlPreviewView.translatesAutoresizingMaskIntoConstraints = false
            urlPreviewView.availableWidth = cellData.maxTextViewWidth
            cellContentView.addSubview(urlPreviewView)
            
            let leadingOrTrailingConstraint: NSLayoutConstraint
            
            
            // Incoming message
            if cellData.isIncoming {

                var leftMargin = PlainRoomCellLayoutConstants.reactionsViewLeftMargin
                if cellData.containsBubbleComponentWithEncryptionBadge {
                    leftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
                }
                
                leadingOrTrailingConstraint = urlPreviewView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: leftMargin)
            } else {
                // Outgoing message
                
                let rightMargin: CGFloat = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
                
                leadingOrTrailingConstraint = urlPreviewView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -rightMargin)
            }
            
            let topMargin = contentViewPositionY + PlainRoomCellLayoutConstants.urlPreviewViewTopMargin + PlainRoomCellLayoutConstants.reactionsViewTopMargin
            
            // Set the preview view's origin
            NSLayoutConstraint.activate([
                leadingOrTrailingConstraint,
                urlPreviewView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: topMargin)
            ])
        }
    }
    
    override func addThreadSummaryView(_ threadSummaryView: ThreadSummaryView,
                              toCell cell: MXKRoomBubbleTableViewCell,
                              cellData: RoomBubbleCellData,
                              contentViewPositionY: CGFloat,
                              upperDecorationView: UIView?) {

        if let threadSummaryDisplayable = cell as? RoomCellThreadSummaryDisplayable {
            threadSummaryDisplayable.addThreadSummaryView(threadSummaryView)
        } else {
            
            cell.addTemporarySubview(threadSummaryView)
            threadSummaryView.translatesAutoresizingMaskIntoConstraints = false

            let cellContentView = cell.contentView

            cellContentView.addSubview(threadSummaryView)
            
            var rightMargin: CGFloat
            var leftMargin: CGFloat
            
            let leadingConstraint: NSLayoutConstraint
            let trailingConstraint: NSLayoutConstraint
                        
            // Incoming message
            if cellData.isIncoming {

                leftMargin = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.left
                if cellData.containsBubbleComponentWithEncryptionBadge {
                    leftMargin += PlainRoomCellLayoutConstants.encryptedContentLeftMargin
                }
                
                rightMargin = BubbleRoomCellLayoutConstants.incomingBubbleBackgroundMargins.right
                
                leadingConstraint = threadSummaryView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor,
                                                           constant: leftMargin)
                trailingConstraint = threadSummaryView.trailingAnchor.constraint(lessThanOrEqualTo: cellContentView.trailingAnchor,
                                                                                 constant: -rightMargin)
            } else {
                // Outgoing message
                                
                leftMargin = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.left
                rightMargin = BubbleRoomCellLayoutConstants.outgoingBubbleBackgroundMargins.right
                
                leadingConstraint = threadSummaryView.leadingAnchor.constraint(greaterThanOrEqualTo: cellContentView.leadingAnchor,
                                                           constant: leftMargin)
                trailingConstraint = threadSummaryView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor,
                                                                                 constant: -rightMargin)
            }
            
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
                leadingConstraint,
                trailingConstraint,
                threadSummaryView.heightAnchor.constraint(equalToConstant: height),
                topConstraint
            ])
        }
    }
    
    // MARK: - Private
    
    // MARK: Timestamp management
    
    private func createTimestampLabel(cellData: MXKRoomBubbleCellData, bubbleComponent: MXKRoomBubbleComponent, viewTag: Int, textColor: UIColor) -> UILabel {
        
        let timeLabel = UILabel()

        timeLabel.text = cellData.eventFormatter.timeString(from: bubbleComponent.date)
        timeLabel.textAlignment = .right
        timeLabel.textColor = textColor
        timeLabel.font = self.theme.fonts.caption2
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.tag = viewTag
        timeLabel.accessibilityIdentifier = "timestampLabel"
        
        return timeLabel
    }
    
    func createTimestampLabel(for cellData: RoomBubbleCellData) -> UILabel? {
        return self.createTimestampLabel(for: cellData, textColor: self.theme.textSecondaryColor)
    }
    
    private func createTimestampLabel(for cellData: RoomBubbleCellData, textColor: UIColor) -> UILabel? {
        
        let componentIndex = cellData.mostRecentComponentIndex
        
        guard let bubbleComponents = cellData.bubbleComponents, componentIndex < bubbleComponents.count else {
            return nil
        }
        
        let component = bubbleComponents[componentIndex]

        return self.createTimestampLabel(cellData: cellData, bubbleComponent: component, viewTag: componentIndex, textColor: textColor)
    }
    
    private func canShowTimestamp(forCellData cellData: MXKRoomBubbleCellData) -> Bool {
        
        guard cellData.isCollapsableAndCollapsed == false else {
            return false
        }
        
        guard let firstComponent = cellData.getFirstBubbleComponentWithDisplay(), let firstEvent = firstComponent.event else {
            return false
        }
        
        switch cellData.cellDataTag {
        case .location:
            return true
        case .poll:
            return true
        default:
            break
        }
        
        if let attachmentType = cellData.attachment?.type {
            switch attachmentType {
            case .voiceMessage, .audio:
                return true
            default:
                break
            }
        }
        
        if cellData.isAttachmentWithThumbnail {
            return true
        }
        
        switch firstEvent.eventType {
        case .roomMessage:
            if let messageType = firstEvent.messageType {
                switch messageType {
                case .text, .emote, .file:
                    return true
                default:
                    break
                }
            }
        default:
            break
        }
        
        return false
    }
    
    private func addTimestampLabel(_ timestampLabel: UILabel,
                                   to cell: MXKRoomBubbleTableViewCell,
                                   on containerView: UIView,
                                   constrainingView: UIView,
                                   rightMargin: CGFloat = BubbleRoomCellLayoutConstants.bubbleTimestampViewMargins.right,
                                   bottomMargin: CGFloat = BubbleRoomCellLayoutConstants.bubbleTimestampViewMargins.bottom) {
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false

        cell.addTemporarySubview(timestampLabel)
                
        containerView.addSubview(timestampLabel)
        
        let trailingConstraint = timestampLabel.trailingAnchor.constraint(equalTo: constrainingView.trailingAnchor, constant: -rightMargin)

        let bottomConstraint = timestampLabel.bottomAnchor.constraint(equalTo: constrainingView.bottomAnchor, constant: -bottomMargin)

        NSLayoutConstraint.activate([
            trailingConstraint,
            bottomConstraint
        ])
    }
}
