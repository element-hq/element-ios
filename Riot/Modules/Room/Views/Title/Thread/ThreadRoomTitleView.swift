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
import MatrixKit

@objc
enum ThreadRoomTitleViewMode: Int {
    case partial
    case full
}

@objcMembers
class ThreadRoomTitleView: RoomTitleView {
    
    private enum Constants {
        static let titleLeadingMarginOnPortrait: CGFloat = 6
        static let titleLeadingMarginOnLandscape: CGFloat = 18
    }
    
    var mode: ThreadRoomTitleViewMode = .full {
        didSet {
            update()
        }
    }
    var threadId: String! {
        didSet {
            updateMode()
        }
    }
    
    //  Container views
    @IBOutlet private weak var partialContainerView: UIView!
    @IBOutlet private weak var fullContainerView: UIView!
    
    //  Individual views
    @IBOutlet private weak var partialTitleLabel: UILabel!
    @IBOutlet private weak var fullTitleLabel: UILabel!
    @IBOutlet private weak var fullRoomAvatarView: RoomAvatarView!
    @IBOutlet private weak var fullRoomEncryptionBadgeView: UIImageView!
    @IBOutlet private weak var fullRoomNameLabel: UILabel!
    @IBOutlet private weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    
    override var mxRoom: MXRoom! {
        didSet {
            updateMode()
        }
    }
    
    override class func nib() -> UINib! {
        return UINib(nibName: String(describing: self),
                     bundle: .main)
    }
    
    override func refreshDisplay() {
        partialTitleLabel.text = VectorL10n.roomThreadTitle
        fullTitleLabel.text = VectorL10n.roomThreadTitle
        
        guard let room = mxRoom else {
            //  room not initialized yet
            return
        }
        fullRoomNameLabel.text = room.displayName
        
        let avatarViewData = AvatarViewData(matrixItemId: room.matrixItemId,
                                            displayName: room.displayName,
                                            avatarUrl: room.mxContentUri,
                                            mediaManager: room.mxSession.mediaManager,
                                            fallbackImage: AvatarFallbackImage.matrixItem(room.matrixItemId,
                                                                                          room.displayName))
        fullRoomAvatarView.fill(with: avatarViewData)
        
        guard let summary = room.summary else {
            fullRoomEncryptionBadgeView.isHidden = true
            return
        }
        if summary.isEncrypted && room.mxSession.crypto != nil {
            fullRoomEncryptionBadgeView.image = EncryptionTrustLevelBadgeImageHelper.roomBadgeImage(for: summary.roomEncryptionTrustLevel())
            fullRoomEncryptionBadgeView.isHidden = false
        } else {
            fullRoomEncryptionBadgeView.isHidden = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        update(theme: ThemeService.shared().theme)
        registerThemeServiceDidChangeThemeNotification()
    }
    
    override func updateLayout(for orientation: UIInterfaceOrientation) {
        super.updateLayout(for: orientation)

        if orientation.isPortrait {
            titleLabelLeadingConstraint.constant = Constants.titleLeadingMarginOnPortrait
        } else {
            titleLabelLeadingConstraint.constant = Constants.titleLeadingMarginOnLandscape
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .themeServiceDidChangeTheme,
                                               object: nil)
    }
    
    private func updateMode() {
        //  ensure both mxRoom and threadId are set
        guard let room = mxRoom,
              let threadId = threadId else {
            return
        }
        
        if room.mxSession.threadingService.thread(withId: threadId) == nil {
            //  thread not created yet
            mode = .partial
            //  use full mode for every case for now
            //  TODO: Fix in future
            mode = .full
        } else {
            //  thread created before
            mode = .full
        }
    }
    
    private func update() {
        switch mode {
        case .partial:
            partialContainerView.isHidden = false
            fullContainerView.isHidden = true
        case .full:
            partialContainerView.isHidden = true
            fullContainerView.isHidden = false
        }
    }
    
    //  MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
}

extension ThreadRoomTitleView: Themable {
    
    func update(theme: Theme) {
        partialTitleLabel.textColor = theme.colors.primaryContent
        fullRoomAvatarView.backgroundColor = .clear
        fullTitleLabel.textColor = theme.colors.primaryContent
        fullRoomNameLabel.textColor = theme.colors.secondaryContent
    }
    
}
