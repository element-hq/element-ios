// 
// Copyright 2020 New Vector Ltd
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
import Reusable

class CallBubbleCellBaseContentView: UIView {
    
    @IBOutlet private weak var paginationTitleView: UIView!
    @IBOutlet private weak var paginationLabel: UILabel!
    @IBOutlet private weak var paginationSeparatorView: UIView!
    
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var avatarImageView: MXKImageView!
    @IBOutlet private weak var callerNameLabel: UILabel!
    @IBOutlet private weak var callIconView: UIImageView!
    @IBOutlet private weak var callTypeLabel: UILabel!
    
    @IBOutlet weak var bubbleOverlayContainer: UIView!
    
    @IBOutlet weak var bottomContainerView: UIView!
    
    private var theme: Theme = ThemeService.shared().theme
    
    func render(_ cellData: MXKCellData) {
        guard let bubbleCellData = cellData as? RoomBubbleCellData else {
            return
        }
        
        if bubbleCellData.isPaginationFirstBubble {
            paginationTitleView.isHidden = false
            paginationLabel.text = bubbleCellData.eventFormatter.dateString(from: bubbleCellData.date, withTime: false)?.uppercased()
        } else {
            paginationTitleView.isHidden = true
        }
        
        avatarImageView.enableInMemoryCache = true
        
        if bubbleCellData.senderId == bubbleCellData.mxSession.myUserId {
            //  event sent by my user, no means in displaying our own avatar and display name
            if let directUserId = bubbleCellData.mxSession.directUserId(inRoom: bubbleCellData.roomId) {
                let user = bubbleCellData.mxSession.user(withUserId: directUserId)
                
                let placeholder = AvatarGenerator.generateAvatar(forMatrixItem: directUserId,
                                                                 withDisplayName: user?.displayname)
                
                avatarImageView.setImageURI(user?.avatarUrl,
                                            withType: nil,
                                            andImageOrientation: .up,
                                            toFitViewSize: avatarImageView.frame.size,
                                            with: MXThumbnailingMethodCrop,
                                            previewImage: placeholder,
                                            mediaManager: bubbleCellData.mxSession.mediaManager)
                avatarImageView.defaultBackgroundColor = .clear
                
                callerNameLabel.text = user?.displayname
            }
        } else {
            avatarImageView.setImageURI(bubbleCellData.senderAvatarUrl,
                                        withType: nil,
                                        andImageOrientation: .up,
                                        toFitViewSize: avatarImageView.frame.size,
                                        with: MXThumbnailingMethodCrop,
                                        previewImage: bubbleCellData.senderAvatarPlaceholder,
                                        mediaManager: bubbleCellData.mxSession.mediaManager)
            avatarImageView.defaultBackgroundColor = .clear
            
            callerNameLabel.text = bubbleCellData.senderDisplayName
        }
        
        let events = bubbleCellData.allLinkedEvents()
        
        guard let event = events.first(where: { $0.eventType == .callInvite }) else {
            return
        }
        
        let callInviteEventContent = MXCallInviteEventContent(fromJSON: event.content)
        let isVideoCall = callInviteEventContent?.isVideoCall() ?? false
        callIconView.image = isVideoCall ? Asset.Images.callVideoIcon.image.vc_tintedImage(usingColor: theme.textSecondaryColor) : Asset.Images.voiceCallHangonIcon.image.vc_tintedImage(usingColor: theme.textSecondaryColor)
        callTypeLabel.text = isVideoCall ? VectorL10n.eventFormatterCallVideo : VectorL10n.eventFormatterCallVoice
    }

}

extension CallBubbleCellBaseContentView: NibLoadable {
    
}

extension CallBubbleCellBaseContentView: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
        
        paginationLabel.textColor = theme.tintColor
        paginationSeparatorView.backgroundColor = theme.tintColor
        
        bgView.backgroundColor = theme.headerBackgroundColor
        callIconView.tintColor = theme.textSecondaryColor
        callTypeLabel.textColor = theme.textSecondaryColor
        
        if let bottomContainerView = bottomContainerView as? Themable {
            bottomContainerView.update(theme: theme)
        }
    }
    
}
