// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class FileWithoutThumbnailBaseBubbleCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable {
    
    weak var fileAttachementView: FileWithoutThumbnailCellContentView?
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        let attributedText = NSMutableAttributedString(attributedString: self.suitableAttributedTextMessage)
        attributedText.addAttributes([.foregroundColor: ThemeService.shared().theme.colors.secondaryContent],
                                     range: NSRange(location: 0, length: attributedText.length))
        self.fileAttachementView?.titleLabel.attributedText = attributedText
        
        self.update(theme: ThemeService.shared().theme)
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        
        guard let contentView = roomCellContentView?.innerContentView else {
            return
        }
        
        let fileAttachementView = FileWithoutThumbnailCellContentView.instantiate()
                
        contentView.vc_addSubViewMatchingParent(fileAttachementView)
        
        self.fileAttachementView = fileAttachementView
    }
    
    override func onContentViewTap(_ sender: UITapGestureRecognizer!) {
        
        if let bubbleData = self.bubbleData, bubbleData.isAttachment {
            self.delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellTapOnAttachmentView, userInfo: nil)            
        } else {
            super.onContentViewTap(sender)
        }
    }
}
