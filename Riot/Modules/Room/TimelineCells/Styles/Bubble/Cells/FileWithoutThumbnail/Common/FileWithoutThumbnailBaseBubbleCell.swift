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
