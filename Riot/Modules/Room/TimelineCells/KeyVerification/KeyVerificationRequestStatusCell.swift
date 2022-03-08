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
class KeyVerificationRequestStatusCell: KeyVerificationBaseCell {

    // MARK: - Constants
    
    private enum Sizing {
        static let view = KeyVerificationRequestStatusCell(style: .default, reuseIdentifier: nil)
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
              let roomBubbleCellData = self.bubbleData as? RoomBubbleCellData,
              let viewData = self.viewData(from: roomBubbleCellData) else {
            MXLog.debug("[KeyVerificationRequestStatusBubbleCell] Fail to render \(String(describing: cellData))")
            return
        }
        
        keyVerificationCellInnerContentView.title = viewData.title
        keyVerificationCellInnerContentView.updateSenderInfo(with: viewData.senderId, userDisplayName: viewData.senderDisplayName)
        keyVerificationCellInnerContentView.requestStatusText = viewData.statusText
    }
    
    override class func sizingView() -> KeyVerificationBaseCell {
        return self.Sizing.view
    }
    
    // MARK: - Private
    
    private func viewData(from roomBubbleCellData: RoomBubbleCellData) -> KeyVerificationRequestStatusViewData? {
        
        let senderId = self.senderId(from: bubbleData)
        let senderDisplayName = self.senderDisplayName(from: bubbleData)
        let title: String
        let statusText: String?
        
        if roomBubbleCellData.isIncoming {
            title = VectorL10n.keyVerificationTileRequestIncomingTitle
        } else {
            title = VectorL10n.keyVerificationTileRequestOutgoingTitle
        }
        
        if let keyVerification = roomBubbleCellData.keyVerification {
            switch keyVerification.state {
            case .requestPending:
                if !roomBubbleCellData.isIncoming {
                    statusText = VectorL10n.keyVerificationTileRequestStatusWaiting
                } else {                    
                    if roomBubbleCellData.isKeyVerificationOperationPending {
                        statusText = VectorL10n.keyVerificationTileRequestStatusDataLoading
                    } else {
                        // Should not happen, KeyVerificationIncomingRequestApprovalBubbleCell should be displayed in this case.
                        statusText = nil
                    }
                }
            case .requestExpired:
                statusText = VectorL10n.keyVerificationTileRequestStatusExpired
            case .requestCancelled, .transactionCancelled:
                let userName = senderDisplayName ?? senderId
                statusText = VectorL10n.keyVerificationTileRequestStatusCancelled(userName)
            case .requestCancelledByMe, .transactionCancelledByMe:
                statusText = VectorL10n.keyVerificationTileRequestStatusCancelledByMe
            default:
                statusText = VectorL10n.keyVerificationTileRequestStatusAccepted
            }
        } else {
            statusText = VectorL10n.keyVerificationTileRequestStatusDataLoading
        }
        
        let viewData: KeyVerificationRequestStatusViewData?
        
        if let statusText = statusText {
            viewData = KeyVerificationRequestStatusViewData(title: title,
                                                            senderId: senderId,
                                                            senderDisplayName: senderDisplayName,
                                                            statusText: statusText)
        } else {
            viewData = nil
        }
        
        return viewData
    }
}
