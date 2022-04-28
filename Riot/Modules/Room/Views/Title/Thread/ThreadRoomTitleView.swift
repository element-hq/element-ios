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

import Foundation
import Reusable

enum ThreadRoomTitleViewMode {
    case allThreads
    case specificThread(threadId: String)
}

@objcMembers
class ThreadRoomTitleView: RoomTitleView {

    private enum Constants {
        static let roomNameLeadingMarginForEncryptedRoom: CGFloat = 10
        static let roomNameLeadingMarginForPlainRoom: CGFloat = 4
    }
    
    var mode: ThreadRoomTitleViewMode = .allThreads {
        didSet {
            update()
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var roomAvatarView: RoomAvatarView!
    @IBOutlet private weak var roomEncryptionBadgeView: UIImageView!
    @IBOutlet private weak var roomNameLabel: UILabel!
    @IBOutlet private weak var roomNameLeadingConstraint: NSLayoutConstraint!
    
    //  MARK: - Methods
    
    func configure(withModel model: ThreadRoomTitleModel) {
        if let avatarViewData = model.roomAvatar {
            roomAvatarView.fill(with: avatarViewData)
        } else {
            roomAvatarView.avatarImageView.image = nil
        }
        roomEncryptionBadgeView.image = model.roomEncryptionBadge
        if roomEncryptionBadgeView.image == nil {
            roomNameLeadingConstraint.constant = Constants.roomNameLeadingMarginForPlainRoom
        } else {
            roomNameLeadingConstraint.constant = Constants.roomNameLeadingMarginForEncryptedRoom
        }
        roomEncryptionBadgeView.isHidden = model.roomEncryptionBadge == nil
        roomNameLabel.text = model.roomDisplayName
    }
    
    //  MARK: - Overrides
    
    override var mxRoom: MXRoom! {
        didSet {
            update()
        }
    }
    
    override class func nib() -> UINib! {
        return self.nib
    }
    
    override func refreshDisplay() {
        guard let room = mxRoom else {
            //  room not initialized yet
            return
        }
        
        let avatarViewData = AvatarViewData(matrixItemId: room.matrixItemId,
                                            displayName: room.displayName,
                                            avatarUrl: room.mxContentUri,
                                            mediaManager: room.mxSession.mediaManager,
                                            fallbackImage: AvatarFallbackImage.matrixItem(room.matrixItemId,
                                                                                          room.displayName))
        
        let encrpytionBadge: UIImage?
        if let summary = room.summary, summary.isEncrypted, room.mxSession.crypto != nil {
            encrpytionBadge = EncryptionTrustLevelBadgeImageHelper.roomBadgeImage(for: summary.roomEncryptionTrustLevel())
        } else {
            encrpytionBadge = nil
        }
        
        let model = ThreadRoomTitleModel(roomAvatar: avatarViewData,
                                         roomEncryptionBadge: encrpytionBadge,
                                         roomDisplayName: room.displayName)
        configure(withModel: model)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        update(theme: ThemeService.shared().theme)
        registerThemeServiceDidChangeThemeNotification()
    }
    
    //  MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .themeServiceDidChangeTheme,
                                               object: nil)
    }
    
    private func update() {
        switch mode {
        case .allThreads:
            titleLabel.text = VectorL10n.threadsTitle
        case .specificThread:
            titleLabel.text = VectorL10n.roomThreadTitle
        }
    }
    
    //  MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }

}

extension ThreadRoomTitleView: NibLoadable {}

extension ThreadRoomTitleView: Themable {
    
    func update(theme: Theme) {
        roomAvatarView.backgroundColor = .clear
        titleLabel.textColor = theme.colors.primaryContent
        roomNameLabel.textColor = theme.colors.secondaryContent
    }
    
}
