/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

@objcMembers
class KeyVerificationIncomingRequestApprovalCell: KeyVerificationBaseCell {

    // MARK: - Constants
    
    private enum Sizing {
        static let view = KeyVerificationIncomingRequestApprovalCell(style: .default, reuseIdentifier: nil)
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
            fatalError("[KeyVerificationIncomingRequestApprovalBubbleCell] keyVerificationCellInnerContentView should not be nil")
        }
        
        keyVerificationCellInnerContentView.isButtonsHidden = false
        keyVerificationCellInnerContentView.isRequestStatusHidden = true
        keyVerificationCellInnerContentView.badgeImage = Asset.Images.encryptionNormal.image
    }
    
    // MARK: - Overrides
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.keyVerificationCellInnerContentView?.acceptActionHandler = nil
        self.keyVerificationCellInnerContentView?.declineActionHandler = nil
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let keyVerificationCellInnerContentView = self.keyVerificationCellInnerContentView,
            let bubbleData = self.bubbleData,
            let viewData = self.viewData(from: bubbleData) else {
            MXLog.debug("[KeyVerificationIncomingRequestApprovalBubbleCell] Fail to render \(String(describing: cellData))")
                return
        }
        
        keyVerificationCellInnerContentView.title = viewData.title
        keyVerificationCellInnerContentView.updateSenderInfo(with: viewData.senderId, userDisplayName: viewData.senderDisplayName)
        
        let actionUserInfo: [AnyHashable: Any]?
            
        if let eventId = bubbleData.getFirstBubbleComponentWithDisplay()?.event.eventId {
            actionUserInfo = [kMXKRoomBubbleCellEventIdKey: eventId]
        } else {
            actionUserInfo = nil
        }
        
        keyVerificationCellInnerContentView.acceptActionHandler = { [weak self] in
            self?.delegate?.cell(self, didRecognizeAction: kMXKRoomBubbleCellKeyVerificationIncomingRequestAcceptPressed, userInfo: actionUserInfo)
        }
        
        keyVerificationCellInnerContentView.declineActionHandler = { [weak self] in
            self?.delegate?.cell(self, didRecognizeAction: kMXKRoomBubbleCellKeyVerificationIncomingRequestDeclinePressed, userInfo: actionUserInfo)
        }
    }
    
    override class func sizingView() -> KeyVerificationBaseCell {
        return self.Sizing.view
    }
    
    // MARK: - Private
    
    private func viewData(from bubbleData: MXKRoomBubbleCellData) -> KeyVerificationIncomingRequestApprovalViewData? {
        
        let senderId = self.senderId(from: bubbleData)
        let senderDisplayName = self.senderDisplayName(from: bubbleData)
        let title = VectorL10n.keyVerificationTileRequestIncomingTitle
        
        return KeyVerificationIncomingRequestApprovalViewData(title: title,
                                                              senderId: senderId,
                                                              senderDisplayName: senderDisplayName)
    }
}
