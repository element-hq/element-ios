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
class KeyVerificationConclusionCell: KeyVerificationBaseCell {
    // MARK: - Constants
    
    private enum Sizing {
        static let view = KeyVerificationConclusionCell(style: .default, reuseIdentifier: nil)
    }
    
    // MARK: - Setup
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        keyVerificationCellInnerContentView?.isButtonsHidden = true
        keyVerificationCellInnerContentView?.isRequestStatusHidden = true
    }
    
    // MARK: - Overrides
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let keyVerificationCellInnerContentView = keyVerificationCellInnerContentView,
              let bubbleData = bubbleData as? RoomBubbleCellData,
              let viewData = viewData(from: bubbleData) else {
            MXLog.debug("[KeyVerificationConclusionBubbleCell] Fail to render \(String(describing: cellData))")
            return
        }
        
        keyVerificationCellInnerContentView.badgeImage = viewData.badgeImage
        keyVerificationCellInnerContentView.title = viewData.title
        keyVerificationCellInnerContentView.updateSenderInfo(with: viewData.senderId, userDisplayName: viewData.senderDisplayName)
    }
    
    override class func sizingView() -> KeyVerificationBaseCell {
        Sizing.view
    }
    
    // MARK: - Private
    
    private func viewData(from roomBubbleData: RoomBubbleCellData) -> KeyVerificationConclusionViewData? {
        guard let event = roomBubbleData.bubbleComponents.first?.event else {
            return nil
        }

        let viewData: KeyVerificationConclusionViewData?

        let senderId = senderId(from: bubbleData)
        let senderDisplayName = senderDisplayName(from: bubbleData)
        let title: String?
        let badgeImage: UIImage?

        switch event.eventType {
        case .keyVerificationDone:
            badgeImage = Asset.Images.encryptionTrusted.image
            title = VectorL10n.keyVerificationTileConclusionDoneTitle
        case .keyVerificationCancel:
            badgeImage = Asset.Images.encryptionWarning.image
            title = VectorL10n.keyVerificationTileConclusionWarningTitle
        default:
            badgeImage = nil
            title = nil
        }

        if let title = title, let badgeImage = badgeImage {
            viewData = KeyVerificationConclusionViewData(badgeImage: badgeImage,
                                                         title: title,
                                                         senderId: senderId,
                                                         senderDisplayName: senderDisplayName)
        } else {
            viewData = nil
        }

        return viewData
    }
}
