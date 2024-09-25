/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        self.keyVerificationCellInnerContentView?.isButtonsHidden = true
        self.keyVerificationCellInnerContentView?.isRequestStatusHidden = true
    }
    
    // MARK: - Overrides
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let keyVerificationCellInnerContentView = self.keyVerificationCellInnerContentView,
            let bubbleData = self.bubbleData as? RoomBubbleCellData,
            let viewData = self.viewData(from: bubbleData) else {
            MXLog.debug("[KeyVerificationConclusionBubbleCell] Fail to render \(String(describing: cellData))")
                return
        }
        
        keyVerificationCellInnerContentView.badgeImage = viewData.badgeImage
        keyVerificationCellInnerContentView.title = viewData.title
        keyVerificationCellInnerContentView.updateSenderInfo(with: viewData.senderId, userDisplayName: viewData.senderDisplayName)
    }
    
    override class func sizingView() -> KeyVerificationBaseCell {
        return self.Sizing.view
    }
    
    // MARK: - Private
    
    private func viewData(from roomBubbleData: RoomBubbleCellData) -> KeyVerificationConclusionViewData? {
        guard let event = roomBubbleData.bubbleComponents.first?.event else {
            return nil
        }

        let viewData: KeyVerificationConclusionViewData?

        let senderId = self.senderId(from: bubbleData)
        let senderDisplayName = self.senderDisplayName(from: bubbleData)
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
