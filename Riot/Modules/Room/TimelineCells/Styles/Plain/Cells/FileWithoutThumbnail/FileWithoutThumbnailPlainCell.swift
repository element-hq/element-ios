// 
// Copyright 2022 New Vector Ltd
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
