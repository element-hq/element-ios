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
import Reusable

enum ThreadRoomTitleViewMode {
    case allThreads
    case specificThread(threadId: String)
}

@objc
protocol ThreadRoomTitleViewDelegate: AnyObject {
    func threadRoomTitleViewDidTapOptions(_ view: ThreadRoomTitleView)
}

@objcMembers
class ThreadRoomTitleView: RoomTitleView {
    
    var mode: ThreadRoomTitleViewMode = .allThreads {
        didSet {
            update()
        }
    }
    weak var viewDelegate: ThreadRoomTitleViewDelegate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var roomAvatarView: RoomAvatarView!
    @IBOutlet private weak var roomEncryptionBadgeView: UIImageView!
    @IBOutlet private weak var roomNameLabel: UILabel!
    @IBOutlet private weak var optionsButton: UIButton!
    
    //  MARK: - Methods
    
    func configure(withViewModel viewModel: ThreadRoomTitleViewModel) {
        if let avatarViewData = viewModel.roomAvatar {
            roomAvatarView.fill(with: avatarViewData)
        } else {
            roomAvatarView.avatarImageView.image = nil
        }
        roomEncryptionBadgeView.image = viewModel.roomEncryptionBadge
        roomEncryptionBadgeView.isHidden = viewModel.roomEncryptionBadge == nil
        roomNameLabel.text = viewModel.roomDisplayName
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
        if let summary = room.summary, room.mxSession.crypto != nil {
            encrpytionBadge = EncryptionTrustLevelBadgeImageHelper.roomBadgeImage(for: summary.roomEncryptionTrustLevel())
        } else {
            encrpytionBadge = nil
        }
        
        let viewModel = ThreadRoomTitleViewModel(roomAvatar: avatarViewData,
                                                 roomEncryptionBadge: encrpytionBadge,
                                                 roomDisplayName: room.displayName)
        configure(withViewModel: viewModel)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        update(theme: ThemeService.shared().theme)
        registerThemeServiceDidChangeThemeNotification()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //  TODO: Find a way to handle this properly
        if let superview = superview?.superview {
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                self.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
            ])
        }
    }
    
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
            optionsButton.setImage(Asset.Images.threadsFilter.image, for: .normal)
        case .specificThread:
            titleLabel.text = VectorL10n.roomThreadTitle
            optionsButton.setImage(Asset.Images.roomContextMenuMore.image, for: .normal)
        }
    }
    
    //  MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func optionsButtonTapped(_ sender: UIButton) {
        viewDelegate?.threadRoomTitleViewDidTapOptions(self)
    }
    
}

extension ThreadRoomTitleView: NibLoadable {}

extension ThreadRoomTitleView: Themable {
    
    func update(theme: Theme) {
        roomAvatarView.backgroundColor = .clear
        titleLabel.textColor = theme.colors.primaryContent
        roomNameLabel.textColor = theme.colors.secondaryContent
        optionsButton.tintColor = theme.colors.accent
    }
    
}
