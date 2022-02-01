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

class BubbleRoomTimelineCellDecorator: PlainRoomTimelineCellDecorator {
        
    override func addTimestampLabelIfNeeded(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        
        guard self.canShowTimestamp(forCellData: cellData) else {
            return
        }
        
        self.addTimestampLabel(toCell: cell, cellData: cellData)
    }
        
    override func addTimestampLabel(toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData) {
        
        // If cell contains a bubble background, add the timestamp inside of it
        if let bubbleBackgroundView = cell.messageBubbleBackgroundView, bubbleBackgroundView.isHidden == false, let timestampLabel = self.createTimestampLabel(for: cellData) {
            
            self.addTimestampLabel(timestampLabel,
                                   to: cell,
                                   on: bubbleBackgroundView,
                                   constrainingView: bubbleBackgroundView)
            
        } else if cellData.isAttachmentWithThumbnail {
                                                 
            if cellData.attachment?.type == .sticker,
               let attachmentView = cell.attachmentView,
                let timestampLabel = self.createTimestampLabel(for: cellData) {
                
                // Prevent overlap with send status icon
                let bottomMargin: CGFloat = 20.0
                let rightMargin: CGFloat = -27.0
                
                self.addTimestampLabel(timestampLabel,
                                       to: cell,
                                       on: cell.contentView,
                                       constrainingView: attachmentView,
                                       rightMargin: rightMargin,
                                       bottomMargin: bottomMargin)
                
            } else if let attachmentView = cell.attachmentView, let timestampLabel = self.createTimestampLabel(for: cellData, textColor: self.theme.baseIconPrimaryColor) {
                // For media with thumbnail cells, add timestamp inside thumbnail
                
                self.addTimestampLabel(timestampLabel,
                                       to: cell,
                                       on: cell.contentView,
                                       constrainingView: attachmentView)
                
            } else {
                super.addTimestampLabel(toCell: cell, cellData: cellData)
            }
        } else if let voiceMessageCell = cell as? VoiceMessageBubbleCell, let playbackView = voiceMessageCell.playbackController?.playbackView, let timestampLabel = self.createTimestampLabel(for: cellData) {
            
            // Add timestamp on cell inherting from VoiceMessageBubbleCell
            
            self.addTimestampLabel(timestampLabel,
                                   to: cell,
                                   on: cell.contentView,
                                   constrainingView: playbackView)
            
        } else if let fileWithoutThumbnailCell = cell as? FileWithoutThumbnailBaseBubbleCell, let fileAttachementView = fileWithoutThumbnailCell.fileAttachementView, let timestampLabel = self.createTimestampLabel(for: cellData) {
            
            // Add timestamp on cell inherting from VoiceMessageBubbleCell
            
            self.addTimestampLabel(timestampLabel,
                                   to: cell,
                                   on: fileAttachementView,
                                   constrainingView: fileAttachementView)
            
        } else {
            super.addTimestampLabel(toCell: cell, cellData: cellData)
        }
    }
    
    override func addReactionView(_ reactionsView: BubbleReactionsView,
                                  toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData, contentViewPositionY: CGFloat, upperDecorationView: UIView?) {
        
        cell.addTemporarySubview(reactionsView)
        
        if let reactionsDisplayable = cell as? BubbleCellReactionsDisplayable {
            reactionsDisplayable.addReactionsView(reactionsView)
            return
        }
        
        reactionsView.translatesAutoresizingMaskIntoConstraints = false
        
        let cellContentView = cell.contentView
        
        cellContentView.addSubview(reactionsView)
        
        // TODO: Use constants
        let topMargin: CGFloat = 4.0
        let leftMargin: CGFloat
        let rightMargin: CGFloat
                
        // Incoming message
        if cellData.isIncoming {
            
            var incomingLeftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin
            
            if cellData.containsBubbleComponentWithEncryptionBadge {
                incomingLeftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            leftMargin = incomingLeftMargin - 6.0
            
            // TODO: Use constants
            let messageViewMarginRight: CGFloat = 42.0
            
            rightMargin = messageViewMarginRight
        } else {
            // Outgoing message
            
            reactionsView.alignment = .right
            
            // TODO: Use constants
            var outgointLeftMargin: CGFloat = 80.0
            
            if cellData.containsBubbleComponentWithEncryptionBadge {
                outgointLeftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            leftMargin = outgointLeftMargin
            
            // TODO: Use constants
            rightMargin = 33
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
        
        cell.addTemporarySubview(urlPreviewView)
        
        let cellContentView = cell.contentView
        
        urlPreviewView.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewView.availableWidth = cellData.maxTextViewWidth
        cellContentView.addSubview(urlPreviewView)
        
        let leadingOrTrailingConstraint: NSLayoutConstraint
        
        
        // Incoming message
        if cellData.isIncoming {

            var leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin
            if cellData.containsBubbleComponentWithEncryptionBadge {
                leftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            leftMargin-=5.0
            
            leadingOrTrailingConstraint = urlPreviewView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: leftMargin)
        } else {
            // Outgoing message
            
            // TODO: Use constants
            let rightMargin: CGFloat = 34.0
            
            leadingOrTrailingConstraint = urlPreviewView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -rightMargin)
        }
        
        let topMargin = contentViewPositionY + RoomBubbleCellLayout.urlPreviewViewTopMargin + RoomBubbleCellLayout.reactionsViewTopMargin
        
        // Set the preview view's origin
        NSLayoutConstraint.activate([
            leadingOrTrailingConstraint,
            urlPreviewView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: topMargin)
        ])
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
                                   rightMargin: CGFloat = 8.0,
                                   bottomMargin: CGFloat = 4.0) {
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
