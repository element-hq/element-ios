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
    
    override func addReactionView(_ reactionsView: BubbleReactionsView,
                                  toCell cell: MXKRoomBubbleTableViewCell, cellData: RoomBubbleCellData, contentViewPositionY: CGFloat, upperDecorationView: UIView?) {
        
        cell.addTmpSubview(reactionsView)
        
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
        
        // Outgoing message
        if cellData.isSenderCurrentUser {
            reactionsView.alignment = .right
            
            // TODO: Use constants
            var outgointLeftMargin = 80.0
            
            if cellData.containsBubbleComponentWithEncryptionBadge {
                outgointLeftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            leftMargin = outgointLeftMargin
            
            // TODO: Use constants
            rightMargin = 33
        } else {
            // Incoming message
            
            var incomingLeftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin
            
            if cellData.containsBubbleComponentWithEncryptionBadge {
                incomingLeftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            leftMargin = incomingLeftMargin - 6.0
            
            // TODO: Use constants
            let messageViewMarginRight: CGFloat = 42.0
            
            rightMargin = messageViewMarginRight
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
        
        cell.addTmpSubview(urlPreviewView)
        
        let cellContentView = cell.contentView
        
        urlPreviewView.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewView.availableWidth = cellData.maxTextViewWidth
        cellContentView.addSubview(urlPreviewView)
        
        let leadingOrTrailingConstraint: NSLayoutConstraint
        
        // Outgoing message
        if cellData.isSenderCurrentUser {
            
            // TODO: Use constants
            let rightMargin = 34.0
            
            leadingOrTrailingConstraint = urlPreviewView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -rightMargin)
        } else {
            // Incoming message
            
            var leftMargin = RoomBubbleCellLayout.reactionsViewLeftMargin
            if cellData.containsBubbleComponentWithEncryptionBadge {
                leftMargin += RoomBubbleCellLayout.encryptedContentLeftMargin
            }
            
            leftMargin-=5.0
            
            leadingOrTrailingConstraint = urlPreviewView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: leftMargin)
        }
        
        let topMargin = contentViewPositionY + RoomBubbleCellLayout.urlPreviewViewTopMargin + RoomBubbleCellLayout.reactionsViewTopMargin
        
        // Set the preview view's origin
        NSLayoutConstraint.activate([
            leadingOrTrailingConstraint,
            urlPreviewView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: topMargin)
        ])
    }
}
