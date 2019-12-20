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

import UIKit

@objcMembers
final class KeyVerificationRequestStatusBubbleCell: KeyVerificationBaseBubbleCell {
    
    // MARK: - Constants
    
    private enum Sizing {
        static let view = KeyVerificationRequestStatusBubbleCell(style: .default, reuseIdentifier: nil)
    }
    
    // MARK: - Setup

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        guard let keyVerificationCellInnerContentView = self.keyVerificationCellInnerContentView else {
            fatalError("[KeyVerificationRequestStatusBubbleCell] keyVerificationCellInnerContentView should not be nil")
        }
        
        keyVerificationCellInnerContentView.isButtonsHidden = true
        keyVerificationCellInnerContentView.isRequestStatusHidden = false
        keyVerificationCellInnerContentView.badgeImage = Asset.Images.encryptionNormal.image
    }
    
    // MARK: - Overrides
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let keyVerificationCellInnerContentView = self.keyVerificationCellInnerContentView,
            let bubbleData = self.bubbleData,
            let viewData = self.viewData(from: bubbleData) else {
                NSLog("[KeyVerificationRequestStatusBubbleCell] Fail to render \(String(describing: cellData))")
                return
        }
        
        keyVerificationCellInnerContentView.title = viewData.title
        keyVerificationCellInnerContentView.updateSenderInfo(with: viewData.senderId, userDisplayName: viewData.senderDisplayName)
        keyVerificationCellInnerContentView.requestStatusText = viewData.statusText
    }
    
    override class func sizingView() -> MXKRoomBubbleTableViewCell {
        return self.Sizing.view
    }
    
    // MARK: - Private
    
    // TODO: Handle view data filling
    private func viewData(from bubbleData: MXKRoomBubbleCellData) -> KeyVerificationRequestStatusViewData? {
        
        let senderId = self.senderId(from: bubbleData)
        let senderDisplayName =  self.senderDisplayName(from: bubbleData)
        let title: String
        let statusText: String = "You accepted"
        
        if senderId.isEmpty == false {
            title = "Verification request"
        } else {
            title = "Verification sent"
        }
        
        return KeyVerificationRequestStatusViewData(title: title,
                                                    senderId: senderId,
                                                    senderDisplayName: senderDisplayName,
                                                    statusText: statusText)
    }
}
