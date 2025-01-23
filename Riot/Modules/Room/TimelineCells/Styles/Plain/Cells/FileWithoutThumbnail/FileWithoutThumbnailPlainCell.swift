// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class FileWithoutThumbnailPlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable, RoomCellThreadSummaryDisplayable {
    
    private(set) var fileAttachementView: FileWithoutThumbnailCellContentView!
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let data = cellData as? RoomBubbleCellData else {
            return
        }
        
        guard data.attachment.type == .file else {
            fatalError("Invalid attachment type passed to a file without thumbnail cell.")
        }
        
        let attributedText = NSMutableAttributedString(attributedString: self.suitableAttributedTextMessage)
        attributedText.addAttributes([.foregroundColor: ThemeService.shared().theme.colors.secondaryContent],
                                     range: NSRange(location: 0, length: attributedText.length))
        self.fileAttachementView.titleLabel.attributedText = attributedText

        self.update(theme: ThemeService.shared().theme)
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
        
        guard let contentView = roomCellContentView?.innerContentView else {
            return
        }
        
        fileAttachementView = FileWithoutThumbnailCellContentView.loadFromNib()
        contentView.vc_addSubViewMatchingParent(fileAttachementView)
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        
        guard let fileAttachementView = fileAttachementView else {
            return
        }
        
        fileAttachementView.update(theme: theme)
        fileAttachementView.backgroundColor = theme.colors.quinaryContent
    }
    
    override func onContentViewTap(_ sender: UITapGestureRecognizer!) {
        
        if let bubbleData = self.bubbleData, bubbleData.isAttachment {
            self.delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellTapOnAttachmentView, userInfo: nil)
        } else {
            super.onContentViewTap(sender)
        }
    }
}
